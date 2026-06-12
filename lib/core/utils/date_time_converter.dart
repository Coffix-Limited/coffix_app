import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json).toUtc();
    if (json is Map) {
      final seconds = json['_seconds'] ?? json['seconds'] as int?;
      final nanoseconds = json['_nanoseconds'] ?? json['nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + ((nanoseconds ?? 0) ~/ 1000000),
          isUtc: true,
        );
      }
    }
    throw ArgumentError('Cannot parse DateTime from $json');
  }

  @override
  dynamic toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object.toUtc());
}
