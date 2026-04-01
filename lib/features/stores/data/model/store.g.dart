// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Store _$StoreFromJson(Map<String, dynamic> json) => Store(
  address: json['address'] as String?,
  disable: json['disable'] as bool?,
  docId: json['docId'] as String,
  gstNumber: json['gstNumber'] as String?,
  imageUrl: json['imageUrl'] as String?,
  invoiceText: json['invoiceText'] as String?,
  location: json['location'] as String?,
  name: json['name'] as String?,
  openingHours: (json['openingHours'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, DayHours.fromJson(e as Map<String, dynamic>)),
  ),
  holidayHours: (json['holidayHours'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, DayHours.fromJson(e as Map<String, dynamic>)),
  ),
  storeCode: json['storeCode'] as String?,
);

Map<String, dynamic> _$StoreToJson(Store instance) => <String, dynamic>{
  'address': instance.address,
  'disable': instance.disable,
  'docId': instance.docId,
  'gstNumber': instance.gstNumber,
  'imageUrl': instance.imageUrl,
  'invoiceText': instance.invoiceText,
  'location': instance.location,
  'name': instance.name,
  'openingHours': instance.openingHours,
  'holidayHours': instance.holidayHours,
  'storeCode': instance.storeCode,
};

DayHours _$DayHoursFromJson(Map<String, dynamic> json) => DayHours(
  isOpen: json['isOpen'] as bool?,
  open: json['open'] as String?,
  close: json['close'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$DayHoursToJson(DayHours instance) => <String, dynamic>{
  'isOpen': instance.isOpen,
  'open': instance.open,
  'close': instance.close,
  'title': instance.title,
  'description': instance.description,
};
