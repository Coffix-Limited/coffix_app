import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import { Log } from "../log/interface";

class LogService {
  // general write for all logs
  async log(data: Log) {
    logger.info(data.action);
    const ref = firestore.collection("logs");
    const docId = ref.doc().id;
    const log: Log = {
      docId: docId,
      // page: data.page,
      category: data.category,
      severityLevel: data.severityLevel,
      userId: data.userId,
      action: data.action,
      notes: data.notes,
      time: new Date(),
    };
    await ref.doc(docId).set(log);
  }
}
