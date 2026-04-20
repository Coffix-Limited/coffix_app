import 'package:coffix_app/features/app/data/model/global.dart';

abstract class AppRepository {
  Stream<AppGlobal> getGlobal();
}