// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Log _$LogFromJson(Map<String, dynamic> json) => Log(
  docId: json['docId'] as String?,
  page: json['page'] as String?,
  customerId: json['customerId'] as String?,
  category: json['category'] as String?,
  severityLevel: json['severityLevel'] as String?,
  userId: json['userId'] as String?,
  action: json['action'] as String?,
  notes: json['notes'] as String?,
  time: const DateTimeConverter().fromJson(json['time']),
);

Map<String, dynamic> _$LogToJson(Log instance) => <String, dynamic>{
  'docId': instance.docId,
  'page': instance.page,
  'customerId': instance.customerId,
  'category': instance.category,
  'severityLevel': instance.severityLevel,
  'userId': instance.userId,
  'action': instance.action,
  'notes': instance.notes,
  'time': const DateTimeConverter().toJson(instance.time),
};
