import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../utils/platform_helper.dart';
import 'session_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  /// POST request helper
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? customHeaders,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint);
    Map<String, String> headers;

    if (requiresAuth) {
      headers = await sessionService.getAuthHeaders();
    } else {
      headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    try {
      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 🚀 [API POST] $uri');
      debugPrint('│ 📦 Body: ${body != null ? jsonEncode(body) : "null"}');
      debugPrint('│ 🔑 Headers: $headers');
      debugPrint('└────────────────────────────────────────────────────────');

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? ApiConstants.timeoutDuration);

      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 📥 [API POST Response] Status: ${response.statusCode} for $uri');
      debugPrint('│ 📄 Body: ${response.body}');
      debugPrint('└────────────────────────────────────────────────────────');

      return _processResponse(response);
    } catch (e) {
      throw _handleNetworkException(e);
    }
  }

  /// GET request helper
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint, queryParameters: queryParameters);
    Map<String, String> headers;

    if (requiresAuth) {
      headers = await sessionService.getAuthHeaders();
    } else {
      headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    }

    try {
      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 🔍 [API GET] $uri');
      debugPrint('│ 🏷️  Query Parameters: ${queryParameters ?? {}}');
      debugPrint('│ 🔑 Headers: $headers');
      debugPrint('└────────────────────────────────────────────────────────');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(timeout ?? ApiConstants.timeoutDuration);

      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 📥 [API GET Response] Status: ${response.statusCode} for $uri');
      debugPrint('│ 📄 Body: ${response.body}');
      debugPrint('└────────────────────────────────────────────────────────');

      return _processResponse(response);
    } catch (e) {
      throw _handleNetworkException(e);
    }
  }

  /// DELETE request helper
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint, queryParameters: queryParameters);
    Map<String, String> headers;

    if (requiresAuth) {
      headers = await sessionService.getAuthHeaders();
    } else {
      headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    }

    try {
      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 🗑️ [API DELETE] $uri');
      debugPrint('│ 🏷️  Query Parameters: ${queryParameters ?? {}}');
      debugPrint('│ 🔑 Headers: $headers');
      debugPrint('└────────────────────────────────────────────────────────');

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(timeout ?? ApiConstants.timeoutDuration);

      debugPrint('┌────────────────────────────────────────────────────────');
      debugPrint('│ 📥 [API DELETE Response] Status: ${response.statusCode} for $uri');
      debugPrint('│ 📄 Body: ${response.body}');
      debugPrint('└────────────────────────────────────────────────────────');

      return _processResponse(response);
    } catch (e) {
      throw _handleNetworkException(e);
    }
  }

  ApiException _handleNetworkException(Object e) {
    if (e is ApiException) {
      return e;
    } else if (e is SocketException) {
      if (e.osError != null && e.osError!.errorCode == 101) {
        return ApiException('No Internet Connection');
      }
      return ApiException(
        PlatformHelper.isMobile
            ? 'Unable to connect to server at ${ApiConstants.baseUrl}.\nPlease ensure the server is running and both devices are on the same Wi-Fi network.'
            : 'Unable to connect to server.\nPlease try again later.',
      );
    } else if (e is TimeoutException) {
      return ApiException(
        PlatformHelper.isMobile
            ? 'Connection to server at ${ApiConstants.baseUrl} timed out. Please check your network connection.'
            : 'Connection timed out. Please try again.',
      );
    } else if (e is FormatException) {
      return ApiException('Invalid response format from server.');
    } else if (e is HttpException) {
      return ApiException(
        PlatformHelper.isMobile
            ? 'Unable to connect to server at ${ApiConstants.baseUrl}.\nPlease try again later.'
            : 'Unable to connect to server.\nPlease try again later.',
      );
    } else {
      final str = e.toString();
      if (str.contains('Failed host lookup')) {
        return ApiException('No Internet Connection');
      }
      return ApiException(
        PlatformHelper.isMobile
            ? 'Unable to connect to server at ${ApiConstants.baseUrl}.\nPlease verify the configured IP address.'
            : 'Unable to connect to server.\nPlease try again later.',
      );
    }
  }

  /// Build URI supporting absolute or relative endpoints
  Uri _buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    String fullUrl;
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      fullUrl = endpoint;
    } else {
      final base = ApiConstants.baseUrl.endsWith('/')
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      fullUrl = '$base$path';
    }

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  /// Process HTTP Response and parse JSON
  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(response.body);
      }
    } on FormatException {
      throw ApiException('Malformed response received from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else if (response.statusCode == 400 || response.statusCode == 401) {
      String message = 'Authentication failed. Please check credentials.';
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('message')) {
        message = jsonBody['message'].toString();
      }
      throw ApiException(
        message,
        statusCode: response.statusCode,
        data: jsonBody,
      );
    } else if (response.statusCode == 403) {
      throw ApiException('Access forbidden.', statusCode: 403);
    } else if (response.statusCode == 404) {
      throw ApiException('Requested resource not found.', statusCode: 404);
    } else if (response.statusCode >= 500) {
      String message = 'Server error. Please try again later.';
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('message')) {
        message = jsonBody['message'].toString();
      }
      throw ApiException(
        message,
        statusCode: response.statusCode,
        data: jsonBody,
      );
    } else {
      throw ApiException(
        'Unexpected server response (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }
}

final apiService = ApiService();
