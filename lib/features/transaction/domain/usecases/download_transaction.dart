import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/domain/usecases/use_case.dart';
import 'package:dio/dio.dart';

class DownloadTransaction extends ApiClient implements UseCase<void, NoParams> {
  DownloadTransaction() : super(dio: Dio());

  @override
  Future<void> call(NoParams params) async {
    await get<dynamic>('/email/credit-transactions');
  }
}
