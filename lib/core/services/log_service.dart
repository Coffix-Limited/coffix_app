import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/logs/data/log.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LogService {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  String? _appVersion;

  Future<String> _getAppVersion() async {
    _appVersion ??= await PackageInfo.fromPlatform().then(
      (info) => '${info.version}+${info.buildNumber}',
    );
    return _appVersion!;
  }

  Future<void> write(Log log) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final appVersion = await _getAppVersion();

      final data = log.toJson()
        ..remove('docId')
        ..['customerId'] ??= uid
        ..['appVersion'] = appVersion
        ..['time'] = TimeUtils.now();

      await _firestore.collection('logs').add(data);
    } catch (_) {
      // Never let a log failure crash the app.
    }
  }

  /// [AUTH] --------------------------------------------
  Future<void> checkAccount() async {
    write(
      Log(
        page: "login_page",
        category: "auth",
        severityLevel: "info",
        action: "User clicked `Next` CTA button on login form.",
        notes: "User logged in or create account.",
      ),
    );
  }

  Future<void> forgotPassword() async {
    write(
      Log(
        page: "forgot_password_page",
        category: "auth",
        severityLevel: "info",
        action:
            "User clicked `Forgot Password` CTA button on forgot password page.",
        notes: "User requested forgot password.",
      ),
    );
  }

  Future<void> deleteAccount() async {
    write(
      Log(
        page: "profile_page",
        category: "auth",
        severityLevel: "info",
        action: "User clicked `Delete Account` CTA button on profile page.",
        notes: "User deleted account.",
      ),
    );
  }

  Future<void> loginGoogleSSO() async {
    write(
      Log(
        page: "login_page",
        category: "auth",
        severityLevel: "info",
        action: "User clicked `Google SSO` CTA button on login form.",
        notes: "User logged in or create account using Google SSO.",
      ),
    );
  }

  Future<void> loginAppleSSO() async {
    write(
      Log(
        page: "login_page",
        category: "auth",
        severityLevel: "info",
        action: "User clicked `Apple SSO` CTA button on login form.",
        notes: "User logged in or create account using Apple SSO.",
      ),
    );
  }

  Future<void> logout() async {
    write(
      Log(
        page: "login_page | profile_page | otp_page",
        category: "auth",
        severityLevel: "info",
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
        category: "auth",
        severityLevel: "info",
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
        category: "auth",
        severityLevel: "info",
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
        category: "profile",
        severityLevel: "info",
        action: "User updated profile information.",
        notes: "User updated profile information.",
      ),
    );
  }

  /// [TRANSACTION] --------------------------------------------
  Future<void> emailCoffixCreditTransactions() async {
    write(
      Log(
        page: "transactions_page",
        category: "transactions",
        severityLevel: "info",
        action:
            "User clicked `Email Transactions` Icon CTA button on transactions page.",
        notes: "User emailed Coffix credit transactions.",
      ),
    );
  }

  Future<void> emailTransaction({required String transactionNumber}) async {
    write(
      Log(
        page: "transactions_page",
        category: "transactions",
        severityLevel: "info",
        action:
            "User clicked `Email Transactions` Icon CTA button on transactions page.",
        notes: "User emailed transaction: $transactionNumber.",
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
        category: "gift",
        severityLevel: "info",
        action: "User clicked `Gift Coffix Credit` CTA button on gift page.",
        notes:
            "User gifted Coffix credit to $recipientEmail with amount: $amount.",
      ),
    );
  }

  /// [STORES] --------------------------------------------
  Future<void> updateStore() async {
    write(
      Log(
        page: "store_page",
        category: "stores",
        severityLevel: "info",
        action: "User updated store information.",
        notes: "User updated store information.",
      ),
    );
  }

  /// [ORDER] --------------------------------------------
  Future<void> reOrder() async {
    write(
      Log(
        page: "order_page",
        category: "order",
        severityLevel: "info",
        action: "User click `ReOrder` CTA button on order page.",
        notes: "User reordered an order.",
      ),
    );
  }

  /// [COFFIX CREDIT] --------------------------------------------
  Future<void> topUp({required double amount}) async {
    write(
      Log(
        page: "credit_page",
        category: "coffix_credit",
        severityLevel: "info",
        action: "User clicked `Top Up` CTA button on credit page.",
        notes: "User topped up credit with amount: $amount.",
      ),
    );
  }

  /// [PRODUCTS] --------------------------------------------
  Future<void> selectCategory({required String category}) async {
    write(
      Log(
        page: "products_page",
        category: "products",
        severityLevel: "info",
        action: "User selected category: $category. from rows of categories",
        notes: "User selected category: $category.",
      ),
    );
  }

  Future<void> viewProduct({required Product product}) async {
    write(
      Log(
        page: "products_page",
        category: "products",
        severityLevel: "info",
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
        category: "products",
        severityLevel: "info",
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
        category: "products",
        severityLevel: "info",
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
        category: "products",
        severityLevel: "info",
        action: "User click `X` CTA button on cart page.",
        notes: "User removed product: ${product.name} from cart.",
      ),
    );
  }

  Future<void> saveDraft() async {
    write(
      Log(
        page: "cart_page",
        category: "products",
        severityLevel: "info",
        action: "User click `Save Draft` CTA button on cart page.",
        notes: "User saved draft of cart.",
      ),
    );
  }

  /// [DRAFT] --------------------------------------------
  Future<void> removeProductFromDraft() async {
    write(
      Log(
        page: "drafts_page",
        category: "drafts",
        severityLevel: "info",
        action: "User click `X` CTA button on drafts page.",
        notes: "User removed item from draft.",
      ),
    );
  }

  /// [PAYMENT]
  Future<void> selectPickupTime() async {
    write(
      Log(
        page: "payment_page",
        category: "payment",
        severityLevel: "info",
        action: "User selected pickup time from list of pickup times.",
        notes: "User selected pickup time.",
      ),
    );
  }

  Future<void> selectPaymentMethod() async {
    write(
      Log(
        page: "payment_method_page",
        category: "payment",
        severityLevel: "info",
        action: "User selected payment method from list of payment methods.",
        notes: "User selected payment method.",
      ),
    );
  }

  Future<void> openPaymentSession() async {
    write(
      Log(
        page: "payment_method_page",
        category: "payment",
        severityLevel: "info",
        action: "User clicked `Pay` CTA button on payment method page.",
        notes: "User opened payment session.",
      ),
    );
  }

  /// [NAVIGATION] --------------------------------------------
  Future<void> navigate({required String page}) async {
    write(
      Log(
        page: "${page}_page",
        category: "navigation",
        severityLevel: "info",
        action: "User navigated to $page page.",
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
        category: "auth",
        severityLevel: "error",
        action: action,
        notes: "User encountered an error while $action.",
      ),
    );
  }

  Future<void> otpError() async {
    write(
      Log(
        page: "otp_page",
        category: "auth",
        severityLevel: "error",
        action: "User entered invalid OTP and clicked `Verify` button.",
        notes: "User entered invalid OTP for email verification.",
      ),
    );
  }

  Future<void> otpExpired() async {
    write(
      Log(
        page: "otp_page",
        category: "auth",
        severityLevel: "error",
        action: "User entered expired OTP and clicked `Verify` button.",
        notes: "User entered expired OTP for email verification.",
      ),
    );
  }
}
