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

  /// Sorts stores grouped by city: the city containing the nearest store comes
  /// first, and within each city stores are ordered alphabetically by name.
  Future<void> sortStoresByDistance({required Position position}) async {
    // Precompute each store's distance from the user (infinity if missing /
    // unparseable so those stores sink to the bottom).
    final distanceByStore = <String, double>{};
    for (final store in _allStores) {
      distanceByStore[store.docId] = _distanceFrom(position, store);
    }

    // Per-city minimum distance ranks each city block.
    final minDistanceByCity = <String, double>{};
    for (final store in _allStores) {
      final cityKey = _cityKey(store.city);
      final distance = distanceByStore[store.docId]!;
      final current = minDistanceByCity[cityKey];
      if (current == null || distance < current) {
        minDistanceByCity[cityKey] = distance;
      }
    }

    final sorted = List<Store>.from(_allStores);
    sorted.sort((a, b) {
      final aCity = _cityKey(a.city);
      final bCity = _cityKey(b.city);

      // 1. City block ordered by its nearest store.
      final cityRank = minDistanceByCity[aCity]!.compareTo(
        minDistanceByCity[bCity]!,
      );
      if (cityRank != 0) return cityRank;

      // 2. Deterministic tie-break when two cities rank equally.
      final cityName = aCity.compareTo(bCity);
      if (cityName != 0) return cityName;

      // 3. Within the same city, alphabetically by store name.
      return (a.name ?? '').toLowerCase().compareTo(
        (b.name ?? '').toLowerCase(),
      );
    });

    _allStores = sorted;
    emit(StoreState.loaded(stores: sorted));
  }

  double _distanceFrom(Position position, Store store) {
    final location = store.location;
    if (location == null) return double.infinity;
    try {
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );
    } catch (_) {
      return double.infinity;
    }
  }

  String _cityKey(String? city) => (city ?? '').trim().toLowerCase();
}
