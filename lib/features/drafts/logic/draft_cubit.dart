import 'package:bloc/bloc.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_state.dart';
part 'draft_cubit.freezed.dart';

class DraftCubit extends Cubit<DraftState> {
  final DraftRepository _draftRepository;
  DraftCubit({required DraftRepository draftRepository})
    : _draftRepository = draftRepository,
      super(DraftState.initial());

  Future<void> createDraft({required Cart cart}) async {
    emit(DraftState.loading(drafts: state.drafts));
    try {
      await _draftRepository.createDraft(cart: cart);
      await getDrafts();
    } catch (e) {
      emit(DraftState.error(message: e.toString(), drafts: state.drafts));
    }
  }

  Future<void> getDrafts() async {
    emit(DraftState.loading());
    try {
      final drafts = await _draftRepository.getDrafts();
      emit(DraftState.loaded(drafts: drafts));
    } catch (e) {
      emit(DraftState.error(message: e.toString()));
    }
  }

  Future<void> deleteDraft({required String draftId}) async {
    try {
      await _draftRepository.deleteDraft(draftId: draftId);
      await getDrafts();
    } catch (e) {
      emit(DraftState.error(message: e.toString()));
    }
  }
}
