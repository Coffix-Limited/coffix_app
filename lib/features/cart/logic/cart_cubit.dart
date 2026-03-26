import 'package:bloc/bloc.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_cubit.freezed.dart';
part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  Map<String, String>? selectedByGroup;
  CartCubit() : super(CartState());

  void addProduct({required CartItem newItem}) {
    final Cart? currentCart = state.cart;

    // 1. if no cart yet -> create cart
    if (currentCart == null) {
      emit(
        state.copyWith(
          cart: Cart(storeId: newItem.storeId, items: [newItem], duration: 0),
        ),
      );
      return;
    }

    // 2. cart is store-scopred -> block or clear when store changes
    if (currentCart.storeId != newItem.storeId) {
      print('Cannot add product to different store cart');
      throw Exception('Cannot add product to different store cart');
    }

    // 3. merge identical config by cartItemId
    final index =
        currentCart.items?.indexWhere((item) => item.id == newItem.id) ?? -1;
    if (index == -1) {
      emit(
        state.copyWith(
          cart: currentCart.copyWith(
            items: [...currentCart.items ?? [], newItem],
          ),
        ),
      );
      return;
    }

    final CartItem existing =
        currentCart.items?[index] ??
        CartItem(
          id: '',
          storeId: '',
          productId: '',
          productName: '',
          productImageUrl: '',
          quantity: 0,
          selectedByGroup: {},
          basePrice: 0,
          modifierPriceSnapshot: {},
          unitTotal: 0,
          lineTotal: 0,
          createdAt: DateTime.now(),
        );
    final int newQuantity = existing.quantity + newItem.quantity;

    final updated = existing.copyWith(
      quantity: newQuantity,
      lineTotal: existing.unitTotal * newQuantity,
    );

    final List<CartItem> updatedItems = [...currentCart.items ?? []]
      ..[index] = updated;

    emit(state.copyWith(cart: currentCart.copyWith(items: updatedItems)));
  }

  void updateProduct({
    required String cartItemId,
    required CartItem updatedItem,
  }) {
    final Cart? currentCart = state.cart;
    if (currentCart == null) return;
    final index =
        currentCart.items?.indexWhere((item) => item.id == cartItemId) ?? -1;
    if (index == -1) return;
    final List<CartItem> updatedItems = [...?currentCart.items]
      ..[index] = updatedItem;
    emit(state.copyWith(cart: currentCart.copyWith(items: updatedItems)));
  }

  void removeProduct({required String cartItemId}) {
    final Cart? currentCart = state.cart;
    if (currentCart == null) return;
    final newItems =
        currentCart.items?.where((item) => item.id != cartItemId) ?? [];
    if (newItems.isEmpty) {
      emit(state.copyWith(cart: null));
    } else {
      emit(
        state.copyWith(cart: currentCart.copyWith(items: newItems.toList())),
      );
    }
  }

  void resetCart() {
    emit(state.copyWith(cart: null));
  }

  void pickTime(double duration) {
    emit(state.copyWith(cart: state.cart?.copyWith(duration: duration)));
  }

  void setPaymentMethod(PaymentMethod paymentMethod) {
    emit(
      state.copyWith(cart: state.cart?.copyWith(paymentMethod: paymentMethod)),
    );
  }
}
