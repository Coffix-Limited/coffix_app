import { firestore } from "../config/firebaseAdmin";
import { Log } from "./interface";

export class LogService {
  async log(log: Log): Promise<Log> {
    const logDocRef = firestore.collection("logs").doc();

    const logDoc: Log = {
      ...log,
      docId: logDocRef.id,
      time: new Date(),
    };

    await logDocRef.set(logDoc);

    return logDoc;
  }
}
