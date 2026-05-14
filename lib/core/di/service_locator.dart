import 'package:coffix_app/data/internet_connection_service.dart';
import 'package:coffix_app/data/repositories/app_repository.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/data/repositories/coupon_repository.dart';
import 'package:coffix_app/data/repositories/modifier_repository.dart';
import 'package:coffix_app/data/repositories/order_repository.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:coffix_app/data/repositories/product_repository.dart';
import 'package:coffix_app/data/repositories/profile_repository.dart';
import 'package:coffix_app/data/repositories/referral_repository.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/data/repositories/transaction_repository.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/features/app/data/app_repository_impl.dart';
import 'package:coffix_app/features/coupons/data/coupon_repository_impl.dart';
import 'package:coffix_app/features/coupons/logic/coupon_cubit.dart';
import 'package:coffix_app/features/app/logic/app_cubit.dart';
import 'package:coffix_app/features/auth/data/auth_repository_impl.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/auth/logic/otp_cubit.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository_impl.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/modifier/data/modifier_repository_impl.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/credit/logic/credit_cubit.dart';
import 'package:coffix_app/features/order/data/order_repository_impl.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/payment/data/payment_repository_impl.dart';
import 'package:coffix_app/features/payment/logic/payment_cubit.dart';
import 'package:coffix_app/features/products/data/product_repository_impl.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/profile/data/profile_repository_impl.dart';
import 'package:coffix_app/features/profile/domain/usecase/update_profile.dart';
import 'package:coffix_app/features/profile/logic/profile_cubit.dart';
import 'package:coffix_app/features/referral/domain/repository/referral_repository_impl.dart';
import 'package:coffix_app/features/referral/logic/referral_cubit.dart';
import 'package:coffix_app/features/stores/data/store_repository_impl.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/features/network/logic/network_cubit.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/features/transaction/domain/transaction_repository_impl.dart';
import 'package:coffix_app/features/transaction/domain/usecases/download_transaction.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Initializes all singleton services for the app.
Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<InternetConnectionService>(
    () => InternetConnectionService(),
  );

  getIt.registerLazySingleton<NetworkCubit>(
    () => NetworkCubit(internetService: getIt<InternetConnectionService>()),
  );

  getIt.registerLazySingleton<AppRepository>(() => AppRepositoryImpl());
  getIt.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ModifierRepository>(
    () => ModifierRepositoryImpl(storeRepository: getIt<StoreRepository>()),
  );
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl());
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(storeRepository: getIt<StoreRepository>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(),
  );
  getIt.registerLazySingleton<DownloadTransaction>(() => DownloadTransaction());
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl());
  getIt.registerLazySingleton<DraftRepository>(() => DraftRepositoryImpl());
  getIt.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(),
  );
  getIt.registerLazySingleton<ReferralCubit>(
    () => ReferralCubit(referralRepository: getIt<ReferralRepository>()),
  );
  getIt.registerLazySingleton<CouponRepository>(() => CouponRepositoryImpl());
  getIt.registerLazySingleton<CouponCubit>(
    () => CouponCubit(couponRepository: getIt<CouponRepository>()),
  );
  getIt.registerLazySingleton<LogService>(() => LogService());
  // App Cubit
  getIt.registerLazySingleton<AppCubit>(
    () => AppCubit(appRepository: getIt<AppRepository>()),
  );
  // Auth Cubit
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      authRepository: getIt<AuthRepository>(),
      storeRepository: getIt<StoreRepository>(),
    ),
  );

  // Cart Cubit
  getIt.registerLazySingleton<CartCubit>(() => CartCubit());

  // Modifier Cubit
  getIt.registerLazySingleton<ModifierCubit>(
    () => ModifierCubit(modifierRepository: getIt<ModifierRepository>()),
  );

  // Order Cubit
  getIt.registerLazySingleton<OrderCubit>(
    () => OrderCubit(orderRepository: getIt<OrderRepository>()),
  );

  // Otp Cubit
  getIt.registerLazySingleton<OtpCubit>(
    () => OtpCubit(authRepository: getIt<AuthRepository>()),
  );
  // Credit Cubit
  getIt.registerLazySingleton<CreditCubit>(
    () => CreditCubit(paymentRepository: getIt<PaymentRepository>()),
  );
  // Draft Cubit
  getIt.registerLazySingleton<DraftCubit>(
    () => DraftCubit(draftRepository: getIt<DraftRepository>()),
  );

  // Payment Cubit
  getIt.registerLazySingleton<PaymentCubit>(
    () => PaymentCubit(paymentRepository: getIt<PaymentRepository>()),
  );

  // Product Modifier Cubit
  getIt.registerLazySingleton<ProductModifierCubit>(
    () => ProductModifierCubit(),
  );

  // Transaction Cubit
  getIt.registerLazySingleton<TransactionCubit>(
    () =>
        TransactionCubit(transactionRepository: getIt<TransactionRepository>()),
  );

  // Update Profile Use Case
  getIt.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(profileRepository: getIt<ProfileRepository>()),
  );

  // Profile Cubit
  getIt.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      profileRepository: getIt<ProfileRepository>(),
    ),
  );

  // Product Cubit
  getIt.registerLazySingleton<ProductCubit>(
    () => ProductCubit(productRepository: getIt<ProductRepository>()),
  );

  // Store Cubit
  getIt.registerLazySingleton<StoreCubit>(
    () => StoreCubit(storeRepository: getIt<StoreRepository>()),
  );
}
