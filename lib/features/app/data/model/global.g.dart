// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppGlobal _$AppGlobalFromJson(Map<String, dynamic> json) => AppGlobal(
  GST: (json['GST'] as num?)?.toDouble(),
  appVersion: json['appVersion'] as String?,
  basicDiscount: (json['basicDiscount'] as num?)?.toDouble(),
  discountLevel2: (json['discountLevel2'] as num?)?.toDouble(),
  discountLevel3: (json['discountLevel3'] as num?)?.toDouble(),
  maxDayBetweenLogin: (json['maxDayBetweenLogin'] as num?)?.toDouble(),
  minCreditToShare: (json['minCreditToShare'] as num?)?.toDouble(),
  minTopUp: (json['minTopUp'] as num?)?.toDouble(),
  aboutUrl: json['aboutUrl'] as String?,
  specialUrl: json['specialUrl'] as String?,
  storeUrl: json['storeUrl'] as String?,
  tcUrl: json['tcUrl'] as String?,
  topupLevel2: (json['topupLevel2'] as num?)?.toDouble(),
  topupLevel3: (json['topupLevel3'] as num?)?.toDouble(),
  withdrawalFee: (json['withdrawalFee'] as num?)?.toDouble(),
  invoiceCounter: (json['invoiceCounter'] as num?)?.toInt(),
  creditExpiryDuration: (json['creditExpiryDuration'] as num?)?.toDouble(),
  referralExpiryDays: (json['referralExpiryDays'] as num?)?.toDouble(),
  scheduleOrder: json['scheduleOrder'] as bool?,
  shareCredit: json['shareCredit'] as bool?,
  withdrawBalance: json['withdrawBalance'] as bool?,
);

Map<String, dynamic> _$AppGlobalToJson(AppGlobal instance) => <String, dynamic>{
  'GST': instance.GST,
  'appVersion': instance.appVersion,
  'basicDiscount': instance.basicDiscount,
  'discountLevel2': instance.discountLevel2,
  'discountLevel3': instance.discountLevel3,
  'maxDayBetweenLogin': instance.maxDayBetweenLogin,
  'minCreditToShare': instance.minCreditToShare,
  'minTopUp': instance.minTopUp,
  'aboutUrl': instance.aboutUrl,
  'specialUrl': instance.specialUrl,
  'storeUrl': instance.storeUrl,
  'tcUrl': instance.tcUrl,
  'topupLevel2': instance.topupLevel2,
  'topupLevel3': instance.topupLevel3,
  'withdrawalFee': instance.withdrawalFee,
  'invoiceCounter': instance.invoiceCounter,
  'creditExpiryDuration': instance.creditExpiryDuration,
  'referralExpiryDays': instance.referralExpiryDays,
  'scheduleOrder': instance.scheduleOrder,
  'shareCredit': instance.shareCredit,
  'withdrawBalance': instance.withdrawBalance,
};
