import express, { Request, Response } from "express";
import Busboy from "busboy";
import { requirePost } from "../middleware/method";
import { logger } from "firebase-functions/v1";
import { exportRequestSchema, importRequestSchema } from "./schema";
import { ExportService, ImportService } from "./service";
import { isImportableCollection } from "./importSchemas";
import { parseCsv } from "../utils/csv";

// Cloud Functions exposes the raw request body here for multipart parsing.
interface RawBodyRequest extends Request {
  rawBody?: Buffer;
}

const importRouter = express.Router();
importRouter.use(express.json());

// Export a single collection to CSV in Storage and return a download link.
importRouter.post(
  "/export",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = exportRequestSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const exportService = new ExportService();
      const { link, requestId, storagePath, sizeBytes } =
        await exportService.exportCollection(validation.data.collection);

      return response.status(200).json({
        success: true,
        message: "Export completed",
        data: { link, requestId, storagePath, sizeBytes },
      });
    } catch (e) {
      logger.error("Error exporting collections:", e);
      return response.status(500).json({
        success: false,
        message: `Internal server error. ${e}`,
      });
    }
  },
);

// Import a CSV into a Firestore collection. Accepts multipart/form-data with a
// `collection` text field and a `file` (the CSV). Rows with a `docId` upsert;
// rows without one insert with a generated id. Invalid rows are skipped. The
// response reports how many rows were created, updated and skipped; the reason
// each row was skipped is written to the function log.
importRouter.post(
  "/import",
  requirePost,
  (request: RawBodyRequest, response: Response) => {
    const contentType = request.headers["content-type"] ?? "";
    if (!contentType.includes("multipart/form-data")) {
      return response.status(400).json({
        success: false,
        message: "Expected multipart/form-data upload",
      });
    }

    const busboy = Busboy({ headers: request.headers });

    let collection = "";
    const fileChunks: Buffer[] = [];
    let fileReceived = false;

    busboy.on("field", (name, value) => {
      if (name === "collection") collection = value;
    });

    busboy.on("file", (_name, stream) => {
      fileReceived = true;
      stream.on("data", (chunk: Buffer) => fileChunks.push(chunk));
      stream.on("error", (e) => logger.error("Error reading upload:", e));
    });

    busboy.on("error", (e) => {
      logger.error("Error parsing multipart body:", e);
      response
        .status(400)
        .json({ success: false, message: "Malformed multipart body" });
    });

    busboy.on("close", async () => {
      const validation = importRequestSchema.safeParse({ collection });
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        return response.status(400).json({ success: false, errors });
      }

      if (!isImportableCollection(collection)) {
        return response.status(400).json({
          success: false,
          message: `Unsupported import collection: ${collection}`,
        });
      }

      if (!fileReceived || fileChunks.length === 0) {
        return response
          .status(400)
          .json({ success: false, message: "Missing or empty CSV file" });
      }

      try {
        const csvText = Buffer.concat(fileChunks).toString("utf-8");
        const { rows } = parseCsv(csvText);

        const importService = new ImportService();
        const result = await importService.importRows(collection, rows);

        return response.status(200).json({
          success: true,
          message: "Import completed",
          data: result,
        });
      } catch (e) {
        logger.error("Error importing collection:", e);
        return response.status(500).json({
          success: false,
          message: `Internal server error. ${e}`,
        });
      }
    });

    // Cloud Functions has already read the stream; feed busboy the raw body.
    if (request.rawBody) {
      busboy.end(request.rawBody);
    } else {
      request.pipe(busboy);
    }
  },
);

export default importRouter;
