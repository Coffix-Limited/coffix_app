import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:coffix_app/main_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env.dev');
  mainCommon(
    flavor: Flavor.dev,
    baseUrl: kDebugMode
        ? 'http://127.0.0.1:5001/coffix-app-dev/us-central1'
        : dotenv.env['API_BASE_URL'] ?? '',
    name: 'Coffix Dev',
  );
}
