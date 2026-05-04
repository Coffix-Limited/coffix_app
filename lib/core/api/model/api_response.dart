class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    dynamic json, {
    T Function(dynamic json)? fromJsonT,
    int? statusCode,
  }) {
    if (json is Map<String, dynamic>) {
      return ApiResponse<T>(
        success: json['success'] ?? false,
        message: json['message'],
        data: fromJsonT != null && json['data'] != null
            ? fromJsonT(json['data'])
            : json['data'],
        errors: json['errors'],
        statusCode: statusCode ?? json['status_code'],
      );
    } else {
      return ApiResponse<T>(
        success: true,
        data: fromJsonT != null ? fromJsonT(json) : json,
        statusCode: statusCode ?? json['status_code'],
      );
    }
  }
}
