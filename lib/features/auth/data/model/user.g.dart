// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  creditAvailable: (json['creditAvailable'] as num?)?.toDouble(),
  docId: json['docId'] as String?,
  email: json['email'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  nickName: json['nickName'] as String?,
  mobile: json['mobile'] as String?,
  birthday: const DateTimeConverter().fromJson(json['birthday']),
  suburb: json['suburb'] as String?,
  city: json['city'] as String?,
  preferredStoreId: json['preferredStoreId'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  emailVerified: json['emailVerified'] as bool?,
  getPurchaseInfoByMail: json['getPurchaseInfoByMail'] as bool?,
  getPromotions: json['getPromotions'] as bool?,
  allowWinACoffee: json['allowWinACoffee'] as bool?,
  lastLogin: const DateTimeConverter().fromJson(json['lastLogin']),
  disabled: json['disabled'] as bool?,
  qrId: json['qrId'] as String?,
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'creditAvailable': instance.creditAvailable,
  'docId': instance.docId,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'nickName': instance.nickName,
  'mobile': instance.mobile,
  'birthday': const DateTimeConverter().toJson(instance.birthday),
  'suburb': instance.suburb,
  'city': instance.city,
  'preferredStoreId': instance.preferredStoreId,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'emailVerified': instance.emailVerified,
  'getPurchaseInfoByMail': instance.getPurchaseInfoByMail,
  'getPromotions': instance.getPromotions,
  'allowWinACoffee': instance.allowWinACoffee,
  'lastLogin': const DateTimeConverter().toJson(instance.lastLogin),
  'disabled': instance.disabled,
  'qrId': instance.qrId,
};
