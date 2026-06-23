abstract class ProfileRepository {
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? nickName,
    String? mobile,
    DateTime? birthday,
    String? suburb,
    String? city,
    String? preferredStoreId,
    bool? allowNotifications,
    bool? getPromotions,
    bool? getPurchaseInfoByMail,
    bool? allowWithdrawBalance,
  });
  Future<void> sendCoffeeOnUs({required List<Map<String, dynamic>> datas});
  Future<void> sendGift({
    required String recipientFirstName,
    required String recipientLastName,
    required String recipientEmail,
    required double amount,
  });
}
