import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {S3Client, PutObjectCommand, DeleteObjectCommand} from "@aws-sdk/client-s3";
import {getSignedUrl} from "@aws-sdk/s3-request-presigner";
import * as admin from "firebase-admin";

admin.initializeApp();

// Secrets — se configuran una sola vez con:
//   firebase functions:secrets:set R2_ACCOUNT_ID
//   firebase functions:secrets:set R2_ACCESS_KEY_ID
//   firebase functions:secrets:set R2_SECRET_ACCESS_KEY
//   firebase functions:secrets:set R2_BUCKET_NAME
//   firebase functions:secrets:set R2_PUBLIC_BASE_URL
// Nunca van en el código ni en el repo.
const R2_ACCOUNT_ID = defineSecret("R2_ACCOUNT_ID");
const R2_ACCESS_KEY_ID = defineSecret("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = defineSecret("R2_SECRET_ACCESS_KEY");
const R2_BUCKET_NAME = defineSecret("R2_BUCKET_NAME");
const R2_PUBLIC_BASE_URL = defineSecret("R2_PUBLIC_BASE_URL");

function r2Client() {
  return new S3Client({
    region: "auto",
    endpoint: `https://${R2_ACCOUNT_ID.value()}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: R2_ACCESS_KEY_ID.value(),
      secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
    },
  });
}

/**
 * Devuelve una URL firmada (válida 5 minutos) para que el cliente
 * suba UN archivo directamente a R2 vía PUT, sin que el secret key
 * pase nunca por el cliente.
 */
export const getR2UploadUrl = onCall(
  {secrets: [R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_PUBLIC_BASE_URL]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const path = request.data?.path as string | undefined;
    const contentType = request.data?.contentType as string | undefined;

    if (!path || !contentType) {
      throw new HttpsError("invalid-argument", "Falta path o contentType.");
    }

    // Evita que alguien escriba fuera de su propia boda / carpeta esperada.
    // Ajustar este prefijo según el módulo (photos, documents, etc.) cuando
    // se conecte cada feature real en su fase correspondiente.
    if (path.includes("..")) {
      throw new HttpsError("invalid-argument", "Ruta inválida.");
    }

    const client = r2Client();
    const command = new PutObjectCommand({
      Bucket: R2_BUCKET_NAME.value(),
      Key: path,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(client, command, {expiresIn: 300});
    const publicUrl = `${R2_PUBLIC_BASE_URL.value()}/${path}`;

    return {uploadUrl, publicUrl};
  }
);

export const deleteR2Object = onCall(
  {secrets: [R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const path = request.data?.path as string | undefined;
    if (!path) {
      throw new HttpsError("invalid-argument", "Falta path.");
    }

    const client = r2Client();
    await client.send(
      new DeleteObjectCommand({
        Bucket: R2_BUCKET_NAME.value(),
        Key: path,
      })
    );

    return {deleted: true};
  }
);
