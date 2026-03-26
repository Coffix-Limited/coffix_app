import 'dart:convert';

import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:crypto/crypto.dart';

class CartHelper {
  /// Builds a stable string key from [selectedByGroup] (groupId → modifierId) for comparison or hashing.
  /// Keys are sorted so the same selection in any order yields the same string.
  /// Example: {'size': 'large', 'milk': 'oat'} → 'milk=oat;size=large'
  String canonicalizeSelectedByGroup(Map<String, String> selectedByGroup) {
    final keys = selectedByGroup.keys.toList()..sort();
    return keys.map((k) => '$k=${selectedByGroup[k]}').join(';');
  }

  String buildCartItemIdHashed({
    required String storeId,
    required String productId,
    required Map<String, String> selectedByGroup,
  }) {
    final mods = canonicalizeSelectedByGroup(selectedByGroup);
    final raw = "$storeId|$productId|$mods";
    return sha1.convert(utf8.encode(raw)).toString();
  }

  /// Builds modifierId → price (priceDelta) for the current selection.
  /// Uses [selectedByGroup] (groupId → modifierId) and [modifierMap] to resolve each selected modifier's price.
  /// Example: selectedByGroup {'size': 'mod_1', 'milk': 'mod_2'},
  ///  modifierMap has mod_1.priceDelta=0.5, mod_2.priceDelta=0.3 → {'mod_1': 0.5, 'mod_2': 0.3}
  Map<String, double> buildModifierPriceSnapshot({
    required Map<String, String> selectedByGroup,
    required Map<String, Modifier> modifierMap,
  }) {
    final result = <String, double>{};

    for (final modifierId in selectedByGroup.values) {
      final modifier = modifierMap[modifierId];
      if (modifier != null) {
        result[modifierId] = modifier.priceDelta ?? 0;
      }
    }
    return result;
  }

  double computeUnitTotal({
    required double basePrice,
    required Map<String, double> modifierPriceSnapshot,
  }) {
    final extra = modifierPriceSnapshot.values.fold(
      0.0,
      (sum, price) => sum + price,
    );
    return basePrice + extra;
  }
}

class ParsedVersion {
  final List<int> numbers; // [major, minor, patch]
  final int build;

  ParsedVersion(this.numbers, this.build);
}

ParsedVersion parseVersion(String version) {
  final parts = version.split('+');

  final numbers = parts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

  while (numbers.length < 3) {
    numbers.add(0);
  }

  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  return ParsedVersion(numbers, build);
}
