// Shared Firebase Storage helpers. Extracted from backup/service.ts so the
// backup flow and the export API share one storage client + URL-signing setup.

import { Storage } from "@google-cloud/storage";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

// Throws a clear error if the storage bucket isn't configured.
export function bucketName(): string {
  const bucket = process.env.BACKUP_BUCKET;
  if (!bucket) throw new Error("BACKUP_BUCKET not configured");
  return bucket;
}

// Storage client built from the service-account creds so V4 URL signing happens
// locally with the private key (no extra signBlob IAM needed).
export function storageClient(): Storage {
  return new Storage({
    projectId: process.env.FB_PROJECT_ID ?? "",
    credentials: {
      client_email: process.env.FB_CLIENT_EMAIL,
      private_key: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    },
  });
}

// Create a 7-day V4 signed URL for an object, forcing a friendly download name.
export async function signedDownloadUrl(
  objectPath: string,
  downloadName: string,
): Promise<string> {
  const [url] = await storageClient()
    .bucket(bucketName())
    .file(objectPath)
    .getSignedUrl({
      version: "v4",
      action: "read",
      expires: Date.now() + SEVEN_DAYS_MS, // V4 max is 7 days
      // Force the browser to save the file under a friendly name
      // instead of the bucket path.
      responseDisposition: `attachment; filename="${downloadName}"`,
    });
  return url;
}
