import 'package:coffix_app/core/utils/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class AppUser {
  final double? creditAvailable;
  final String? docId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? mobile;
  @DateTimeConverter()
  final DateTime? birthday;
  final String? suburb;
  final String? city;
  final String? preferredStoreId;
  @DateTimeConverter()
  final DateTime? createdAt;
  final bool? emailVerified;
  final bool? getPurchaseInfoByMail;
  final bool? getPromotions;
  final bool? allowWinACoffee;
  @DateTimeConverter()
  final DateTime? lastLogin;
  final bool? disabled;
  final String? qrId;

  AppUser({
    this.creditAvailable,
    this.docId,
    this.email,
    this.firstName,
    this.lastName,
    this.nickName,
    this.mobile,
    this.birthday,
    this.suburb,
    this.city,
    this.preferredStoreId,
    this.createdAt,
    this.emailVerified,
    this.getPurchaseInfoByMail,
    this.getPromotions,
    this.allowWinACoffee,
    this.lastLogin,
    this.disabled,
    this.qrId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);
}
