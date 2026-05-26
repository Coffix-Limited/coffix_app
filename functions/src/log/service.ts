import { firestore } from "../config/firebaseAdmin";
import { Log } from "./interface";

class LogService {
  async log(log: Log) {
    const logRef = firestore.collection("logs");
    const logDoc = logRef.doc();
    await logDoc.set(
      {
        ...log,
        createdAt: new Date(),
      },
      { merge: true },
    );
  }
}

export default LogService;
