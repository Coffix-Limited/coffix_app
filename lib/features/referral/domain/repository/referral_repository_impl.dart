import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/data/repositories/referral_repository.dart';
import 'package:dio/dio.dart';

class ReferralRepositoryImpl extends ApiClient implements ReferralRepository {
  ReferralRepositoryImpl() : super(dio: Dio());

  @override
  Future<String> createReferral({
    required List<Map<String, dynamic>> recipients,
  }) async {
    final result = await post(
      '/referrals/send',
      data: {'recipients': recipients},
    );
    return result.message ?? result.data?.toString() ?? '';
  }
}
