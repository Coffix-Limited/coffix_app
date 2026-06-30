import { Storage } from "@google-cloud/storage";
import archiver from "archiver";
import { GoogleAuth } from "google-auth-library";
import { logger } from "firebase-functions";
import {
  BACKUP_RECIPIENT_EMAIL,
  RESEND_BCC_EMAIL,
  RESEND_FROM_EMAIL,
} from "../constant/constant";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
const EXPORT_FOLDER = "firestore-exports";

export class BackupService {
  private readonly project = process.env.FB_PROJECT_ID ?? "";

  // Throws a clear error if the backup bucket isn't configured.
  private bucketName(): string {
    const bucket = process.env.BACKUP_BUCKET;
    if (!bucket) throw new Error("BACKUP_BUCKET not configured");
    return bucket;
  }

  // dev -> "(default)", prod -> "coffix-prod-australia" (mirrors firebaseAdmin.ts)
  private databaseName(): string {
    const gcloudProject = process.env.GCLOUD_PROJECT ?? "";
    return gcloudProject.includes("dev")
      ? "(default)"
      : "coffix-prod-australia";
  }

  // Current NZ date as yyyy-MM-dd (en-CA yields ISO date formatting).
  private nzDateStamp(): string {
    return new Date().toLocaleDateString("en-CA", {
      timeZone: "Pacific/Auckland",
    });
  }

  // Current NZ time as HHmmss (en-GB, 24h) with colons stripped, e.g. "142233".
  // Used to give each export its own sub-folder so same-day runs don't collide.
  private nzTimeStamp(): string {
    return new Date()
      .toLocaleTimeString("en-GB", {
        timeZone: "Pacific/Auckland",
        hour12: false,
      })
      .replace(/:/g, "");
  }

  // Storage client built from the service-account creds so V4 URL signing happens
  // locally with the private key (no extra signBlob IAM needed).
  private storageClient(): Storage {
    return new Storage({
      projectId: this.project,
      credentials: {
        client_email: process.env.FB_CLIENT_EMAIL,
        private_key: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
      },
    });
  }

  /**
   * Phase 1: kick off the Firestore managed export to a dated GCS folder.
   * Returns immediately with the operation name + prefix; does NOT wait for the
   * (long-running) operation to complete.
   */
  async startExport(): Promise<{
    operationName: string;
    prefix: string;
    date: string;
  }> {
    const bucket = this.bucketName();
    const date = this.nzDateStamp();
    const time = this.nzTimeStamp();
    // Nest each run under a timestamped sub-folder so re-runs on the same day
    // don't hit Firestore's "Path already exists" error.
    const prefix = `${EXPORT_FOLDER}/${date}/${time}`;
    const outputUriPrefix = `gs://${bucket}/${prefix}`;

    const db = encodeURIComponent(this.databaseName());
    const url =
      `https://firestore.googleapis.com/v1/projects/${this.project}` +
      `/databases/${db}:exportDocuments`;

    const auth = new GoogleAuth({
      credentials: {
        client_email: process.env.FB_CLIENT_EMAIL,
        private_key: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
      },
      scopes: ["https://www.googleapis.com/auth/datastore"],
    });
    const client = await auth.getClient();

    // Omitting collectionIds exports ALL collections.
    const { data } = await client.request<{ name: string }>({
      url,
      method: "POST",
      data: { outputUriPrefix },
    });

    logger.info(`[backup] export started: ${data.name} -> ${outputUriPrefix}`);
    return { operationName: data.name, prefix, date };
  }

  /**
   * Resolve the latest export sub-folder for a given date. Since each run nests
   * under a timestamped folder (firestore-exports/<date>/<HHmmss>), Phase 2 can
   * no longer rebuild the path from the date alone — it must find the newest one.
   */
  async latestExportPrefix(date: string): Promise<string> {
    const bucket = this.storageClient().bucket(this.bucketName());
    const dayPrefix = `${EXPORT_FOLDER}/${date}/`;

    const [files] = await bucket.getFiles({ prefix: dayPrefix });
    if (files.length === 0) {
      throw new Error(`No export found under ${dayPrefix}`);
    }

    // Collect the immediate <timestamp> sub-folders, pick the lexicographically
    // greatest (HHmmss sorts chronologically within a day).
    const timestamps = new Set<string>();
    for (const f of files) {
      const ts = f.name.substring(dayPrefix.length).split("/")[0];
      if (ts) timestamps.add(ts);
    }

    const latest = [...timestamps].sort().at(-1);
    return `${EXPORT_FOLDER}/${date}/${latest}`;
  }

  /**
   * Phase 2a: stream every object under the export prefix through archiver into a
   * single `<prefix>.zip` object in the same bucket. Streaming keeps memory flat.
   * Returns the zip object path.
   */
  async zipExport(prefix: string): Promise<string> {
    const bucket = this.storageClient().bucket(this.bucketName());

    const [files] = await bucket.getFiles({ prefix: `${prefix}/` });
    if (files.length === 0) {
      throw new Error(`No export files found under ${prefix}/`);
    }

    const zipPath = `${prefix}.zip`;
    const zipStream = bucket.file(zipPath).createWriteStream({
      metadata: { contentType: "application/zip" },
      resumable: false,
    });

    const archive = archiver("zip", { zlib: { level: 9 } });

    const done = new Promise<void>((resolve, reject) => {
      zipStream.on("finish", resolve);
      zipStream.on("error", reject);
      archive.on("error", reject);
    });

    archive.pipe(zipStream);
    for (const file of files) {
      // path inside the zip, relative to the export folder
      const name = file.name.substring(`${prefix}/`.length);
      archive.append(file.createReadStream(), { name });
    }
    await archive.finalize();
    await done;

    logger.info(`[backup] zipped ${files.length} files -> ${zipPath}`);
    return zipPath;
  }

  /**
   * Phase 2b: create a 7-day V4 signed URL for the zip and email it to IT via Resend.
   */
  async createSignedUrlAndEmail(zipPath: string, date: string): Promise<void> {
    const downloadName = `coffix-firestore-backup-${date}.zip`;
    const [url] = await this.storageClient()
      .bucket(this.bucketName())
      .file(zipPath)
      .getSignedUrl({
        version: "v4",
        action: "read",
        expires: Date.now() + SEVEN_DAYS_MS, // V4 max is 7 days
        // Force the browser to save the file under a friendly name
        // instead of the bucket path (e.g. "2026-06-26.zip").
        responseDisposition: `attachment; filename="${downloadName}"`,
      });

    const subject = `Coffix Firestore backup — ${date}`;
    const html = `
      <p>The Firestore backup for <strong>${date}</strong> is ready.</p>
      <p><a href="${url}">Download backup (.zip)</a></p>
      <p>This link expires in <strong>7 days</strong>. A fresh link is emailed every day.</p>
    `;

    const RESEND_API_KEY = process.env.RESEND_API_KEY;
    if (!RESEND_API_KEY) throw new Error("RESEND_API_KEY not configured");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: RESEND_FROM_EMAIL,
        to: [BACKUP_RECIPIENT_EMAIL],
        bcc: [RESEND_BCC_EMAIL],
        subject,
        html,
      }),
    });

    if (!res.ok) {
      const err = await res.json();
      logger.error("[backup] Resend API error", {
        resendStatus: res.status,
        resendError: err,
      });
      throw new Error(`Resend ${res.status}: ${JSON.stringify(err)}`);
    }

    logger.info(`[backup] signed link emailed to ${BACKUP_RECIPIENT_EMAIL}`);
  }
}
