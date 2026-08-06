import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/utils/stream_disposable.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/domain/draft_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_state.dart';
part 'draft_cubit.freezed.dart';

class DraftCubit extends Cubit<DraftState> implements StreamDisposable {
  final DraftRepository _draftRepository;
  StreamSubscription<List<Draft>>? _draftsSubscription;

  DraftCubit({required DraftRepository draftRepository})
    : _draftRepository = draftRepository,
      super(DraftState.initial());

  Future<void> createDraft({required Cart cart}) async {
    emit(DraftState.loading(drafts: state.drafts));
    try {
      await _draftRepository.createDraft(cart: cart);
      emit(DraftState.success(drafts: state.drafts));
    } catch (e) {
      emit(DraftState.error(message: e.toString(), drafts: state.drafts));
    }
  }

  Future<void> getDrafts() async {
    _draftsSubscription?.cancel();
    emit(DraftState.loading());
    _draftsSubscription = _draftRepository.getDrafts().listen(
      (drafts) {
        emit(DraftState.loaded(drafts: drafts));
      },
      onError: (e) {
        emit(DraftState.error(message: e.toString()));
      },
    );
  }

  Future<void> deleteDraft({required String draftId}) async {
    emit(DraftState.loading(drafts: state.drafts));
    try {
      await _draftRepository.deleteDraft(draftId: draftId);
      emit(DraftState.deleted(drafts: state.drafts));
    } catch (e) {
      emit(DraftState.error(message: e.toString(), drafts: state.drafts));
    }
  }

  @override
  void cancelSubscriptions() {
    _draftsSubscription?.cancel();
  }
}
