import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StoreList extends StatelessWidget {
  const StoreList({super.key, required this.stores});

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
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

    return SingleChildScrollView(
      padding: AppSizes.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppField(hintText: "Store Search", name: "search"),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text("Please select your preferred loaction:"),
          const SizedBox(height: AppSizes.lg),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final store = stores[index];
              final dateRange = DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(hours: 1)),
              );
              final isOpen = store.isOpenAt();
              return AppClickable(
                showSplash: false,
                onPressed: () {
                  if (isOpen) {
                    updateStore(store.docId);
                  }
                },
                child: Opacity(
                  opacity: isOpen ? 1 : 0.6,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppSizes.iconSizeLarge,
                        backgroundImage: NetworkImage(store.imageUrl ?? ""),
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
                                    style: AppTypography.labelS,
                                  ),
                                ),
                                if (!isOpen)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: AppSizes.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGrey.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.sm,
                                      ),
                                    ),
                                    child: Text(
                                      "Closed",
                                      style: AppTypography.body2XS.copyWith(
                                        color: AppColors.lightGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              store.address ?? "",
                              style: AppTypography.body2XS.copyWith(
                                color: AppColors.lightGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      if (isOpen) AppIcon.withIconData(Icons.arrow_forward_ios),
                    ],
                  ),
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
