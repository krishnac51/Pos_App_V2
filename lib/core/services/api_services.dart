import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:pos_v2/constants/app_constants.dart';

class ApiService extends GetxService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiService({required this.baseUrl, Map<String, String>? headers})
    : defaultHeaders =

          headers ??
          {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool logoutOnUnauthorized = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
      _logRequest(
        method: 'GET',
        uri: uri,
        headers: {...defaultHeaders, ...?headers},
        body: queryParameters,
      );
      final response = await http.get(
        uri,
        headers: {...defaultHeaders, ...?headers},
      );
      return _handleResponse(response, logoutOnUnauthorized);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', data: null);
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    bool logoutOnUnauthorized = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final requestHeaders = {...defaultHeaders, ...?headers};
      _logRequest(
        method: 'POST',
        uri: uri,
        headers: requestHeaders,
        body: body,
      );
      final response = await http.post(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, logoutOnUnauthorized);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error', data: null);
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, File>? files,
    bool logoutOnUnauthorized = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (headers != null) request.headers.addAll(headers);

      // Add fields
      if (fields != null) request.fields.addAll(fields);

      // Add files
      if (files != null) {
        for (var entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path),
          );
        }
      }

      _logRequest(
        method: 'POST MULTIPART',
        uri: uri,
        headers: request.headers,
        body: {'fields': fields, 'files': files?.keys.toList()},
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, logoutOnUnauthorized);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', data: null);
    }
  }

  dynamic _handleResponse(http.Response response, bool logoutOnUnauthorized) {
    _logResponse(response);

    dynamic responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      responseData = null;
    }

    if (response.statusCode == 401 && logoutOnUnauthorized) {
      AppConstants.logoutUser();

      throw ApiException(
        message: _messageFromResponse(responseData),
        data: responseData,
        statusCode: 401,
      );
    }

    if (response.statusCode == 401) {
      throw ApiException(
        message: _messageFromResponse(responseData),
        data: responseData,
        statusCode: 401,
      );
    }

    if (responseData != null) {
      return responseData;
    } else {
      throw ApiException(
        message: 'Invalid response from server',
        data: null,
        statusCode: response.statusCode,
      );
    }
  }

  String _messageFromResponse(dynamic responseData) {
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (message is Map) {
        return _messageFromResponse(message);
      }
    }
    return '';
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    dynamic body,
  }) {
    if (!kDebugMode) return;

    debugPrint('┌── API REQUEST ─────────────────────────────────────────');
    debugPrint('$method $uri');
    debugPrint('Headers: ${_stringifyForLog(headers)}');
    debugPrint('Body: ${_stringifyForLog(body)}');
    debugPrint('└────────────────────────────────────────────────────────');
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) return;

    dynamic responseBody = response.body;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      // Keep non-JSON responses as plain text for debugging.
    }

    debugPrint('┌── API RESPONSE ────────────────────────────────────────');
    debugPrint('HTTP ${response.statusCode} ${response.request?.url}');
    debugPrint('Body: ${_stringifyForLog(responseBody)}');
    debugPrint('└────────────────────────────────────────────────────────');
  }

  String _stringifyForLog(dynamic value) {
    final redactedValue = _redactForLog(value);
    if (redactedValue is String) return redactedValue;

    try {
      return jsonEncode(redactedValue);
    } catch (_) {
      return redactedValue.toString();
    }
  }

  dynamic _redactForLog(dynamic value, [String? key]) {
    if (_isSensitiveKey(key)) return '[REDACTED]';

    if (value is Map) {
      return value.map(
        (entryKey, entryValue) =>
            MapEntry(entryKey, _redactForLog(entryValue, entryKey.toString())),
      );
    }

    if (value is Iterable) {
      return value.map((item) => _redactForLog(item)).toList();
    }

    return value;
  }

  bool _isSensitiveKey(String? key) {
    if (key == null) return false;
    final normalizedKey = key.toLowerCase().replaceAll('_', '');
    return normalizedKey == 'password' ||
        normalizedKey == 'confirmpassword' ||
        normalizedKey == 'otp' ||
        normalizedKey == 'activekey' ||
        normalizedKey == 'accesscode' ||
        normalizedKey == 'authorization' ||
        normalizedKey == 'accesstoken' ||
        normalizedKey == 'refreshtoken' ||
        normalizedKey == 'token';
  }
}

// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiException({required this.message, this.data, this.statusCode});

  @override
  String toString() => message;
}
