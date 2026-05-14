import 'package:bloc/bloc.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_modifier_state.dart';
part 'product_modifier_cubit.freezed.dart';

class ProductModifierCubit extends Cubit<ProductModifierState> {
  ProductModifierCubit() : super(ProductModifierState());

  double getTotalPrice(List<Modifier> modifiers) {
    return modifiers.fold(0.0, (sum, mod) => sum + (mod.priceDelta ?? 0));
  }

  void initProductModifiers({
    required Product product,
    required List<Modifier> allModifiers,
  }) {
    final groupCodes = product.modifierGroupIds?.toSet() ?? {};
    if (groupCodes.isEmpty) {
      emit(ProductModifierState(modifiers: [], totalPrice: 0));
      return;
    }
    final inScope = allModifiers.where((m) => groupCodes.contains(m.groupId));
    final defaults = inScope.where((m) => m.isDefault == true).toList();
    emit(
      ProductModifierState(
        modifiers: defaults,
        totalPrice: getTotalPrice(defaults),
      ),
    );
  }

  void initFromCartItem({
    required Product product,
    required List<Modifier> allModifiers,
    required Map<String, String> selectedByGroup,
  }) {
    final groupCodes = product.modifierGroupIds?.toSet() ?? {};
    if (groupCodes.isEmpty || selectedByGroup.isEmpty) {
      emit(ProductModifierState(modifiers: [], totalPrice: 0));
      return;
    }
    final inScope = allModifiers.where((m) => groupCodes.contains(m.groupId));
    final selected = <Modifier>[];
    for (final entry in selectedByGroup.entries) {
      final matches = inScope.where(
        (m) => m.groupId == entry.key && m.docId == entry.value,
      );
      if (matches.isNotEmpty) selected.add(matches.first);
    }
    emit(
      ProductModifierState(
        modifiers: selected,
        totalPrice: getTotalPrice(selected),
      ),
    );
  }

  void selectModifiers({
    required Modifier modifier,
    required String bundleGroupId,
  }) {
    final normalizedModifier = modifier.groupId != bundleGroupId
        ? modifier.copyWith(groupId: bundleGroupId)
        : modifier;

    final current = state.modifiers;
    final alreadySelected = current.any(
      (m) => m.docId == normalizedModifier.docId,
    );

    final List<Modifier> updated;
    if (alreadySelected) {
      updated =
          current.where((m) => m.docId != normalizedModifier.docId).toList();
    } else {
      updated = [
        ...current.where((m) => m.groupId != bundleGroupId),
        normalizedModifier,
      ];
    }

    emit(
      ProductModifierState(
        modifiers: updated,
        totalPrice: getTotalPrice(updated),
      ),
    );
  }

  void resetModifiers() {
    emit(ProductModifierState(modifiers: [], totalPrice: 0));
  }
}
