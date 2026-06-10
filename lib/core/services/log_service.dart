import 'dart:developer' as dev;

import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/features/logs/data/log.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogService extends ApiClient {
  LogService() : super(dio: Dio());

   

  Future<void> write(Log log) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final data = log.copyWith(customerId: uid).toJson()
        ..removeWhere((key, value) => value == null);
      await post("/log/create", data: data);
    } catch (e) {
      // Never let a log failure crash the app.
      dev.log("Error writing log: $e");
    }
  }

  /// [AUTH] --------------------------------------------
  Future<void> checkAccount() async {
    write(
      Log(
        page: "login_page",
        category: "App",
        severityLevel: 1,
        action: "login",
        notes: "User logged in or create account using email and password.",
      ),
    );
  }

  Future<void> forgotPassword() async {
    write(
      Log(
        page: "forgot_password_page",
        category: "App",
        severityLevel: 1,
        action: "forgot_password",
        notes: "User requested forgot password.",
      ),
    );
  }

  Future<void> deleteAccount() async {
    write(
      Log(
        page: "profile_page",
        category: "App",
        severityLevel: 1,
        action: "delete_account",
        notes: "User deleted account.",
      ),
    );
  }

  Future<void> loginGoogleSSO() async {
    write(
      Log(
        page: "login_page",
        category: "App",
        severityLevel: 1,
        action: "login",
        notes: "User logged in or create account using Google SSO.",
      ),
    );
  }

  Future<void> loginAppleSSO() async {
    write(
      Log(
        page: "login_page",
        category: "App",
        severityLevel: 1,
        action: "login",
        notes: "User logged in or create account using Apple SSO.",
      ),
    );
  }

  Future<void> logout() async {
    write(
      Log(
        page: "login_page | profile_page | otp_page",
        category: "App",
        severityLevel: 1,
        action: "User clicked `Logout` CTA button on profile page.",
        notes: "User logged out of the app.",
      ),
    );
  }

  /// [AUTH OTP] --------------------------------------------
  Future<void> getOTP() async {
    write(
      Log(
        page: "otp_page",
        category: "App",
        severityLevel: 1,
        action:
            "After entering email and email is not verified, user redirected to OTP page",
        notes: "User requested OTP for email verification to verify email.",
      ),
    );
  }

  Future<void> verifyOTP() async {
    write(
      Log(
        page: "otp_page",
        category: "App",
        severityLevel: 1,
        action: "User entered OTP and clicked `Verify` button.",
        notes: "User verified OTP for email verification.",
      ),
    );
  }

  /// [PROFILE] --------------------------------------------
  Future<void> updateProfile() async {
    write(
      Log(
        page: "profile_page",
        category: "App",
        severityLevel: 1,
        action: "updateProfile",
        notes: "User updated profile information.",
      ),
    );
  }

  /// [TRANSACTION] --------------------------------------------
  Future<void> emailCoffixCreditTransactions() async {
    write(
      Log(
        page: "profile_page",
        category: "App",
        severityLevel: 1,
        action: "transactionEmail",
        notes:
            "User clicked the Email Transactions Icon CTA button to email Coffix credit transactions.",
      ),
    );
  }

  Future<void> emailTransaction({required String transactionNumber}) async {
    write(
      Log(
        page: "transactions_page",
        category: "App",
        severityLevel: 1,
        action: "transactionEmail",
        notes:
            "User clicked the Email Transactions Icon CTA button to email transaction: $transactionNumber.",
      ),
    );
  }

  /// [GIFT] --------------------------------------------
  Future<void> giftCoffixCredit({
    required String recipientEmail,
    required double amount,
  }) async {
    write(
      Log(
        page: "gift_page",
        category: "App",
        severityLevel: 5,
        action: "User clicked `Gift Coffix Credit` CTA button on gift page.",
        notes:
            "User gifted Coffix credit to $recipientEmail with amount: $amount.",
      ),
    );
  }

  /// [STORES] --------------------------------------------
  Future<void> updateStore({required String storeName}) async {
    write(
      Log(
        page: "store_page",
        category: "App",
        severityLevel: 1,
        action: "updateStore",
        notes: "User updated store information into $storeName.",
      ),
    );
  }

  /// [ORDER] --------------------------------------------
  Future<void> reOrder() async {
    write(
      Log(
        page: "order_page",
        category: "App",
        severityLevel: 1,
        action: "reOrder",
        notes: "User click the Reorder CTA button.",
      ),
    );
  }

  /// [COFFIX CREDIT] --------------------------------------------
  Future<void> topUp({required double amount}) async {
    write(
      Log(
        page: "credit_page",
        category: "App",
        severityLevel: 5,
        action: "topUp",
        notes: "User topped up credit with amount: $amount.",
      ),
    );
  }

  /// [PRODUCTS] --------------------------------------------
  Future<void> selectCategory({required String category}) async {
    write(
      Log(
        page: "products_page",
        category: "App",
        severityLevel: 1,
        action: "User selected category: $category. from rows of categories",
        notes: "User selected category: $category.",
      ),
    );
  }

  Future<void> viewProduct({required Product product}) async {
    write(
      Log(
        page: "products_page",
        category: "App",
        severityLevel: 1,
        action: "User viewed product: ${product.name}. from list of products",
        notes: "User viewed product: ${product.name}.",
      ),
    );
  }

  Future<void> addProductToCart({
    required Product product,
    required int quantity,
  }) async {
    write(
      Log(
        page: "product_page",
        category: "App",
        severityLevel: 1,
        action: "User click `Add To Order` CTA button on product page.",
        notes:
            "User added product: ${product.name} to cart with quantity: $quantity.",
      ),
    );
  }

  Future<void> customiseProduct({
    required Map<String, String> selectedModifiers,
  }) async {
    write(
      Log(
        page: "customise_page",
        category: "App",
        severityLevel: 1,
        action: "User click `Update` CTA button on  customise product page.",
        notes:
            "User customised product with selected modifiers: $selectedModifiers.",
      ),
    );
  }

  Future<void> removeProductFromCart({required Product product}) async {
    write(
      Log(
        page: "cart_page",
        category: "App",
        severityLevel: 1,
        action: "User click `X` CTA button on cart page.",
        notes: "User removed product: ${product.name} from cart.",
      ),
    );
  }

  Future<void> saveDraft() async {
    write(
      Log(
        page: "cart_page",
        category: "App",
        severityLevel: 1,
        action: "draft",
        notes: "User saved the current cart as a draft.",
      ),
    );
  }

  /// [DRAFT] --------------------------------------------
  Future<void> removeProductFromDraft() async {
    write(
      Log(
        page: "drafts_page",
        category: "App",
        severityLevel: 1,
        action: "User click `X` CTA button on drafts page.",
        notes: "User removed item from draft.",
      ),
    );
  }

  /// [PAYMENT]
  Future<void> createPaymentSession() async {
    write(
      Log(
        page: "payment_options_page",
        category: "App",
        severityLevel: 5,
        action: "payment",
        notes:
            "User click the Pay CTA button to create a payment session for ordering a product.",
      ),
    );
  }

  Future<void> payUsingCoffixCredit() async {
    write(
      Log(
        page: "payment_options_page",
        category: "App",
        severityLevel: 5,
        action: "payment",
        notes: "User click the Pay CTA button to pay using Coffix Credit.",
      ),
    );
  }

  /// [NAVIGATION] --------------------------------------------
  Future<void> navigate({required String page}) async {
    if (page.isEmpty) return;
    write(
      Log(
        page: "${page}_page",
        category: "App",
        severityLevel: 1,
        action: "navigation",
        notes: "User navigated to $page page.",
      ),
    );
  }

  /// [ERRORS] --------------------------------------------
  /// [AUTH ERROR] --------------------------------------------
  Future<void> authError({required String action}) async {
    write(
      Log(
        page: "login_page",
        category: "AppError",
        severityLevel: 3,
        action: action,
        notes: "User encountered an error while $action.",
      ),
    );
  }

  Future<void> otpError() async {
    write(
      Log(
        page: "otp_page",
        category: "AppError",
        severityLevel: 3,
        action: "User entered invalid OTP and clicked `Verify` button.",
        notes: "User entered invalid OTP for email verification.",
      ),
    );
  }

  Future<void> otpExpired() async {
    write(
      Log(
        page: "otp_page",
        category: "AppError",
        severityLevel: 3,
        action: "User entered expired OTP and clicked `Verify` button.",
        notes: "User entered expired OTP for email verification.",
      ),
    );
  }
}
