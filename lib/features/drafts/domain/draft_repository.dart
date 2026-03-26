import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';

abstract class DraftRepository {
  Future<void> createDraft({required Cart cart});
  Future<List<Draft>> getDrafts();
  Future<void> deleteDraft({required String draftId});
}
