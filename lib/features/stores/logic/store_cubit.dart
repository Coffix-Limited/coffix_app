import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_state.dart';
part 'store_cubit.freezed.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;
  StreamSubscription<List<Store>>? _storesSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Store> _allStores = [];

  StoreCubit({required StoreRepository storeRepository})
    : _storeRepository = storeRepository,
      super(StoreState.initial());

  void getStores() {
    emit(StoreState.loading());
    _storesSubscription?.cancel();
    _storesSubscription = _storeRepository.getStores().listen(
      (stores) {
        _allStores = stores;
        emit(StoreState.loaded(stores: stores));
      },
      onError: (e) => emit(StoreState.error(message: e.toString())),
    );
  }

  void searchStores(String query) {
    if (query.isEmpty) {
      emit(StoreState.loaded(stores: List.from(_allStores)));
      return;
    }
    final lower = query.toLowerCase();
    final filtered = _allStores.where((s) {
      final nameMatch = s.name?.toLowerCase().contains(lower) ?? false;
      final addressMatch = s.address?.toLowerCase().contains(lower) ?? false;
      return nameMatch || addressMatch;
    }).toList();
    emit(StoreState.loaded(stores: filtered));
  }

  Future<void> updatePreferredStore({required String storeId}) async {
    await _storeRepository.updatePreferredStore(storeId: storeId);
  }
}
