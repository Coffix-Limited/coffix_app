// lib/utils/time_utils.dart
import 'package:timezone/timezone.dart' as tz;

class TimeUtils {
  static  tz.TZDateTime now() {
    return tz.TZDateTime.now(tz.local);
  }
}
