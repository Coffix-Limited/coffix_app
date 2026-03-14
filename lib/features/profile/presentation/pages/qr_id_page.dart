import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
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
      appBar: const AppBackHeader(title: 'My QR ID'),

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
                  Center(
                    child: QrImageView(
                      data: qrId,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SelectableText(qrId, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
    );
  }
}
