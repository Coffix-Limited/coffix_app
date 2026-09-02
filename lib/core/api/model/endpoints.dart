import 'package:coffix_app/core/flavors/flavor_config.dart';

abstract class ApiEndpoints {
  static String get endpoint => FlavorConfig.instance.baseUrl;

  /// Base URL for the v1 API. Sourced from FlavorConfig, which is populated
  /// from API_BASE_URL in .env.dev / .env (see main_dev.dart / main_common.dart).
  ///
  /// To point a local debug build at the Firebase emulator instead, opt in
  /// explicitly by uncommenting the line below (do not make this the default):
  // static String get v1 => "http://127.0.0.1:5001/coffix-app-dev/us-central1/v1";
  static String get v1 => endpoint;
}
