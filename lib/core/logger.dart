import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _tag = 'UVProtector';

  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  static void logError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final effectiveTag = tag ?? _tag;
    final levelStr = level.name.toUpperCase().padRight(7);
    final timestamp = DateTime.now().toIso8601String();

    final buffer = StringBuffer();
    buffer.write('[$timestamp] $levelStr [$effectiveTag] $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    switch (level) {
      case LogLevel.debug:
        developer.log(buffer.toString(), name: effectiveTag, level: 500);
      case LogLevel.info:
        developer.log(buffer.toString(), name: effectiveTag, level: 800);
      case LogLevel.warning:
        developer.log(buffer.toString(), name: effectiveTag, level: 900);
      case LogLevel.error:
        developer.log(
          buffer.toString(),
          name: effectiveTag,
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  static void logServiceError(
    String serviceName,
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      'Service error in $serviceName during $operation',
      tag: 'Service',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logApiError(
    String endpoint,
    int? statusCode,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      'API error: $endpoint returned ${statusCode ?? 'unknown status'}',
      tag: 'API',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logCacheError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      'Cache error during $operation',
      tag: 'Cache',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
