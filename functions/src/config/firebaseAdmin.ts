import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

const SECONDARY_APP = "printer";

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FB_PROJECT_ID,
      clientEmail: process.env.FB_CLIENT_EMAIL,
      privateKey: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    }),
  });
}

const project = process.env.GCLOUD_PROJECT ?? "";
const databaseName = project.includes("dev")
  ? "(default)"
  : "coffix-prod-australia";

export const firestore = getFirestore(admin.app(), databaseName);
export const auth = admin.auth();
export const timestamp = admin.firestore.Timestamp;
export const fieldValue = admin.firestore.FieldValue;

const printerProjectId = process.env.PRINTER_PROJECT_ID;
const printerPrivateKey = process.env.PRINTER_PRIVATE_KEY;
const printerClientEmail = process.env.PRINTER_CLIENT_EMAIL;

if (!printerProjectId || !printerClientEmail || !printerPrivateKey) {
  throw new Error(
    "Missing printer env vars: PRINTER_PROJECT_ID / PRINTER_CLIENT_EMAIL / PRINTER_PRIVATE_KEY",
  );
}

if (!admin.apps.find((app) => app?.name === SECONDARY_APP)) {
  admin.initializeApp(
    {
      credential: admin.credential.cert({
        projectId: printerProjectId,
        clientEmail: printerClientEmail,
        privateKey: printerPrivateKey?.replace(/\\n/g, "\n"),
      }),
    },
    SECONDARY_APP,
  );
}

export const printerApp = admin.app(SECONDARY_APP);
export const printerFirestore = printerApp.firestore();
