/// Redacts credential-shaped values from HTTP headers and request/response
/// bodies before they are written to debug logs. Never mutates the input —
/// each function returns a redacted copy, so the real headers/body sent over
/// the network are unaffected.
library;

const redactedPlaceholder = '[REDACTED]';

/// Header names (case-insensitive) whose values must never be logged.
const sensitiveHeaderNames = <String>{
  'authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'api-key',
  'proxy-authorization',
};

/// Substrings (case-insensitive) that mark a body field as credential-shaped.
/// Matched with `contains`, so e.g. `refreshToken` and `access_token` both hit
/// the `token` keyword.
const sensitiveBodyKeywords = <String>{
  'password',
  'token', // also catches idToken / accessToken / refreshToken
  'authorization',
  'apikey',
  'secret',
};

/// Returns a copy of [headers] with any sensitive header value replaced by
/// [redactedPlaceholder]. Matching is case-insensitive on the header name.
/// Non-sensitive headers are returned unchanged. The original map passed in
/// is never modified.
Map<String, dynamic> sanitizeHeadersForLogging(Map<String, dynamic> headers) {
  return headers.map((key, value) {
    final isSensitive = sensitiveHeaderNames.contains(key.toLowerCase());
    return MapEntry(key, isSensitive ? redactedPlaceholder : value);
  });
}

/// Returns a redacted copy of a request/response body for logging.
///
/// Recurses into nested [Map]s and [List]s. Any map key whose lowercased name
/// contains one of [sensitiveBodyKeywords] has its value replaced with
/// [redactedPlaceholder] rather than being logged. Values that are not a
/// [Map] or [List] (a plain string, form data, raw bytes, etc.) are returned
/// unchanged, since there is no structured field to inspect. The original
/// object is never modified.
dynamic sanitizeBodyForLogging(dynamic body) {
  if (body is Map) {
    return body.map((key, value) {
      final keyStr = key.toString().toLowerCase();
      final isSensitive = sensitiveBodyKeywords.any(keyStr.contains);
      return MapEntry(
        key,
        isSensitive ? redactedPlaceholder : sanitizeBodyForLogging(value),
      );
    });
  }
  if (body is List) {
    return body.map(sanitizeBodyForLogging).toList();
  }
  return body;
}
