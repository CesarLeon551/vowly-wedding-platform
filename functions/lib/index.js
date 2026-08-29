"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteR2Object = exports.getR2UploadUrl = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Secrets — se configuran una sola vez con:
//   firebase functions:secrets:set R2_ACCOUNT_ID
//   firebase functions:secrets:set R2_ACCESS_KEY_ID
//   firebase functions:secrets:set R2_SECRET_ACCESS_KEY
//   firebase functions:secrets:set R2_BUCKET_NAME
//   firebase functions:secrets:set R2_PUBLIC_BASE_URL
// Nunca van en el código ni en el repo.
const R2_ACCOUNT_ID = (0, params_1.defineSecret)("R2_ACCOUNT_ID");
const R2_ACCESS_KEY_ID = (0, params_1.defineSecret)("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = (0, params_1.defineSecret)("R2_SECRET_ACCESS_KEY");
const R2_BUCKET_NAME = (0, params_1.defineSecret)("R2_BUCKET_NAME");
const R2_PUBLIC_BASE_URL = (0, params_1.defineSecret)("R2_PUBLIC_BASE_URL");
function r2Client() {
    return new client_s3_1.S3Client({
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
exports.getR2UploadUrl = (0, https_1.onCall)({ secrets: [R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_PUBLIC_BASE_URL] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }
    const path = request.data?.path;
    const contentType = request.data?.contentType;
    if (!path || !contentType) {
        throw new https_1.HttpsError("invalid-argument", "Falta path o contentType.");
    }
    // Evita que alguien escriba fuera de su propia boda / carpeta esperada.
    // Ajustar este prefijo según el módulo (photos, documents, etc.) cuando
    // se conecte cada feature real en su fase correspondiente.
    if (path.includes("..")) {
        throw new https_1.HttpsError("invalid-argument", "Ruta inválida.");
    }
    const client = r2Client();
    const command = new client_s3_1.PutObjectCommand({
        Bucket: R2_BUCKET_NAME.value(),
        Key: path,
        ContentType: contentType,
    });
    const uploadUrl = await (0, s3_request_presigner_1.getSignedUrl)(client, command, { expiresIn: 300 });
    const publicUrl = `${R2_PUBLIC_BASE_URL.value()}/${path}`;
    return { uploadUrl, publicUrl };
});
exports.deleteR2Object = (0, https_1.onCall)({ secrets: [R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }
    const path = request.data?.path;
    if (!path) {
        throw new https_1.HttpsError("invalid-argument", "Falta path.");
    }
    const client = r2Client();
    await client.send(new client_s3_1.DeleteObjectCommand({
        Bucket: R2_BUCKET_NAME.value(),
        Key: path,
    }));
    return { deleted: true };
});
