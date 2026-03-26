import 'package:coffix_app/core/utils/time_utils.dart';
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
  // "-37.683, 176.1665"
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

  /// Returns how many minutes remain until closing, or null if closed/no hours.
  int? minutesUntilClose() {
    if (!isOpenAt()) return null;
    final dt = TimeUtils.now();
    final key = _weekdayKey(dt.weekday);
    final hours = openingHours?[key];
    if (hours == null || hours.close == null) return null;
    final nowMinutes = dt.hour * 60 + dt.minute;
    final closeMinutes = _parseMinutes(hours.close!);
    int diff = closeMinutes - nowMinutes;
    // Overnight shift: close is next day
    if (diff < 0) diff += 1440;
    return diff;
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Simple open check
  bool isOpenAt() {
    final dt = TimeUtils.now();
    final key = _weekdayKey(dt.weekday);
    final hours = openingHours?[key];
    if (hours == null || hours.isOpen == false) return false;
    return hours.contains(dt);
  }

  /// Returns today's closing time as a formatted string, e.g. "2:30pm".
  /// Returns null if no closing time is available.
  String? todayCloseFormatted() {
    final key = _weekdayKey(TimeUtils.now().weekday);
    final close = openingHours?[key]?.close;
    return close != null ? _formatHhmm(close) : null;
  }

  /// Returns the next open day + time, e.g. ("Mon", "8:00am").
  /// Looks up to 7 days ahead.
  ({String day, String time})? nextOpeningFormatted() {
    const dayAbbr = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final now = TimeUtils.now();
    for (int offset = 1; offset <= 7; offset++) {
      final candidate = now.add(Duration(days: offset));
      final key = _weekdayKey(candidate.weekday);
      final hours = openingHours?[key];
      if (hours != null && hours.isOpen == true && hours.open != null) {
        return (
          day: dayAbbr[candidate.weekday]!,
          time: _formatHhmm(hours.open!),
        );
      }
    }
    return null;
  }

  static String _formatHhmm(String hhmm) {
    final parts = hhmm.split(':');
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'am' : 'pm';
    if (hour == 0)
      hour = 12;
    else if (hour > 12)
      hour -= 12;
    final minStr = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return '$hour$minStr$period';
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
