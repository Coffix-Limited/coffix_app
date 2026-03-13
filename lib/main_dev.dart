import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:coffix_app/main_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env.dev');
  print(dotenv.env['API_BASE_URL']);
  mainCommon(
    flavor: Flavor.dev,
    baseUrl: dotenv.env['API_BASE_URL'] ?? '',
    name: 'Coffix Dev',
  );
}
