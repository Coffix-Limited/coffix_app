import 'package:coffix_app/core/flavors/flavor_config.dart';

class AppConstants {
  static String get databaseId => FlavorConfig.instance.flavor == Flavor.dev
      ? '(default)'
      : 'coffix-prod-australia';
  static const String kUpdateWarningDismissCount =
      'update_warning_dismiss_count';
  static const int kUpdateWarningDismissLimit = 5;
  static const String globalCollectionDocId = 'EQ0i4V6H47Ra7yMCdG7B';
  
}
