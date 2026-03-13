import 'package:freezed_annotation/freezed_annotation.dart';

part 'store.g.dart';

@JsonSerializable()
class Store {
  final String? address;
  final bool? disable;
  final String docId;
  final String? gstNumber;
  final String? imageUrl;
  final String? invoiceText;
  final String? location;
  final String? name;
  final Map<String, DayHours>? openingHours;
  final String? storeCode;

  Store({
    this.address,
    this.disable,
    required this.docId,
    this.gstNumber,
    this.imageUrl,
    this.invoiceText,
    this.location,
    this.name,
    this.openingHours,
    this.storeCode,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
  Map<String, dynamic> toJson() => _$StoreToJson(this);

  // Simple open check
  bool isOpenAt() {
    final dt = DateTime.now();
    final key = _weekdayKey(dt.weekday);
    final hours = openingHours?[key];
    print(hours?.toJson());
    if (hours == null || hours.isOpen == false) return false;
    return hours.contains(dt);
  }

  static String _weekdayKey(int weekday) {
    const map = {
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };
    return map[weekday]!;
  }
}

@JsonSerializable()
class DayHours {
  final bool? isOpen;
  final String? open; // "06:30"
  final String? close; // "14:30"

  DayHours({this.isOpen, this.open, this.close});

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      _$DayHoursFromJson(json);
  Map<String, dynamic> toJson() => _$DayHoursToJson(this);

  bool contains(DateTime dt) {
    if (isOpen == false || open == null || close == null) return false;

    final nowMinutes = dt.hour * 60 + dt.minute;
    final openMinutes = _toMinutes(open!);
    final closeMinutes = _toMinutes(close!);

    if (closeMinutes > openMinutes) {
      return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
    }

    // Overnight shift support
    return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
