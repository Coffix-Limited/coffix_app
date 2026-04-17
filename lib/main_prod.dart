import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:coffix_app/main_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  
  mainCommon(
    flavor: Flavor.prod,
    baseUrl: dotenv.env['API_BASE_URL'] ?? '',
    name: 'Coffix',
  );
}
