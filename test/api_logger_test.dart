import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:western_area_rural_district_council/utils/api_logger.dart';

void main() {
  group('ApiLoggerInterceptor', () {
    test('logs request, response and error asynchronously without blocking', () async {
      final List<String> printedLogs = [];
      final logger = ApiLoggerInterceptor(
        enabled: true,
        enableColors: false,
        customPrinter: (msg) => printedLogs.add(msg),
      );

      final dio = Dio();
      dio.interceptors.add(logger);

      // 1. Test Request & Response logging
      final options = RequestOptions(
        path: '/test-endpoint',
        method: 'POST',
        baseUrl: 'https://api.example.com',
        queryParameters: {'page': 1, 'limit': 20},
        headers: {'Authorization': 'Bearer token123', 'Accept': 'application/json'},
        data: {'name': 'Freetown', 'code': 'FT01'},
      );

      bool requestHandlerCalled = false;
      // Emulate handler
      logger.onRequest(
        options,
        _MockRequestHandler(() {
          requestHandlerCalled = true;
        }),
      );
      expect(requestHandlerCalled, isTrue, reason: 'Request handler should be called immediately');

      // Wait for async microtask
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(printedLogs.isNotEmpty, isTrue);
      expect(printedLogs.first, contains('[REQ #1] POST https://api.example.com/test-endpoint?page=1&limit=20'));
      expect(printedLogs.first, contains('Headers:'));
      expect(printedLogs.first, contains('Bearer token123'));
      expect(printedLogs.first, contains('"name":"Freetown"'));

      // 2. Test Response logging
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        statusMessage: 'OK',
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
        data: {
          'status': 'success',
          'data': [
            {'id': 10, 'title': 'Council Building'}
          ]
        },
      );

      bool responseHandlerCalled = false;
      logger.onResponse(
        response,
        _MockResponseHandler(() {
          responseHandlerCalled = true;
        }),
      );
      expect(responseHandlerCalled, isTrue, reason: 'Response handler should be called immediately');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(printedLogs.length, greaterThanOrEqualTo(2));
      final responseLog = printedLogs[1];
      expect(responseLog, contains('[RES #1] 200 OK'));
      expect(responseLog, contains('Council Building'));
      expect(responseLog, contains('Headers:'));

      // 3. Test Error logging
      final dioException = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'error': 'Resource not found'},
        ),
        type: DioExceptionType.badResponse,
        message: 'Not found error',
      );

      bool errorHandlerCalled = false;
      logger.onError(
        dioException,
        _MockErrorHandler(() {
          errorHandlerCalled = true;
        }),
      );
      expect(errorHandlerCalled, isTrue, reason: 'Error handler should be called immediately');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(printedLogs.length, greaterThanOrEqualTo(3));
      final errorLog = printedLogs[2];
      expect(errorLog, contains('[ERR #1] 404 badResponse'));
      expect(errorLog, contains('Resource not found'));
    });

    test('correctly logs FormData fields and files without hiding details', () async {
      final List<String> printedLogs = [];
      final logger = ApiLoggerInterceptor(
        enabled: true,
        enableColors: false,
        customPrinter: (msg) => printedLogs.add(msg),
      );

      final formData = FormData.fromMap({
        'reason': 'Owner not available',
        'latitude': '8.4844',
      });
      formData.files.add(
        MapEntry(
          'property_image',
          MultipartFile.fromString('dummy image content', filename: 'photo.jpg'),
        ),
      );

      final options = RequestOptions(
        path: '/inaccessible-property',
        method: 'POST',
        data: formData,
      );

      logger.onRequest(options, _MockRequestHandler(() {}));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(printedLogs.isNotEmpty, isTrue);
      final log = printedLogs.first;
      expect(log, contains('FormData'));
      expect(log, contains('Owner not available'));
      expect(log, contains('photo.jpg'));
    });

    test('safe printing handles long messages without losing data', () async {
      final List<String> printedLogs = [];
      final logger = ApiLoggerInterceptor(
        enabled: true,
        enableColors: false,
        customPrinter: (msg) => printedLogs.add(msg),
      );

      // Create large payload (> 3000 chars)
      final largeMap = {
        for (int i = 0; i < 100; i++) 'key_$i': 'value_with_some_long_text_$i',
      };

      final options = RequestOptions(
        path: '/large-data',
        method: 'POST',
        data: largeMap,
      );

      logger.onRequest(options, _MockRequestHandler(() {}));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(printedLogs.isNotEmpty, isTrue);
      expect(printedLogs.first, contains('key_0'));
      expect(printedLogs.first, contains('key_99'));
    });
  });
}

class _MockRequestHandler extends RequestInterceptorHandler {
  _MockRequestHandler(this.onNext);
  final void Function() onNext;

  @override
  void next(RequestOptions requestOptions) {
    onNext();
  }
}

class _MockResponseHandler extends ResponseInterceptorHandler {
  _MockResponseHandler(this.onNext);
  final void Function() onNext;

  @override
  void next(Response<dynamic> response) {
    onNext();
  }
}

class _MockErrorHandler extends ErrorInterceptorHandler {
  _MockErrorHandler(this.onNext);
  final void Function() onNext;

  @override
  void next(DioException err) {
    onNext();
  }
}
