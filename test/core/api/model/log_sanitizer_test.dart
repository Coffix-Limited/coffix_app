import 'package:coffix_app/core/api/model/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeHeadersForLogging', () {
    test('redacts known sensitive headers regardless of case', () {
      final headers = <String, dynamic>{
        'Authorization': 'Bearer super-secret-token',
        'COOKIE': 'session=abc123',
        'Set-Cookie': 'session=abc123; Path=/',
        'x-api-key': 'sk_live_12345',
        'API-Key': 'sk_live_67890',
        'Proxy-Authorization': 'Basic dXNlcjpwYXNz',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final result = sanitizeHeadersForLogging(headers);

      expect(result['Authorization'], redactedPlaceholder);
      expect(result['COOKIE'], redactedPlaceholder);
      expect(result['Set-Cookie'], redactedPlaceholder);
      expect(result['x-api-key'], redactedPlaceholder);
      expect(result['API-Key'], redactedPlaceholder);
      expect(result['Proxy-Authorization'], redactedPlaceholder);

      // Ordinary headers must still be visible, unmodified.
      expect(result['Content-Type'], 'application/json');
      expect(result['Accept'], 'application/json');
    });

    test('does not mutate the original headers map', () {
      final headers = <String, dynamic>{'Authorization': 'Bearer abc'};

      sanitizeHeadersForLogging(headers);

      expect(headers['Authorization'], 'Bearer abc');
    });
  });

  group('sanitizeBodyForLogging', () {
    test('redacts credential-shaped fields, case-insensitively', () {
      final body = <String, dynamic>{
        'email': 'customer@example.com',
        'password': 'hunter2',
        'idToken': 'eyJhbGciOi...',
        'accessToken': 'ya29.a0AfH6...',
        'refreshToken': '1//0gAbc...',
        'Authorization': 'Bearer abc',
        'apiKey': 'sk_live_12345',
        'secret': 'shh',
        'orderId': 'order-123',
      };

      final result = sanitizeBodyForLogging(body) as Map;

      expect(result['password'], redactedPlaceholder);
      expect(result['idToken'], redactedPlaceholder);
      expect(result['accessToken'], redactedPlaceholder);
      expect(result['refreshToken'], redactedPlaceholder);
      expect(result['Authorization'], redactedPlaceholder);
      expect(result['apiKey'], redactedPlaceholder);
      expect(result['secret'], redactedPlaceholder);

      // Ordinary fields survive untouched.
      expect(result['email'], 'customer@example.com');
      expect(result['orderId'], 'order-123');
    });

    test('recurses into nested maps and lists', () {
      final body = <String, dynamic>{
        'user': {
          'name': 'Jane',
          'credentials': {'password': 'hunter2', 'token': 'abc.def.ghi'},
        },
        'items': [
          {'sku': 'latte', 'price': 5.0},
          {'sku': 'flat-white', 'secret': 'nope'},
        ],
      };

      final result = sanitizeBodyForLogging(body) as Map;
      final user = result['user'] as Map;
      final credentials = user['credentials'] as Map;
      final items = result['items'] as List;

      expect(user['name'], 'Jane');
      expect(credentials['password'], redactedPlaceholder);
      expect(credentials['token'], redactedPlaceholder);
      expect((items[0] as Map)['price'], 5.0);
      expect((items[1] as Map)['secret'], redactedPlaceholder);
    });

    test('leaves non-map/list bodies unchanged', () {
      expect(sanitizeBodyForLogging('a plain string body'), 'a plain string body');
      expect(sanitizeBodyForLogging(null), isNull);
      expect(sanitizeBodyForLogging(42), 42);
    });

    test('does not mutate the original body map', () {
      final body = <String, dynamic>{'password': 'hunter2'};

      sanitizeBodyForLogging(body);

      expect(body['password'], 'hunter2');
    });
  });
}
