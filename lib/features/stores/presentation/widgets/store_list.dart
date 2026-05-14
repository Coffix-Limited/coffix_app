import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/location_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_guest_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StoreList extends StatelessWidget {
  const StoreList({super.key, required this.stores});

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) =>
          user.user.emailVerified == true &&
          user.user.finishedOnboarding == true,
      orElse: () => false,
    );
    void updateStore(String storeId) async {
      try {
        await context.read<StoreCubit>().updatePreferredStore(storeId: storeId);
        if (context.mounted) {
          context.goNamed(HomePage.route);
          AppNotification.show(context, "Preferred store updated");
        }
      } catch (e) {
        if (!context.mounted) return;
        AppNotification.show(context, "Failed to update store");
      }
    }

    final user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    final lat = user?.store?.location?.latitude;
    final lng = user?.store?.location?.longitude;

    return SingleChildScrollView(
      padding: AppSizes.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppField(
                  hintText: "Store Search",
                  name: "search",
                  prefixIcon: Icon(Icons.search, color: AppColors.lightGrey),
                  onChanged: (val) {
                    context.read<StoreCubit>().searchStores(val ?? "");
                  },
                ),
              ),
              SizedBox(width: AppSizes.sm),
              AppClickable(
                showSplash: false,
                onPressed: () async {
                  await getIt<StoreRepository>().openMap(lat ?? 0, lng ?? 0);
                },
                child: Image.asset(AppImages.target),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text("Please select your preferred location:"),
          const SizedBox(height: AppSizes.lg),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final store = stores[index];

              final isOpen = store.isOpenAt();
              // final isOpen = true;
              return AppClickable(
                showSplash: false,
                onPressed: () {
                  if (!isAuthenticated) {
                    AppGuestBottomSheet.show(
                      context,
                      message: "Please sign in to continue",
                    );
                  } else if (isOpen) {
                    updateStore(store.docId);
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: AppSizes.iconSizeLarge,
                      child: ClipOval(
                        child: AppCachedNetworkImage(
                          imageUrl: store.imageUrl ?? "",
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  store.name ?? "",
                                  style: AppTypography.labelM,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            store.address ?? "",
                            style: AppTypography.bodyXS.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            isOpen
                                ? "Closes at ${store.todayCloseFormatted() ?? ''}"
                                : () {
                                    final next = store.nextOpeningFormatted();
                                    return next != null
                                        ? "Closed. Opens on ${next.day} ${next.time}"
                                        : "MON-SUN is closed";
                                  }(),
                            style: AppTypography.body2XS.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    if (isOpen) AppIcon.withIconData(Icons.arrow_forward_ios),
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const Divider(),
            itemCount: stores.length,
          ),
        ],
      ),
    );
  }
}
