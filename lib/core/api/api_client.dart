import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:coffix_app/core/api/model/endpoints.dart';
import 'package:coffix_app/core/api/model/api_exceptions.dart';
import 'package:coffix_app/core/api/model/api_response.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
// import 'package:go_gym/client/model/api_interceptors.dart';

abstract class ApiClient {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  // final SharedPreferencesStorage _storage;
  final AuthRepository _authRepository = getIt<AuthRepository>();

  ApiClient({
    required Dio dio,
    // required SharedPreferencesStorage storage,
  }) : _dio = dio,
       // _storage = storage,
       super() {
    dio.options = BaseOptions(
      receiveTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
    // dio.interceptors.add(ApiInterceptors());
  }

  /// Cancel a specific request by its key
  void cancelRequest(String key) {
    log("Cancelling request: $key");
    _cancelTokens[key]?.cancel('Request cancelled');
    _cancelTokens.remove(key);
    log("Request cancelled: $key");
  }

  /// Cancel all ongoing requests
  void cancelAllRequests() {
    _cancelTokens.forEach((key, token) {
      token.cancel('All requests cancelled');
    });
    _cancelTokens.clear();
  }

  /// Get or create a cancel token for a request
  CancelToken _getCancelToken(String key) {
    if (!_cancelTokens.containsKey(key)) {
      _cancelTokens[key] = CancelToken();
    }
    return _cancelTokens[key]!;
  }

  Options options(String? token) => Options(
    headers: token == null
        ? {"Content-Type": "application/json"}
        : {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
  );

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
    String? secretKey,
    String? cancelKey,
  }) async {
    try {
      final token = secretKey ?? await _authRepository.getFirebaseToken();

      final cancelToken = cancelKey != null ? _getCancelToken(cancelKey) : null;

      final response = await _dio.get<T>(
        "${baseUrl ?? ApiEndpoints.v1}$path",
        queryParameters: queryParameters,
        options: options ?? this.options(token),
        cancelToken: cancelToken,
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromJsonT: (json) => json as T,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw ApiExceptions(
          "Request cancelled",
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw ApiExceptions("Unknown error occured", statusCode: 500);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
    String? secretKey,
    bool isJson = true,
    String? cancelKey,
  }) async {
    try {
      final token = secretKey ?? await _authRepository.getFirebaseToken();

      log("token: $token");

      final response = await _dio.post<T>(
        "${baseUrl ?? ApiEndpoints.v1}$path",
        data: isJson ? jsonEncode(data) : data,
        queryParameters: queryParameters,
        options: options ?? this.options(token),
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromJsonT: (json) => json as T,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw ApiExceptions(
          "Request cancelled",
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw ApiExceptions('Unknown error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
    String? secretKey,
    bool isJson = true,
  }) async {
    try {
      final token = secretKey ?? await _authRepository.getFirebaseToken();

      final response = await _dio.put<T>(
        "${baseUrl ?? ApiEndpoints.v1}$path",
        data: isJson ? jsonEncode(data) : data,
        queryParameters: queryParameters,
        options: options ?? this.options(token),
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromJsonT: (json) => json as T,
      );
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw ApiExceptions('Unknown error occurred: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
    String? secretKey,
  }) async {
    try {
      final token = secretKey ?? await _authRepository.getFirebaseToken();

      final response = await _dio.delete<T>(
        "${baseUrl ?? ApiEndpoints.v1}$path",
        data: data,
        queryParameters: queryParameters,
        options: options ?? this.options(token),
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromJsonT: (json) => json as T,
      );
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw ApiExceptions('Unknown error occurred');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl,
    String? secretKey,
  }) async {
    try {
      final token = secretKey ?? await _authRepository.getFirebaseToken();

      final response = await _dio.patch<T>(
        "${baseUrl ?? ApiEndpoints.v1}$path",
        data: data,
        queryParameters: queryParameters,
        options: options ?? this.options(token),
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromJsonT: (json) => json as T,
      );
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw ApiExceptions('Unknown error occurred');
    }
  }
}
