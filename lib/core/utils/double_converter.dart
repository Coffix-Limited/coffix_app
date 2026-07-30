import 'package:freezed_annotation/freezed_annotation.dart';

class DoubleConverter implements JsonConverter<double?, Object?> {
  const DoubleConverter();

  @override
  double? fromJson(Object? json) {
    if (json == null) return null;

    if (json is double) return json;
    if (json is int) return json.toDouble();
    if (json is String) return double.tryParse(json);

    return null;
  }

  @override
  Object? toJson(double? object) => object;
}
