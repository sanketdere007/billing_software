import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result object for connection diagnostics
class ConnectionTestResult {
  final bool isSuccess;
  final String message;
  final int? statusCode;

  const ConnectionTestResult({
    required this.isSuccess,
    required this.message,
    this.statusCode,
  });

  factory ConnectionTestResult.success({
    String message = 'Connected to server successfully.',
    int? statusCode,
  }) {
    return ConnectionTestResult(
      isSuccess: true,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ConnectionTestResult.failure(String message, {int? statusCode}) {
    return ConnectionTestResult(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Centralized service to manage local Server IP and dynamic API Base URL
/// configuration exclusively for Mobile platforms.
class ServerConfigService extends ChangeNotifier {
  static final ServerConfigService _instance = ServerConfigService._internal();
  factory ServerConfigService() => _instance;
  ServerConfigService._internal();

  // Storage Keys in SharedPreferences
  static const String keyServerIp = 'server_ip_address';
  static const String keyServerBaseUrl = 'server_api_base_url';

  // Default configuration
  static const int defaultPort = 3032;
  static const String fallbackIp = '192.168.1.10';
  static const String fallbackBaseUrl = 'http://192.168.1.10:3032';

  String? _currentIp;
  String? _currentBaseUrl;
  bool _isInitialized = false;

  /// Stored IP address (e.g., '192.168.1.10')
  String? get currentIp => _currentIp;

  /// Dynamically generated Base URL (e.g., 'http://192.168.1.10:3032')
  String get currentBaseUrl =>
      _currentBaseUrl ?? formatBaseUrl(_currentIp ?? fallbackIp);

  /// Whether the configuration has been initialized from local storage
  bool get isInitialized => _isInitialized;

  /// Returns true only if an IP address has been explicitly saved by the user
  bool get hasConfiguredIp =>
      _currentIp != null && _currentIp!.trim().isNotEmpty;

  /// Initialize and load saved configuration from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString(keyServerIp);
      final savedBaseUrl = prefs.getString(keyServerBaseUrl);

      if (savedIp != null && savedIp.trim().isNotEmpty) {
        _currentIp = cleanIp(savedIp);
        _currentBaseUrl = savedBaseUrl ?? formatBaseUrl(_currentIp!);
      }
      _isInitialized = true;
      notifyListeners();
      debugPrint(
        '🌐 [ServerConfigService] Initialized -> IP: "$_currentIp", BaseUrl: "$_currentBaseUrl"',
      );
    } catch (e) {
      debugPrint('⚠️ [ServerConfigService] Failed to load server config: $e');
    }
  }

  /// Sanitize input by stripping protocol (http://, https://), port, or trailing paths
  static String cleanIp(String input) {
    String ip = input.trim();
    // Remove protocol
    ip = ip.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    // Remove query params or path
    if (ip.contains('/')) {
      ip = ip.split('/').first;
    }
    // Remove port if provided
    if (ip.contains(':')) {
      ip = ip.split(':').first;
    }
    return ip.trim();
  }

  /// Validate IPv4 address format (e.g. 192.168.1.10)
  static bool isValidIp(String input) {
    final cleaned = cleanIp(input);
    if (cleaned.isEmpty) return false;

    final parts = cleaned.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      if (part.isEmpty) return false;
      final val = int.tryParse(part);
      if (val == null || val < 0 || val > 255) return false;
      // Disallow numbers with leading zeros like "01" unless it's just "0"
      if (part.length > 1 && part.startsWith('0')) return false;
    }
    return true;
  }

  /// Generate dynamic API Base URL using format: http://{ipaddress}:3032
  static String formatBaseUrl(String ipAddress) {
    final clean = cleanIp(ipAddress);
    return 'http://$clean:$defaultPort';
  }

  /// Save new IP address and generated Base URL locally in SharedPreferences
  Future<void> saveConfig(String ipAddress) async {
    final clean = cleanIp(ipAddress);
    final baseUrl = formatBaseUrl(clean);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyServerIp, clean);
    await prefs.setString(keyServerBaseUrl, baseUrl);

    _currentIp = clean;
    _currentBaseUrl = baseUrl;
    _isInitialized = true;
    notifyListeners();

    debugPrint(
      '🌐 [ServerConfigService] Saved -> IP: "$clean", BaseUrl: "$baseUrl"',
    );
  }

  /// Clear saved server IP configuration (for testing / reset)
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyServerIp);
    await prefs.remove(keyServerBaseUrl);

    _currentIp = null;
    _currentBaseUrl = null;
    notifyListeners();
  }

  /// Test connectivity to the given server IP address on port 3032
  Future<ConnectionTestResult> testConnection(
    String ipAddress, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!isValidIp(ipAddress)) {
      return ConnectionTestResult.failure(
        'Invalid IP address format. Example: 192.168.1.10',
      );
    }

    final clean = cleanIp(ipAddress);
    final baseUrl = formatBaseUrl(clean);
    final testUri = Uri.parse('$baseUrl/api/Auth/Login');

    try {
      debugPrint('🔍 [ServerConfigService] Testing connection to: $testUri');
      final response = await http
          .get(
            testUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📥 [ServerConfigService] Response: status ${response.statusCode}',
      );

      // Any HTTP response from the server (even 400, 401, 404, 405) confirms the server is reachable and listening!
      return ConnectionTestResult.success(
        message: 'Connected to server successfully (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      debugPrint('⚠️ [ServerConfigService] SocketException: $e');
      return ConnectionTestResult.failure(
        'Unable to reach server at $baseUrl.\n'
        'Please ensure your laptop and mobile device are on the same Wi-Fi network and the server is running.',
      );
    } on TimeoutException {
      debugPrint('⚠️ [ServerConfigService] TimeoutException');
      return ConnectionTestResult.failure(
        'Connection timed out while reaching $baseUrl.\n'
        'Please check that your laptop firewall allows incoming connections on port $defaultPort.',
      );
    } on HttpException catch (e) {
      debugPrint('⚠️ [ServerConfigService] HttpException: $e');
      return ConnectionTestResult.failure(
        'HTTP communication error: ${e.message}',
      );
    } catch (e) {
      debugPrint('⚠️ [ServerConfigService] Connection error: $e');
      final err = e.toString().contains('Failed host lookup')
          ? 'Network error: Host unreachable. Please check Wi-Fi connection.'
          : 'Unable to connect to server at $baseUrl.\nPlease try again.';
      return ConnectionTestResult.failure(err);
    }
  }
}

/// Global instance of [ServerConfigService]
final serverConfigService = ServerConfigService();
