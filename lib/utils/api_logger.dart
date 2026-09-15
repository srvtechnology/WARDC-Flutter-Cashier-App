import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// An asynchronous, non-blocking Dio interceptor that logs API requests,
/// responses, and errors in a compact format without omitting or hiding details.
class ApiLoggerInterceptor extends Interceptor {
  ApiLoggerInterceptor({
    this.enabled = kDebugMode,
    this.logHeaders = true,
    this.logQueryParams = true,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.logErrorStackTrace = false,
    this.compactJson = true,
    this.enableColors = true,
    this.customPrinter,
  });

  /// Whether logging is enabled. Defaults to [kDebugMode].
  final bool enabled;

  /// Whether to log request/response headers.
  final bool logHeaders;

  /// Whether to log URL query parameters.
  final bool logQueryParams;

  /// Whether to log the request payload/body.
  final bool logRequestBody;

  /// Whether to log the response body.
  final bool logResponseBody;

  /// Whether to print the full stack trace on errors.
  final bool logErrorStackTrace;

  /// When true, formats JSON into a compact single line instead of multi-line.
  final bool compactJson;

  /// Whether to include ANSI color codes for terminal/console highlighting.
  final bool enableColors;

  /// Optional custom print handler. If null, safe chunked printing is used.
  final void Function(String message)? customPrinter;

  static int _requestCounter = 0;
  static const String _startTimeKey = '_api_logger_start_time';
  static const String _requestIdKey = '_api_logger_request_id';

  // ANSI color escapes
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _magenta = '\x1B[35m';
  static const String _gray = '\x1B[90m';

  String _color(String text, String colorCode) {
    if (!enableColors) return text;
    return '$colorCode$text$_reset';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final int requestId = ++_requestCounter;
    options.extra[_startTimeKey] = DateTime.now().microsecondsSinceEpoch;
    options.extra[_requestIdKey] = requestId;

    // Proceed immediately so request dispatch is never blocked by logging
    handler.next(options);

    if (enabled) {
      scheduleMicrotask(() => _logRequest(requestId, options));
    }
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final int? startTime = response.requestOptions.extra[_startTimeKey] as int?;
    final int requestId =
        (response.requestOptions.extra[_requestIdKey] as int?) ?? 0;
    final int durationMs = startTime != null
        ? ((DateTime.now().microsecondsSinceEpoch - startTime) / 1000).round()
        : -1;

    // Proceed immediately so caller gets the response without latency
    handler.next(response);

    if (enabled) {
      scheduleMicrotask(
        () => _logResponse(requestId, response, durationMs),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final int? startTime = err.requestOptions.extra[_startTimeKey] as int?;
    final int requestId =
        (err.requestOptions.extra[_requestIdKey] as int?) ?? 0;
    final int durationMs = startTime != null
        ? ((DateTime.now().microsecondsSinceEpoch - startTime) / 1000).round()
        : -1;

    // Proceed immediately so error handlers are not delayed
    handler.next(err);

    if (enabled) {
      scheduleMicrotask(() => _logError(requestId, err, durationMs));
    }
  }

  void _logRequest(int id, RequestOptions options) {
    final StringBuffer buf = StringBuffer();
    final String method = options.method.toUpperCase();
    final String uri = options.uri.toString();

    buf.writeln(
      _color('┌── 🚀 [REQ #$id] $method $uri', _cyan),
    );

    if (logHeaders && options.headers.isNotEmpty) {
      buf.writeln(
        '│ ${_color("Headers:", _gray)} ${_formatMap(options.headers)}',
      );
    }

    if (logQueryParams && options.queryParameters.isNotEmpty) {
      buf.writeln(
        '│ ${_color("Query:", _gray)} ${_formatMap(options.queryParameters)}',
      );
    }

    if (logRequestBody && options.data != null) {
      final String formattedBody = _formatData(options.data);
      buf.writeln('│ ${_color("Body:", _gray)} $formattedBody');
    }

    buf.write(_color('└──', _cyan));
    _print(buf.toString());
  }

  void _logResponse(int id, Response<dynamic> response, int durationMs) {
    final StringBuffer buf = StringBuffer();
    final int statusCode = response.statusCode ?? 0;
    final String statusMessage = response.statusMessage ?? '';
    final String method = response.requestOptions.method.toUpperCase();
    final String uri = response.requestOptions.uri.toString();

    final String statusColor = statusCode >= 200 && statusCode < 300
        ? _green
        : (statusCode >= 300 && statusCode < 400 ? _yellow : _red);

    final String durationStr = durationMs >= 0 ? ' (${durationMs}ms)' : '';

    buf.writeln(
      _color(
        '┌── 🟢 [RES #$id] $statusCode $statusMessage$durationStr ── $method $uri',
        statusColor,
      ),
    );

    if (logHeaders && response.headers.map.isNotEmpty) {
      final Map<String, dynamic> cleanHeaders = response.headers.map.map(
        (key, value) => MapEntry(key, value.length == 1 ? value.first : value),
      );
      buf.writeln('│ ${_color("Headers:", _gray)} ${_formatMap(cleanHeaders)}');
    }

    if (logResponseBody && response.data != null) {
      final String formattedBody = _formatData(response.data);
      buf.writeln('│ ${_color("Body:", _gray)} $formattedBody');
    }

    buf.write(_color('└──', statusColor));
    _print(buf.toString());
  }

  void _logError(int id, DioException err, int durationMs) {
    final StringBuffer buf = StringBuffer();
    final int? statusCode = err.response?.statusCode;
    final String statusText = statusCode != null ? '$statusCode ' : '';
    final String method = err.requestOptions.method.toUpperCase();
    final String uri = err.requestOptions.uri.toString();
    final String durationStr = durationMs >= 0 ? ' (${durationMs}ms)' : '';

    buf.writeln(
      _color(
        '┌── 🔴 [ERR #$id] $statusText${err.type.name}$durationStr ── $method $uri',
        _red,
      ),
    );

    if (err.message != null && err.message!.isNotEmpty) {
      buf.writeln('│ ${_color("Message:", _magenta)} ${err.message}');
    }

    if (err.response?.data != null) {
      final String responseBody = _formatData(err.response!.data);
      buf.writeln('│ ${_color("Error Body:", _magenta)} $responseBody');
    }

    if (logErrorStackTrace) {
      buf.writeln('│ ${_color("Stack Trace:", _gray)}\n${err.stackTrace}');
    }

    buf.write(_color('└──', _red));
    _print(buf.toString());
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';

    if (data is FormData) {
      final Map<String, dynamic> fields = {};
      for (final MapEntry<String, String> entry in data.fields) {
        fields[entry.key] = entry.value;
      }

      final List<String> filesInfo = [];
      for (final MapEntry<String, MultipartFile> entry in data.files) {
        final MultipartFile file = entry.value;
        final String size = _formatBytes(file.length);
        final String type = file.contentType?.toString() ?? 'unknown';
        filesInfo.add(
          '${entry.key}: ${file.filename ?? "unnamed"} ($size, $type)',
        );
      }

      final StringBuffer fdBuf = StringBuffer();
      fdBuf.write('FormData {');
      if (fields.isNotEmpty) {
        fdBuf.write(' fields: ${_formatMap(fields)}');
      }
      if (filesInfo.isNotEmpty) {
        if (fields.isNotEmpty) fdBuf.write(', ');
        fdBuf.write('files: [${filesInfo.join(', ')}]');
      }
      fdBuf.write(' }');
      return fdBuf.toString();
    }

    if (data is Map || data is List) {
      try {
        if (compactJson) {
          return jsonEncode(data);
        } else {
          return const JsonEncoder.withIndent('  ').convert(data);
        }
      } catch (_) {
        return data.toString();
      }
    }

    if (data is String) {
      final String trimmed = data.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          final dynamic decoded = jsonDecode(trimmed);
          if (compactJson) {
            return jsonEncode(decoded);
          } else {
            return const JsonEncoder.withIndent('  ').convert(decoded);
          }
        } catch (_) {
          return data;
        }
      }
      return data;
    }

    return data.toString();
  }

  String _formatMap(Map<dynamic, dynamic> map) {
    try {
      return jsonEncode(map);
    } catch (_) {
      return map.toString();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Print safely without truncation by chunking long lines if needed.
  /// Standard logcat cuts off logs after ~1020 bytes, so safe chunking ensures
  /// full details are visible on all devices and consoles.
  void _print(String message) {
    if (customPrinter != null) {
      customPrinter!(message);
      return;
    }

    // developer.log for DevTools network/inspector stream
    developer.log(message, name: 'API');

    // Safe chunked console print to prevent platform stdout truncation
    const int maxChunkLength = 800;
    final List<String> lines = message.split('\n');

    for (final String line in lines) {
      if (line.length <= maxChunkLength) {
        // ignore: avoid_print
        print(line);
      } else {
        int startIndex = 0;
        while (startIndex < line.length) {
          final int endIndex = (startIndex + maxChunkLength < line.length)
              ? startIndex + maxChunkLength
              : line.length;
          // ignore: avoid_print
          print(line.substring(startIndex, endIndex));
          startIndex = endIndex;
        }
      }
    }
  }
}
