import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DraftsPage extends StatelessWidget {
  static String route = 'drafts_route';
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<DraftCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
      ],
      child: const DraftsView(),
    );
  }
}

class DraftsView extends StatefulWidget {
  const DraftsView({super.key});

  @override
  State<DraftsView> createState() => _DraftsViewState();
}

class _DraftsViewState extends State<DraftsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBackHeader(title: 'My Drafts', showLocation: false),
      body: BlocBuilder<DraftCubit, DraftState>(
        builder: (context, state) {
          return state.map(
            initial: (drafts) =>
                const Center(child: CircularProgressIndicator()),
            loading: (drafts) =>
                const Center(child: CircularProgressIndicator()),
            error: (msg) => Center(
              child: Padding(
                padding: AppSizes.defaultPadding,
                child: Text(msg.message, textAlign: TextAlign.center),
              ),
            ),
            loaded: (data) => _DraftsContent(drafts: data.drafts),
            success: (data) => _DraftsContent(drafts: data.drafts),
          );
        },
      ),
    );
  }
}

class _DraftsContent extends StatelessWidget {
  const _DraftsContent({super.key, required this.drafts});

  final List<Draft> drafts;

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) {
      return Padding(
        padding: AppSizes.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: EmptyState(
                title: 'No drafts yet',
                subtitle: 'Saved carts will appear here',
                icon: Icons.drafts_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return SafeArea(
      child: ListView.separated(
        padding: AppSizes.defaultPadding,
        itemCount: drafts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, index) {
          return _DraftCard(draft: drafts[index]);
        },
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});

  final Draft draft;

  void _loadDraftIntoCart(BuildContext context, Cart cart) {
    final cartCubit = context.read<CartCubit>();
    cartCubit.resetCart();
    for (final item in cart.items ?? []) {
      try {
        cartCubit.addProduct(newItem: item);
      } catch (_) {}
    }
    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final items = draft.carts.first.items ?? [];
    final Cart cart = draft.cart ?? Cart();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.md),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: AppColors.error,
                        child: const Icon(
                          Icons.close,
                          size: AppSizes.iconSizeMedium,
                          color: AppColors.white,
                        ),
                      ),
                      onPressed: () => context.read<DraftCubit>().deleteDraft(
                        draftId: draft.id ?? '',
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cart.items?.length ?? 0,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = cart.items?[index];
                          final imageUrl = item?.productImageUrl ?? '';
                          final modifierLabels =
                              item?.modifierLabelSnapshot.values.toList() ??
                              [] as List<String>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.sm,
                                    ),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.softGrey,
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.sm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.coffee,
                                      color: AppColors.lightGrey,
                                      size: AppSizes.iconSizeSmall,
                                    ),
                                  ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item?.productName ?? ''} (x${item?.quantity ?? 0})',
                                        style: AppTypography.bodyM600,
                                      ),
                                      if (modifierLabels.isNotEmpty) ...[
                                        const SizedBox(height: AppSizes.xs),
                                        Text(
                                          modifierLabels.join(', '),
                                          style: AppTypography.body3XS,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                height: 24,
                width: 56,
                onPressed: () =>
                    _loadDraftIntoCart(context, draft.cart ?? Cart()),
                label: 'Order',
                textStyle: AppTypography.body2XS.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
