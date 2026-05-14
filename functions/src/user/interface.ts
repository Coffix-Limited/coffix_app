export interface AppUser {
  creditAvailable?: number;
  creditExpiry?: string;
  docId?: string;
  email?: string;
  firstName?: string;
  lastName?: string;
  nickName?: string;
  mobile?: string;
  birthday?: Date // depending on how you deserialize
  suburb?: string;
  city?: string;
  preferredStoreId?: string;
  createdAt?: Date;
  emailVerified?: boolean;
  getPurchaseInfoByMail?: boolean;
  getPromotions?: boolean;
  allowWinACoffee?: boolean;
  allowWithdrawBalance?: boolean;
  lastLogin?: Date;
  disabled?: boolean;
  qrId?: string;
  fcmToken?: string;
  finishedOnboarding?: boolean;
}
