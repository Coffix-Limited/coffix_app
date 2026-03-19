import 'package:dio/dio.dart';

class ApiExceptions implements Exception {
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiExceptions(this.message, {this.data, this.statusCode});

  @override
  String toString() => message;

  factory ApiExceptions.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ApiExceptions('Connection timeout with API server');
      case DioExceptionType.sendTimeout:
        return ApiExceptions('Send timeout with API server');
      case DioExceptionType.receiveTimeout:
        return ApiExceptions('Receive timeout with API server');
      case DioExceptionType.badCertificate:
        return ApiExceptions('Bad certificate');
      case DioExceptionType.badResponse:
        final statusCode = dioError.response?.statusCode;

        if (statusCode == 413) {
          return ApiExceptions("File too large for upload");
        } else if (statusCode == 502) {
          return ApiExceptions("502: Server is down. Please try again later.");
        } else if (statusCode != null &&
            statusCode >= 500 &&
            statusCode < 600) {
          return ApiExceptions(
            "Server error ($statusCode). Please try again later.",
          );
        }

        return _handleResponseError(dioError);
      case DioExceptionType.cancel:
        return ApiExceptions('Request to API server was cancelled');
      case DioExceptionType.connectionError:
        return ApiExceptions('Connection failed');
      case DioExceptionType.unknown:
        return ApiExceptions('Unknown error occurred');
    }
  }

  static ApiExceptions _handleResponseError(DioException dioError) {
    final statusCode = dioError.response?.statusCode;
    final data = dioError.response?.data;

    final response = dioError.response?.data as Map<String, dynamic>;
    final errorMessage = response["message"] ?? "";

    switch (statusCode) {
      case 400:
        return ApiExceptions('400: $errorMessage', statusCode: statusCode);
      case 401:
        return ApiExceptions('401: $errorMessage', statusCode: statusCode);
      case 403:
        return ApiExceptions('403: $errorMessage', statusCode: statusCode);
      case 404:
        return ApiExceptions('404: $errorMessage', statusCode: statusCode);
      case 409:
        return ApiExceptions('409: $errorMessage', statusCode: statusCode);
      case 422:
        final errorMessage =
            dioError.response?.data["message"] as String? ??
            "Something went wrong";

        return ApiExceptions(
          '422: $errorMessage',
          data: data,
          statusCode: statusCode,
        );
      default:
        return ApiExceptions(
          'Oops something went wrong',
          statusCode: statusCode,
        );
    }
  }
}
