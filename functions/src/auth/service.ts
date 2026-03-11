import { getAuth } from "firebase-admin/auth";

export class AuthService {
  async customerHasAccount({ email }: { email: string }) {
    try {
      // verify if the user is already registered
      const user = await getAuth().getUserByEmail(email);
      return !!user;
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        return false;
      }
      throw error;
    }
  }
}
