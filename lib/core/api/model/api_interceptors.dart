import 'package:coffix_app/core/api/model/log_sanitizer.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiInterceptors extends InterceptorsWrapper {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 120,
      colors: false,
      printEmojis: false,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i("Request: ${options.method} ${options.uri}");
    _logger.i("Headers: ${sanitizeHeadersForLogging(options.headers)}");
    _logger.i("Body: ${sanitizeBodyForLogging(options.data)}");
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      "Response: ${response.statusCode} ${response.requestOptions.uri}",
    );
    _logger.i("Data: ${sanitizeBodyForLogging(response.data)}");
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e("Error: ${err.message}", error: err);
    return handler.next(err);
  }
}
