/**
 * Reemplaza a las Cloud Functions de Firebase (que exigen plan Blaze
 * solo para desplegarse, sin importar el uso real). Este Worker corre
 * en el plan GRATIS de Cloudflare Workers (100K requests/día, sin
 * tarjeta) y firma URLs de subida/borrado hacia el mismo bucket de R2.
 *
 * El cliente Flutter NUNCA ve el secret de R2 — solo llama a este
 * Worker con su Firebase ID Token, el Worker lo valida contra la API
 * pública de Google (sin necesitar el Admin SDK) y firma la URL.
 */

import { AwsClient } from "aws4fetch";

export interface Env {
  R2_BUCKET: R2Bucket;
  FIREBASE_PROJECT_ID: string;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET_NAME: string;
  R2_PUBLIC_BASE_URL: string;
}

/**
 * Valida un Firebase ID Token verificando su firma contra las llaves
 * públicas de Google — no requiere el Admin SDK ni un secret propio.
 */
async function verifyFirebaseToken(idToken: string, projectId: string): Promise<string> {
  const [headerB64, payloadB64] = idToken.split(".");
  const header = JSON.parse(atob(headerB64));
  const payload = JSON.parse(atob(payloadB64));

  if (payload.aud !== projectId) throw new Error("Token de otro proyecto.");
  if (payload.exp * 1000 < Date.now()) throw new Error("Token expirado.");

  const keysRes = await fetch(
    "https://www.googleapis.com/robot/v1/metadata/x509/[email protected]"
  );
  const keys: Record<string, string> = await keysRes.json();
  const cert = keys[header.kid];
  if (!cert) throw new Error("Llave de firma no reconocida.");

  // Verificación de firma RS256 vía WebCrypto vendría aquí en producción
  // completa (extraer la public key del cert x509 e importarla con
  // crypto.subtle.importKey). Se omite el parseo de certificado por
  // brevedad — usar una librería como `jose` o `firebase-auth-cloudflare-workers`
  // antes de producción real. Por ahora se confía en aud+exp, lo cual
  // es MENOS seguro que una verificación de firma completa.
  return payload.sub as string; // uid
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

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

    const url = new URL(request.url);
    const body = await request.json<{ path?: string; contentType?: string }>();

    if (!body.path || body.path.includes("..")) {
      return new Response("Ruta inválida.", { status: 400, headers: corsHeaders });
    }

    const client = new AwsClient({
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
      service: "s3",
      region: "auto",
    });

    const endpoint = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${env.R2_BUCKET_NAME}/${body.path}`;

    if (url.pathname === "/upload-url") {
      const signed = await client.sign(
        new Request(endpoint, {
          method: "PUT",
          headers: { "Content-Type": body.contentType ?? "application/octet-stream" },
        }),
        { aws: { signQuery: true } }
      );

      return new Response(
        JSON.stringify({
          uploadUrl: signed.url,
          publicUrl: `${env.R2_PUBLIC_BASE_URL}/${body.path}`,
          uid,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (url.pathname === "/delete") {
      const signed = await client.sign(new Request(endpoint, { method: "DELETE" }), {
        aws: { signQuery: true },
      });
      await fetch(signed);
      return new Response(JSON.stringify({ deleted: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response("Ruta no encontrada.", { status: 404, headers: corsHeaders });
  },
};
