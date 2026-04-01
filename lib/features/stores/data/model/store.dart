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
  final String? location;
  final String? name;

  /// Weekly recurring hours
  final Map<String, DayHours>? openingHours;

  /// yyyy-MM-dd → HolidayHours (extends DayHours shape)
  final Map<String, DayHours>? holidayHours;

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
    this.holidayHours,
    this.storeCode,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
  Map<String, dynamic> toJson() => _$StoreToJson(this);

  /// ------------------------------
  /// PUBLIC API
  /// ------------------------------

  /// Returns how many minutes remain until closing, or null if closed.
  int? minutesUntilClose() {
    final dt = TimeUtils.now();
    final hours = _effectiveHoursFor(dt);

    if (hours == null || !hours.contains(dt) || hours.close == null) {
      return null;
    }

    final nowMinutes = dt.hour * 60 + dt.minute;
    final closeMinutes = _parseMinutes(hours.close!);

    int diff = closeMinutes - nowMinutes;

    // Overnight shift support
    if (diff < 0) diff += 1440;

    return diff;
  }

  /// Simple open check (holiday-aware)
  bool isOpenAt() {
    final dt = TimeUtils.now();
    final hours = _effectiveHoursFor(dt);

    if (hours == null || hours.isOpen == false) return false;

    return hours.contains(dt);
  }

  /// Returns today's closing time (formatted)
  String? todayCloseFormatted() {
    final hours = _effectiveHoursFor(TimeUtils.now());
    final close = hours?.close;

    return close != null ? _formatHhmm(close) : null;
  }

  /// Returns next opening day + time (holiday-aware)
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
      final hours = _effectiveHoursFor(candidate);

      if (hours != null && hours.isOpen == true && hours.open != null) {
        return (
          day: dayAbbr[candidate.weekday]!,
          time: _formatHhmm(hours.open!),
        );
      }
    }

    return null;
  }

  /// ------------------------------
  /// CORE LOGIC (HOLIDAY OVERRIDE)
  /// ------------------------------

  /// Resolves which hours apply for a given date
  /// 1. holidayHours (exact date)
  /// 2. fallback to openingHours (weekday)
  DayHours? _effectiveHoursFor(DateTime dt) {
    final holidayKey = _dateKey(dt);

    final holiday = holidayHours?[holidayKey];
    if (holiday != null) return holiday;

    final weekdayKey = _weekdayKey(dt.weekday);
    return openingHours?[weekdayKey];
  }

  /// ------------------------------
  /// HELPERS
  /// ------------------------------

  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _formatHhmm(String hhmm) {
    final parts = hhmm.split(':');
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final period = hour < 12 ? 'am' : 'pm';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

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
  final String? open; // "HH:mm"
  final String? close; // "HH:mm"

  /// Used mainly for holidays (optional UI fields)
  final String? title;
  final String? description;

  DayHours({this.isOpen, this.open, this.close, this.title, this.description});

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      _$DayHoursFromJson(json);

  Map<String, dynamic> toJson() => _$DayHoursToJson(this);

  /// Checks if a given DateTime is within this time range
  bool contains(DateTime dt) {
    if (isOpen == false || open == null || close == null) return false;

    final nowMinutes = dt.hour * 60 + dt.minute;
    final openMinutes = _toMinutes(open!);
    final closeMinutes = _toMinutes(close!);

    // Normal shift
    if (closeMinutes > openMinutes) {
      return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
    }

    // Overnight shift (e.g. 22:00 → 02:00)
    return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
