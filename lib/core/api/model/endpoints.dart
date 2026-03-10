import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:flutter/foundation.dart';

abstract class ApiEndpoints {
  static String get endpoint => FlavorConfig.instance.baseUrl;
  static String get v1 => kDebugMode ? "$endpoint/v1" : endpoint;
}
