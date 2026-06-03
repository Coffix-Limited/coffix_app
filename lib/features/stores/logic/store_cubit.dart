import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/extensions/location_extensions.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';

part 'store_state.dart';
part 'store_cubit.freezed.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;
  StreamSubscription<List<Store>>? _storesSubscription;
  List<Store> _allStores = [];

  StoreCubit({required StoreRepository storeRepository})
    : _storeRepository = storeRepository,
      super(StoreState.initial());

  void getStores() {
    emit(StoreState.loading());
    _storesSubscription?.cancel();
    _storesSubscription = _storeRepository.getStores().listen((stores) {
      final sorted = _sortByName(stores);
      _allStores = sorted;
      emit(StoreState.loaded(stores: sorted));
    }, onError: (e) => emit(StoreState.error(message: e.toString())));
  }

  List<Store> _sortByName(List<Store> stores) {
    final sorted = List<Store>.from(stores);
    sorted.sort(
      (a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
    );
    return sorted;
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

  Future<void> sortStoresByDistance({required Position position}) async {
    final sorted = List<Store>.from(_allStores);
    sorted.sort((a, b) {
      final aDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        a.location?.latitude ?? 0,
        a.location?.longitude ?? 0,
      );
      final bDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        b.location?.latitude ?? 0,
        b.location?.longitude ?? 0,
      );
      return aDistance.compareTo(bDistance);
    });
    _allStores = sorted;
    emit(StoreState.loaded(stores: sorted));
  }
}
