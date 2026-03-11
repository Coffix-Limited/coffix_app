class AuthExceptions implements Exception {
  final String message;
  final String code;
  AuthExceptions({required this.message, required this.code});
}
