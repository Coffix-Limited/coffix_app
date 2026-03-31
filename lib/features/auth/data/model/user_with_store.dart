import 'package:coffix_app/features/auth/data/model/user.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_with_store.g.dart';

@JsonSerializable(explicitToJson: true)
class AppUserWithStore {
  final AppUser user;
  final Store? store;

  AppUserWithStore({required this.user, this.store});

  factory AppUserWithStore.fromJson(Map<String, dynamic> json) =>
      _$AppUserWithStoreFromJson(json);

  Map<String, dynamic> toJson() => _$AppUserWithStoreToJson(this);
}
