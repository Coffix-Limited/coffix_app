// ignore_for_file: non_constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'global.g.dart';

@JsonSerializable(explicitToJson: true)
class AppGlobal extends Equatable {
  final double? GST;
  final String? appVersion;
  final double? basicDiscount;
  final double? discountLevel2;
  final double? discountLevel3;
  final double? maxDayBetweenLogin;
  final double? minCreditToShare;
  final double? minTopUp;
  final String? aboutUrl;
  final String? specialUrl;
  final String? storeUrl;
  final String? tcUrl;
  final double? topupLevel2;
  final double? topupLevel3;
  final double? withdrawalFee;
  final int? invoiceCounter;
  final double? creditExpiryDuration;
  final double? referralExpiryDays;
  final bool? scheduleOrder;
  final bool? shareCredit;
  final bool? withdrawBalance;

  const AppGlobal({
    this.GST,
    this.appVersion,
    this.basicDiscount,
    this.discountLevel2,
    this.discountLevel3,
    this.maxDayBetweenLogin,
    this.minCreditToShare,
    this.minTopUp,
    this.aboutUrl,
    this.specialUrl,
    this.storeUrl,
    this.tcUrl,
    this.topupLevel2,
    this.topupLevel3,
    this.withdrawalFee,
    this.invoiceCounter,
    this.creditExpiryDuration,
    this.referralExpiryDays,
    this.scheduleOrder,
    this.shareCredit,
    this.withdrawBalance,
  });

  factory AppGlobal.fromJson(Map<String, dynamic> json) =>
      _$AppGlobalFromJson(json);
  Map<String, dynamic> toJson() => _$AppGlobalToJson(this);

  AppGlobal copyWith({
    double? GST,
    String? appVersion,
    double? basicDiscount,
    double? discountLevel2,
    double? discountLevel3,
    double? maxDayBetweenLogin,
    double? minCreditToShare,
    double? minTopUp,
    String? aboutUrl,
    String? specialUrl,
    String? storeUrl,
    String? tcUrl,
    double? topupLevel2,
    double? topupLevel3,
    double? withdrawalFee,
    int? invoiceCounter,
    double? creditExpiryDuration,
    double? referralExpiryDays,
    bool? scheduleOrder,
    bool? shareCredit,
    bool? withdrawBalance,
  }) => AppGlobal(
    GST: GST ?? this.GST,
    appVersion: appVersion ?? this.appVersion,
    basicDiscount: basicDiscount ?? this.basicDiscount,
    discountLevel2: discountLevel2 ?? this.discountLevel2,
    discountLevel3: discountLevel3 ?? this.discountLevel3,
    maxDayBetweenLogin: maxDayBetweenLogin ?? this.maxDayBetweenLogin,
    minCreditToShare: minCreditToShare ?? this.minCreditToShare,
    minTopUp: minTopUp ?? this.minTopUp,
    aboutUrl: aboutUrl ?? this.aboutUrl,
    specialUrl: specialUrl ?? this.specialUrl,
    storeUrl: storeUrl ?? this.storeUrl,
    tcUrl: tcUrl ?? this.tcUrl,
    topupLevel2: topupLevel2 ?? this.topupLevel2,
    topupLevel3: topupLevel3 ?? this.topupLevel3,
    withdrawalFee: withdrawalFee ?? this.withdrawalFee,
    invoiceCounter: invoiceCounter ?? this.invoiceCounter,
    creditExpiryDuration: creditExpiryDuration ?? this.creditExpiryDuration,
    referralExpiryDays: referralExpiryDays ?? this.referralExpiryDays,
    scheduleOrder: scheduleOrder ?? this.scheduleOrder,
    shareCredit: shareCredit ?? this.shareCredit,
    withdrawBalance: withdrawBalance ?? this.withdrawBalance,
  );

  @override
  List<Object?> get props => [
    GST,
    appVersion,
    basicDiscount,
    discountLevel2,
    discountLevel3,
    maxDayBetweenLogin,
    minCreditToShare,
    minTopUp,
    aboutUrl,
    specialUrl,
    storeUrl,
    tcUrl,
    topupLevel2,
    topupLevel3,
    withdrawalFee,
    invoiceCounter,
    creditExpiryDuration,
    referralExpiryDays,
    scheduleOrder,
    shareCredit,
    withdrawBalance,
  ];
}
