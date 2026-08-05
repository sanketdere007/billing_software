import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
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
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      if (e.osError != null && e.osError!.errorCode == 101) {
        throw ApiException('No Internet Connection');
      }
      throw ApiException(
        'Unable to connect to server.\nPlease try again later.',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } on HttpException {
      throw ApiException(
        'Unable to connect to server.\nPlease try again later.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        e.toString().contains('Failed host lookup')
            ? 'No Internet Connection'
            : 'Unable to connect to server.\nPlease try again later.',
      );
    }
  }

  /// GET request helper
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint, queryParameters: queryParameters);
    Map<String, String> headers;

    if (requiresAuth) {
      headers = await sessionService.getAuthHeaders();
    } else {
      headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    }

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConstants.timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      if (e.osError != null && e.osError!.errorCode == 101) {
        throw ApiException('No Internet Connection');
      }
      throw ApiException(
        'Unable to connect to server.\nPlease try again later.',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } on HttpException {
      throw ApiException(
        'Unable to connect to server.\nPlease try again later.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        e.toString().contains('Failed host lookup')
            ? 'No Internet Connection'
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
