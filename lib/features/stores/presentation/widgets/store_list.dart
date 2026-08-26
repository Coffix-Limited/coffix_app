import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_guest_bottom_sheet.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class StoreList extends StatelessWidget {
  const StoreList({super.key, required this.stores});

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user.emailVerified == true,
      orElse: () => false,
    );
    final isFinishedOnboarding = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user.finishedOnboarding == true,
      orElse: () => false,
    );
    void updateStore(String storeId, String storeName) async {
      try {
        // Reconcile the cart against the new store before switching: drop
        // items not available there, keep + re-stamp the rest.
        final catalog = context.read<ProductCubit>().state.maybeWhen(
          loaded: (products, _, _) => products,
          orElse: () => <ProductWithCategory>[],
        );
        final removed = context.read<CartCubit>().reconcileForStore(newStoreId: storeId, catalog: catalog);

        LogService().updateStore(storeName: storeName);
        await context.read<StoreCubit>().updatePreferredStore(storeId: storeId);
        if (context.mounted) {
          context.goNamed(HomePage.route);
          AppNotification.show(
            context,
            removed > 0 ? "Some items were removed — not available at this store" : "Preferred store updated",
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        AppNotification.show(context, "Failed to update store");
      }
    }

    Future<Position> getCurrentLocation() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error("Location permissions are denied forever.");
      }

      return await Geolocator.getCurrentPosition();
    }

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
                  try {
                    final position = await getCurrentLocation();
                    if (!context.mounted) return;
                    await context.read<StoreCubit>().sortStoresByDistance(position: position);
                  } catch (e) {
                    if (!context.mounted) return;
                    AppNotification.show(context, "Enable location access to sort stores by distance");
                  }
                },
                child: Image.asset(AppImages.target),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text("Please select your preferred location:"),
          const SizedBox(height: AppSizes.lg),
          stores.isEmpty
              ? EmptyState(title: "No stores found", subtitle: "Please try again later", icon: Icons.search)
              : ListView.separated(
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
                            message: "Please complete your profile to continue",
                            isAuthenticated: isAuthenticated,
                            isFinishedOnboarding: isFinishedOnboarding,
                          );
                        } else if (!isFinishedOnboarding) {
                          AppGuestBottomSheet.show(
                            context,
                            message: "Please finish first setting up your profile.",
                            isAuthenticated: isAuthenticated,
                            isFinishedOnboarding: isFinishedOnboarding,
                          );
                        } else if (isOpen) {
                          updateStore(store.docId, store.name ?? "");
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: AppSizes.iconSizeLarge,
                            child: ClipOval(child: AppCachedNetworkImage(imageUrl: store.imageUrl ?? "")),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [Expanded(child: Text(store.name ?? "", style: AppTypography.labelM))],
                                ),
                                Text(store.address ?? "", style: AppTypography.bodyXS.copyWith(color: AppColors.black)),
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
                                    color: isOpen ? AppColors.success : AppColors.error,
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
