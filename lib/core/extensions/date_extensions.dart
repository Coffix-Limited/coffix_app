import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String formatDate() {
    return DateFormat('dd.MM.yyyy hh:mm').format(this);
  }
}
