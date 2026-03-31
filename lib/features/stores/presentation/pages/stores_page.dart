import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/features/stores/presentation/widgets/store_list.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StoresPage extends StatelessWidget {
  static String route = 'stores_route';
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<StoreCubit>(),
      child: const StoresView(),
    );
  }
}

class StoresView extends StatefulWidget {
  const StoresView({super.key});

  @override
  State<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<StoresView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(
        title: "Stores",
        onBack: () {
          context.goNamed(HomePage.route);
        },
      ),
      body: BlocConsumer<StoreCubit, StoreState>(
        listener: (context, state) {
          state.whenOrNull(
            loaded: (stores) {
              if (stores.isNotEmpty) {
                context.read<CartCubit>().resetCart();
              }
            },
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => AppLoading(),
            loaded: (stores) {
              return StoreList(
                stores: stores.where((store) {
                  final next = store.nextOpeningFormatted();
                  return next != null;
                }).toList(),
              );
            },
            error: (message) =>
                AppError(title: "Failed getting store", subtitle: message),
          );
        },
      ),
    );
  }
}
