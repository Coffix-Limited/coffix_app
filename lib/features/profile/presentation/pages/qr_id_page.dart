import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrIdPage extends StatelessWidget {
  static String route = 'qr_id_route';
  const QrIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const QrIdView();
  }
}

class QrIdView extends StatelessWidget {
  const QrIdView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userWithStore = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    final qrId = userWithStore?.user.qrId;

    return Scaffold(
      appBar: const AppBackHeader(title: "Coffix ID", showLocation: false),

      body: qrId == null || qrId.isEmpty
          ? Center(
              child: Text(
                'No customer ID available',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : SingleChildScrollView(
              padding: AppSizes.defaultPadding,
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.xxl),
                  Text(
                    "Please show your ID to your barista",
                    style: AppTypography.bodyM,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSizes.xxxxxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          color: AppColors.background,
                          boxShadow: [AppColors.shadow],
                          child: Text(
                            "${userWithStore?.user.firstName} ${userWithStore?.user.lastName}",
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyS.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlackColor,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.sm),
                        AppCard(
                          color: AppColors.background,
                          boxShadow: [AppColors.shadow],
                          child: Center(
                            child: QrImageView(
                              data: qrId,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),
                  SelectableText(qrId, style: AppTypography.bodyM600),
                ],
              ),
            ),
    );
  }
}
