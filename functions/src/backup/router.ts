import express, { Request, Response } from "express";
import { requirePost } from "../middleware/method";
import { BackupService } from "./service";
import { logger } from "firebase-functions";

const router = express.Router();
const backupService = new BackupService();

// Shared cron guard — identical to log/router.ts. Returns false (and responds 401)
// when the x-cron-secret header is missing or wrong.
function requireCronSecret(request: Request, response: Response): boolean {
  const secret = request.headers["x-cron-secret"];
  if (!secret || secret !== process.env.CRON_SECRET) {
    response.status(401).json({ success: false, message: "Unauthorized" });
    return false;
  }
  return true;
}

// Phase 1: start the managed export, return immediately.
router.post(
  "/daily",
  requirePost,
  async (request: Request, response: Response) => {
    if (!requireCronSecret(request, response)) return;
    try {
      const { operationName, prefix } = await backupService.startExport();
      logger.info("[backup/daily] export started:", operationName);
      return response
        .status(200)
        .json({ success: true, data: { operationName, prefix } });
    } catch (e) {
      logger.error("[backup/daily] error:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

// Phase 2: zip the latest export folder and email the signed link.
// Schedule this a few minutes after /daily so the export has finished.
router.post(
  "/zip-and-send",
  requirePost,
  async (request: Request, response: Response) => {
    if (!requireCronSecret(request, response)) return;
    try {
      const date = new Date().toLocaleDateString("en-CA", {
        timeZone: "Pacific/Auckland",
      });
      const prefix = await backupService.latestExportPrefix(date);
      const zipPath = await backupService.zipExport(prefix);
      await backupService.createSignedUrlAndEmail(zipPath, date);
      logger.info("[backup/zip-and-send] done:", zipPath);
      return response.status(200).json({ success: true, data: { zipPath } });
    } catch (e) {
      logger.error("[backup/zip-and-send] error:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
