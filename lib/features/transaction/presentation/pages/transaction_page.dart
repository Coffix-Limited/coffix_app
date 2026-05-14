import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/features/transaction/presentation/widgets/expired_transaction.dart';
import 'package:coffix_app/features/transaction/presentation/widgets/gift_transaction.dart';
import 'package:coffix_app/features/transaction/presentation/widgets/order_transaction.dart';
import 'package:coffix_app/features/transaction/presentation/widgets/top_up_transaction.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionPage extends StatelessWidget {
  static String route = 'transaction_route';
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<TransactionCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
      ],
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
    return Scaffold(
      appBar: AppBackHeader(title: "My Transactions", showLocation: false),
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          state.whenOrNull(
            emailSent: (_, message) => AppNotification.show(context, message),
            error: (_, message) => AppNotification.error(context, message),
          );
        },
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: Text('Pull to load')),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (transactions) {
                final isLoading = context.watch<OrderCubit>().state.maybeWhen(
                  loading: (orders) => true,
                  orElse: () => false,
                );
                if (isLoading) {
                  return const Center(child: AppLoading());
                }
                if (transactions.isEmpty) {
                  return EmptyState(
                    title: "No transactions yet",
                    subtitle: "Your transactions will appear here",
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.sm),
                  padding: AppSizes.defaultPadding,
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final Transaction transaction = transactions[index];
                    if (transaction.type == "topup") {
                      return TopUpTransaction(transaction: transaction);
                    } else if (transaction.type == "order") {
                      return OrderTransaction(transaction: transaction);
                    } else if (transaction.type == "gift") {
                      return GiftTransaction(transaction: transaction);
                    } else if (transaction.type == "expired") {
                      return ExpiredTransaction(transaction: transaction);
                    }
                    return OrderTransaction(transaction: transaction);
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
      ),
    );
  }
}
