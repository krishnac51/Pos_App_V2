import 'package:get/get.dart';
import 'package:pos_v2/core/services/api_services.dart';

/// Normalizes API/network errors to short, user-friendly translated messages
/// so long exceptions (e.g. ClientException) don't flood the toast.
class ErrorMessageHelper {
  /// Extracts the server's message without exposing a decoded map in the UI.
  static String responseMessage(dynamic response, {String? fallbackKey}) {
    return _extractResponseMessage(response) ??
        (fallbackKey ?? 'unexpected_error').tr;
  }

  /// Returns a short, translated message suitable for snackbar/toast.
  /// Use this instead of showing raw exception messages.
  static String toUserMessage(dynamic error, {String? fallbackKey}) {
    final String raw = error is ApiException
        ? error.message
        : error?.toString() ?? '';

    // Preserve a message returned with an HTTP error (especially 401).
    // Only classify exceptions without an API status as network failures.
    if (error is ApiException &&
        error.statusCode != null &&
        error.message.trim().isNotEmpty) {
      return error.message.trim();
    }

    // Network/connection errors (often very long in Dart)
    if (_isNetworkError(raw)) {
      return 'network_error'.tr;
    }
    // Server/API returned an error message (keep if short and readable)
    if (error is ApiException && error.message.isNotEmpty) {
      final msg = error.message;
      if (msg.length <= 80 &&
          !msg.contains('Exception') &&
          !msg.contains('Error:')) {
        return msg;
      }
      return 'network_error'.tr;
    }
    return (fallbackKey ?? 'unexpected_error').tr;
  }

  static bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection') ||
        lower.contains('network error') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('failed host lookup') ||
        lower.contains('handshake exception') ||
        lower.contains('timeout');
  }

  static String? _extractResponseMessage(dynamic response) {
    if (response is! Map) return null;

    final message = response['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    if (message is Map) {
      final nestedMessage = _extractResponseMessage(message);
      if (nestedMessage != null) return nestedMessage;
    }

    final errors = response['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        final nestedMessage = _extractValueMessage(value);
        if (nestedMessage != null) return nestedMessage;
      }
    }

    return null;
  }

  static String? _extractValueMessage(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Iterable) {
      for (final item in value) {
        final message = _extractValueMessage(item);
        if (message != null) return message;
      }
    }
    if (value is Map) return _extractResponseMessage(value);
    return null;
  }
}
