import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/drafts/presentation/widgets/draft_card.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            deleted: (data) => _DraftsContent(drafts: data.drafts),
          );
        },
      ),
    );
  }
}

class _DraftsContent extends StatelessWidget {
  const _DraftsContent({required this.drafts});

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
          return DraftCard(draft: drafts[index]);
        },
      ),
    );
  }
}
