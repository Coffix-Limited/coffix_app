import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

(String, Color) _transactionStatusStyle(TransactionStatus? s) {
  return switch (s) {
    TransactionStatus.paid => ('Paid', AppColors.success),
    TransactionStatus.created => ('Created', AppColors.primary),
    TransactionStatus.approved => ('Approved', AppColors.success),
    TransactionStatus.failed => ('Failed', AppColors.error),
    _ => ('—', AppColors.lightGrey),
  };
}

Map<DateTime, List<Transaction>> _groupByDay(List<Transaction> transactions) {
  final map = <DateTime, List<Transaction>>{};
  for (final t in transactions) {
    final d = t.createdAt;
    if (d == null) continue;
    final day = DateTime(d.year, d.month, d.day);
    map.putIfAbsent(day, () => []).add(t);
  }
  for (final list in map.values) {
    list.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
  }
  return map;
}

List<_ListItem> _buildListItems(Map<DateTime, List<Transaction>> grouped) {
  final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final items = <_ListItem>[];
  for (final date in dates) {
    items.add(_ListItem(isHeader: true, date: date, transaction: null));
    for (final t in grouped[date]!) {
      items.add(_ListItem(isHeader: false, date: null, transaction: t));
    }
  }
  return items;
}

class _ListItem {
  final bool isHeader;
  final DateTime? date;
  final Transaction? transaction;
  _ListItem({required this.isHeader, this.date, this.transaction});
}

class TransactionPage extends StatelessWidget {
  static String route = 'transaction_route';
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<TransactionCubit>(),
      child: const TransactionView(),
    );
  }
}

class TransactionView extends StatefulWidget {
  const TransactionView({super.key});

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions', style: theme.textTheme.titleLarge),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Pull to load')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Text(
                    'No transactions yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }
              final grouped = _groupByDay(transactions);
              final items = _buildListItems(grouped);
              return ListView.builder(
                padding: AppSizes.defaultPadding,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isHeader && item.date != null) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : AppSizes.lg,
                        bottom: AppSizes.sm,
                      ),
                      child: Text(
                        item.date?.formatDate() ?? '—',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.lightGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  final t = item.transaction!;
                  final (statusLabel, statusColor) = _transactionStatusStyle(
                    t.status,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${t.orderNumber?.last6 ?? '—'}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    t.amount?.toCurrencySuperscript(
                                          style: theme.textTheme.titleSmall,
                                        ) ??
                                        TextSpan(text: '0.00'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.xs),
                          if (t.createdAt != null)
                            Text(
                              t.createdAt?.formatDate() ?? '—',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.lightGrey,
                              ),
                            ),
                          const SizedBox(height: AppSizes.xs),
                          Row(
                            children: [
                              StatusChip(
                                label: statusLabel,
                                color: statusColor,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              if (t.paymentMethod != null)
                                Text(
                                  "via ${t.paymentMethod?.label ?? '—'}",
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            error: (message) => Center(
              child: Padding(
                padding: AppSizes.defaultPadding,
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
          );
        },
      ),
    );
  }
}
