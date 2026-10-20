/**
 * Cloudflare Worker (plan gratis, sin tarjeta). Reemplaza a las Cloud
 * Functions de Firebase (que exigen plan Blaze solo para desplegarse).
 *
 *  - /spotify/search               búsqueda de canciones (Client Credentials)
 *  - /spotify/auth/callback        OAuth de Spotify (crea la playlist real)
 *  - /spotify/playlist/add-track   agrega canción a la playlist real
 *  - /spotify/playlist/remove-track
 *  - /upload-url, /delete          URLs firmadas hacia R2 (requieren sesión)
 */


export interface Env {
  R2_BUCKET: R2Bucket;
  FIREBASE_PROJECT_ID: string;
  R2_PUBLIC_BASE_URL: string;
  SPOTIFY_CLIENT_ID: string;
  SPOTIFY_CLIENT_SECRET: string;
  // Origen exacto de la app Flutter (protocolo + host + puerto): se usa
  // como targetOrigin del postMessage del popup de OAuth. En desarrollo
  // debe ser http://localhost:5000 (no 127.0.0.1: son orígenes distintos).
  FLUTTER_APP_URL: string;
}

// ---------------------------------------------------------------------------
// Verificación de Firebase ID Token (JWT RS256)
// ---------------------------------------------------------------------------

// Llaves públicas con las que Google firma los ID Tokens de Firebase, en
// formato JWK (importables directo con WebCrypto). El correo se arma por
// partes para que ningún herramienta de texto lo reescriba al copiarlo.
const FIREBASE_JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/" +
  "securetoken" + "@" + "system.gserviceaccount.com";

/** Los JWT usan base64url (con - y _, sin relleno). atob() solo entiende
 * base64 estándar, por eso hay que convertir antes de decodificar. */
function base64UrlToBytes(input: string): Uint8Array {
  const base64 = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function base64UrlToJson<T>(input: string): T {
  return JSON.parse(new TextDecoder().decode(base64UrlToBytes(input))) as T;
}

type FirebaseJwk = JsonWebKey & { kid: string };
let jwksCache: { keys: FirebaseJwk[]; expiresAt: number } | null = null;

async function getFirebaseKeys(forceRefresh = false): Promise<FirebaseJwk[]> {
  if (!forceRefresh && jwksCache && jwksCache.expiresAt > Date.now()) {
    return jwksCache.keys;
  }
  const res = await fetch(FIREBASE_JWKS_URL);
  if (!res.ok) {
    throw new Error(`No se pudieron obtener las llaves de Google (${res.status}).`);
  }
  const data = (await res.json()) as { keys: FirebaseJwk[] };
  // Google rota estas llaves cada varios días; 1 hora de caché es de sobra
  // y, si aparece un kid desconocido, se vuelve a pedir de inmediato.
  jwksCache = { keys: data.keys, expiresAt: Date.now() + 60 * 60 * 1000 };
  return data.keys;
}

/** Valida firma, emisor, audiencia y vigencia. Devuelve el uid. */
async function verifyFirebaseToken(idToken: string, projectId: string): Promise<string> {
  const parts = idToken.split(".");
  if (parts.length !== 3) throw new Error("Formato de token inválido.");
  const [headerB64, payloadB64, signatureB64] = parts;

  const header = base64UrlToJson<{ alg: string; kid: string }>(headerB64);
  const payload = base64UrlToJson<{
    aud: string;
    iss: string;
    sub: string;
    exp: number;
    iat: number;
  }>(payloadB64);

  if (header.alg !== "RS256") throw new Error("Algoritmo no permitido.");

  const now = Math.floor(Date.now() / 1000);
  if (payload.aud !== projectId) throw new Error("Token de otro proyecto.");
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
    throw new Error("Emisor inválido.");
  }
  if (!payload.sub) throw new Error("Token sin usuario.");
  if (payload.exp <= now) throw new Error("Token expirado.");
  if (payload.iat > now + 300) throw new Error("Token con fecha futura.");

  let keys = await getFirebaseKeys();
  let jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) {
    keys = await getFirebaseKeys(true);
    jwk = keys.find((k) => k.kid === header.kid);
  }
  if (!jwk) {
    throw new Error(
      `Llave de firma no reconocida (kid ${String(header.kid).slice(0, 8)}…; ` +
        `Google publicó ${keys.length} llaves).`
    );
  }

  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    base64UrlToBytes(signatureB64),
    new TextEncoder().encode(`${headerB64}.${payloadB64}`)
  );
  if (!valid) throw new Error("Firma inválida.");

  return payload.sub;
}

// ---------------------------------------------------------------------------
// Spotify
// ---------------------------------------------------------------------------

let spotifyTokenCache: { token: string; expiresAt: number } | null = null;

async function getSpotifyToken(env: Env): Promise<string> {
  if (spotifyTokenCache && spotifyTokenCache.expiresAt > Date.now()) {
    return spotifyTokenCache.token;
  }

  const basicAuth = btoa(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`);
  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${basicAuth}`,
    },
    body: "grant_type=client_credentials",
  });

  if (!res.ok) {
    throw new Error(`No se pudo autenticar con Spotify (${res.status}).`);
  }

  const data = await res.json<{ access_token: string; expires_in: number }>();
  spotifyTokenCache = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in - 60) * 1000,
  };
  return data.access_token;
}

/** HTML mínimo que le manda el resultado del OAuth a la ventana que lo
 * abrió (window.opener) vía postMessage y se cierra sola. La app Flutter
 * nunca se recarga: solo este popup ligero pasa por la navegación. */
function postMessageAndClose(env: Env, payload: Record<string, unknown>): Response {
  const json = JSON.stringify(payload);
  const html = `<!DOCTYPE html>
<html><body>
<script>
  if (window.opener) {
    window.opener.postMessage(${JSON.stringify(json)}, ${JSON.stringify(env.FLUTTER_APP_URL)});
  }
  window.close();
</script>
Conectado. Puedes cerrar esta ventana si no se cierra sola.
</body></html>`;
  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);

    // Sirve para comprobar qué versión está desplegada (abrir en el navegador).
    if (url.pathname === "/version") {
      return new Response(JSON.stringify({ version: "jwk-verify-2" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // --- Búsqueda de Spotify ---
    if (url.pathname === "/spotify/search") {
      if (request.method !== "GET") {
        return new Response("Method not allowed", { status: 405, headers: corsHeaders });
      }
      const q = url.searchParams.get("q");
      if (!q || q.trim().length === 0) {
        return new Response(JSON.stringify({ tracks: [] }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      try {
        const token = await getSpotifyToken(env);
        const searchRes = await fetch(
          `https://api.spotify.com/v1/search?q=${encodeURIComponent(q)}&type=track&limit=10`,
          { headers: { Authorization: `Bearer ${token}` } }
        );

        if (!searchRes.ok) {
          const errorBody = await searchRes.text();
          return new Response(`Error de Spotify (${searchRes.status}): ${errorBody}`, {
            status: 502,
            headers: corsHeaders,
          });
        }

        const data = await searchRes.json<{ tracks: { items: unknown[] } }>();
        const tracks = data.tracks.items.map((t: any) => ({
          spotifyTrackId: t.id,
          name: t.name,
          artist: (t.artists ?? []).map((a: any) => a.name).join(", "),
          album: t.album?.name ?? "",
          imageUrl: t.album?.images?.[1]?.url ?? t.album?.images?.[0]?.url ?? null,
          durationMs: t.duration_ms,
          spotifyUrl: t.external_urls?.spotify ?? "",
        }));

        return new Response(JSON.stringify({ tracks }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (e) {
        return new Response(`Error: ${(e as Error).message}`, { status: 500, headers: corsHeaders });
      }
    }

    // --- Callback de OAuth de Spotify ---
    if (url.pathname === "/spotify/auth/callback") {
      const code = url.searchParams.get("code");
      const state = url.searchParams.get("state"); // weddingId
      const error = url.searchParams.get("error");

      if (error || !code) {
        return postMessageAndClose(env, { type: "spotify-error", error: error ?? "sin_codigo" });
      }

      try {
        const basicAuth = btoa(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`);
        const tokenRes = await fetch("https://accounts.spotify.com/api/token", {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            Authorization: `Basic ${basicAuth}`,
          },
          body: new URLSearchParams({
            grant_type: "authorization_code",
            code,
            redirect_uri: `${url.origin}/spotify/auth/callback`,
          }),
        });

        if (!tokenRes.ok) {
          const errText = await tokenRes.text();
          return postMessageAndClose(env, { type: "spotify-error", error: errText });
        }

        const tokenData = await tokenRes.json<{ access_token: string; refresh_token: string }>();

        const createRes = await fetch("https://api.spotify.com/v1/me/playlists", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${tokenData.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            name: "Nuestra Boda",
            description: "Playlist colaborativa generada desde la app de la boda.",
            public: false,
          }),
        });

        if (!createRes.ok) {
          const errText = await createRes.text();
          return postMessageAndClose(env, { type: "spotify-error", error: errText });
        }

        const playlist = await createRes.json<{ id: string; external_urls: { spotify: string } }>();

        return postMessageAndClose(env, {
          type: "spotify-connected",
          weddingId: state ?? "",
          refreshToken: tokenData.refresh_token,
          playlistId: playlist.id,
          playlistUrl: playlist.external_urls.spotify,
        });
      } catch (e) {
        return postMessageAndClose(env, { type: "spotify-error", error: (e as Error).message });
      }
    }

    // --- Agregar/quitar una canción de la playlist real de Spotify ---
    if (url.pathname === "/spotify/playlist/add-track" || url.pathname === "/spotify/playlist/remove-track") {
      if (request.method !== "POST") {
        return new Response("Method not allowed", { status: 405, headers: corsHeaders });
      }

      const body = await request.json<{
        refreshToken?: string;
        playlistId?: string;
        spotifyTrackId?: string;
      }>();

      if (!body.refreshToken || !body.playlistId || !body.spotifyTrackId) {
        return new Response("Faltan parámetros.", { status: 400, headers: corsHeaders });
      }

      try {
        const basicAuth = btoa(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`);
        const refreshRes = await fetch("https://accounts.spotify.com/api/token", {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            Authorization: `Basic ${basicAuth}`,
          },
          body: new URLSearchParams({
            grant_type: "refresh_token",
            refresh_token: body.refreshToken,
          }),
        });

        if (!refreshRes.ok) {
          const errText = await refreshRes.text();
          return new Response(`No se pudo renovar el token: ${errText}`, {
            status: 502,
            headers: corsHeaders,
          });
        }

        const refreshData = await refreshRes.json<{ access_token: string }>();

        const itemsUrl = `https://api.spotify.com/v1/playlists/${body.playlistId}/items`;
        const method = url.pathname.endsWith("add-track") ? "POST" : "DELETE";
        const spotifyRes = await fetch(itemsUrl, {
          method,
          headers: {
            Authorization: `Bearer ${refreshData.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ uris: [`spotify:track:${body.spotifyTrackId}`] }),
        });

        if (!spotifyRes.ok) {
          const errText = await spotifyRes.text();
          return new Response(`Error de Spotify (${spotifyRes.status}): ${errText}`, {
            status: 502,
            headers: corsHeaders,
          });
        }

        return new Response(JSON.stringify({ ok: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (e) {
        return new Response(`Error: ${(e as Error).message}`, { status: 500, headers: corsHeaders });
      }
    }

    // --- Rutas de R2: requieren sesión de Firebase ---
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }

    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response("No autenticado.", { status: 401, headers: corsHeaders });
    }

    let uid: string;
    try {
      uid = await verifyFirebaseToken(authHeader.slice(7), env.FIREBASE_PROJECT_ID);
    } catch (e) {
      return new Response(`Token inválido: ${(e as Error).message}`, {
        status: 401,
        headers: corsHeaders,
      });
    }

    if (url.pathname === "/upload") {
      const path = url.searchParams.get("path") ?? "";
      const contentType = request.headers.get("Content-Type") ?? "";
      if (!path || path.startsWith("/") || path.includes("..") || path.includes("\\") ||
          !path.startsWith("weddings/")) {
        return new Response("Ruta no permitida.", { status: 403, headers: corsHeaders });
      }
      if (!contentType.startsWith("image/")) {
        return new Response("Tipo de archivo no permitido.", { status: 415, headers: corsHeaders });
      }
      const bytes = await request.arrayBuffer();
      if (!bytes.byteLength || bytes.byteLength > 10 * 1024 * 1024) {
        return new Response("Tamaño inválido (máximo 10 MB).", { status: 413, headers: corsHeaders });
      }
      await env.R2_BUCKET.put(path, bytes, { httpMetadata: { contentType } });
      return new Response(JSON.stringify({ publicUrl: `${env.R2_PUBLIC_BASE_URL.replace(/\/$/, "")}/${path}` }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (url.pathname === "/delete") {
      const body = await request.json<{ path?: string }>();
      const path = body.path ?? "";
      if (!path.startsWith("weddings/") || path.includes("..") || path.includes("\\")) {
        return new Response("Ruta no permitida.", { status: 403, headers: corsHeaders });
      }
      await env.R2_BUCKET.delete(path);
      return new Response(JSON.stringify({ deleted: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response("Ruta no encontrada.", { status: 404, headers: corsHeaders });
  },
};
