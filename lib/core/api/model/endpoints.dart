import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:flutter/foundation.dart';

abstract class ApiEndpoints {
  static String get endpoint => FlavorConfig.instance.baseUrl;
  static String get v1 => kDebugMode
      ? "http://127.0.0.1:5001/coffix-app-dev/us-central1/v1"
      : endpoint;
}
