import { getAuth, UserRecord } from "firebase-admin/auth";
import { firestore } from "../config/firebaseAdmin";
import FirebaseService from "../firebase/service";
import { CreateStaffSchema } from "./schema";

export class StaffService {
  /**
   * Returns true when the email already belongs to an app user in the
   * `customers` collection. Staff are not allowed to reuse a customer email.
   */
  async customerExists(email: string): Promise<boolean> {
    const customer = await new FirebaseService().findCustomerByEmail(email);
    return customer !== null;
  }

  async createStaffAuthUser(email: string): Promise<UserRecord> {
    return getAuth().createUser({ email });
  }

  /**
   * Writes the staff doc using the Auth UID as the document ID, mirroring the
   * reference implementation.
   */
  async createStaffDoc(
    uid: string,
    { email, role, storeIds, firstName, lastName }: CreateStaffSchema,
  ): Promise<void> {
    await firestore
      .collection("staffs")
      .doc(uid)
      .set({
        docId: uid,
        email,
        role,
        storeIds: storeIds ?? [],
        disabled: false,
        createdAt: new Date(),
        firstName: firstName ?? null,
        lastName: lastName ?? null,
      });
  }

  async deleteStaffAuthUser(uid: string): Promise<void> {
    await getAuth().deleteUser(uid);
  }
}
