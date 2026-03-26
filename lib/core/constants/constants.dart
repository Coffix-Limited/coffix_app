import 'package:coffix_app/core/flavors/flavor_config.dart';

class AppConstants {
  static String get databaseId => FlavorConfig.instance.flavor == Flavor.dev
      ? 'coffix-app-dev'
      : 'coffix-prod-australia';
  static const String kUpdateWarningDismissCount = 'update_warning_dismiss_count';
  static const int kUpdateWarningDismissLimit = 5;
}
