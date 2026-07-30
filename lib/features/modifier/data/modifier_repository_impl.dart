import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/data/repositories/modifier_repository.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/modifier/data/model/modifier_group.dart';
import 'package:coffix_app/features/modifier/data/model/modifier_group_bundle.dart';
import 'package:coffix_app/features/products/data/model/product.dart';

class ModifierRepositoryImpl implements ModifierRepository {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final StoreRepository _storeRepository;

  ModifierRepositoryImpl({required StoreRepository storeRepository}) : _storeRepository = storeRepository;

  static const int _whereInLimit = 10;

  /// Fetches modifier group documents from Firestore by [groupIds].
  /// Queries in chunks of 10 (whereIn limit) and returns groups in the same order as [groupIds].
  @override
  Future<List<ModifierGroup>> getModifierGroups({required List<String> groupIds}) async {
    final validIds = groupIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) return [];

    final List<ModifierGroup> all = [];
    for (var i = 0; i < validIds.length; i += _whereInLimit) {
      final chunk = validIds.skip(i).take(_whereInLimit).toList();
      final snapshot = await _firestore.collection('modifierGroups').where('docId', whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] ??= doc.id;
        all.add(ModifierGroup.fromJson(data));
      }
    }

    final byId = {for (final g in all) g.docId: g};
    return groupIds.map((id) => byId[id]).whereType<ModifierGroup>().where((group) => group.isDeleted != true).toList();
  }

  /// Fetches modifier documents from Firestore by [modifierIds].
  /// Queries in chunks of 10 (whereIn limit) and returns modifiers in the same order as [modifierIds].
  @override
  Future<List<Modifier>> getModifiersByIds({required List<String> modifierIds}) async {
    final validIds = modifierIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) return [];

    final List<Modifier> all = [];
    for (var i = 0; i < validIds.length; i += _whereInLimit) {
      final chunk = validIds.skip(i).take(_whereInLimit).toList();
      final snapshot = await _firestore.collection('modifiers').where('docId', whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] ??= doc.id;
        all.add(Modifier.fromJson(data));
      }
    }

    final byId = {for (final m in all) m.docId: m};
    return modifierIds
        .map((id) => byId[id])
        .whereType<Modifier>()
        .where((modifier) => modifier.isDeleted != true)
        .toList();
  }

  /// Full customization flow (Steps 2–7): override → enabled groups → fetch groups → fetch modifiers → build bundles.
  @override
  Future<List<ModifierGroupBundle>> getCustomizationBundles({required String storeId, required Product product}) async {
    final productId = product.docId;
    if (productId == null || productId.isEmpty) return [];
    if (storeId.isEmpty) return [];

    final override = await _storeRepository.getProductOverride(productId: productId, storeId: storeId);

    final enabledGroupIds = product.modifierGroupIds
        ?.where((id) => id.isNotEmpty && !override.disabledGroupIds.contains(id))
        .toList();

    if (enabledGroupIds == null || enabledGroupIds.isEmpty) return [];

    final groups = await getModifierGroups(groupIds: enabledGroupIds);

    final allModifierIds = groups.expand((g) => g.modifierIds.where((id) => id.isNotEmpty)).toSet().toList();
    final filteredModifierIds = allModifierIds.where((id) => !override.disabledModifierIds.contains(id)).toList();

    final modifiers = await getModifiersByIds(modifierIds: filteredModifierIds);
    final modifierById = {for (final m in modifiers) m.docId: m};

    return groups
        .map(
          (g) => ModifierGroupBundle(
            group: g,
            modifiers: g.modifierIds.map((id) => modifierById[id]).whereType<Modifier>().toList(),
          ),
        )
        .toList();
  }
}
