import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billing_software/services/server_config_service.dart';
import 'package:billing_software/utils/platform_helper.dart';
import 'package:billing_software/utils/api_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlatformHelper.setOverrideForTesting(null);
    PlatformHelper.setOverrideIsMobileForTesting(null);
  });

  tearDown(() {
    PlatformHelper.setOverrideForTesting(null);
    PlatformHelper.setOverrideIsMobileForTesting(null);
  });

  group('ServerConfigService - IP Sanitization & Validation', () {
    test('cleanIp removes whitespace, schemes, ports, and trailing slashes', () {
      expect(ServerConfigService.cleanIp('192.168.1.10'), '192.168.1.10');
      expect(ServerConfigService.cleanIp('  192.168.1.10  '), '192.168.1.10');
      expect(
        ServerConfigService.cleanIp('http://192.168.1.10'),
        '192.168.1.10',
      );
      expect(
        ServerConfigService.cleanIp('https://192.168.1.10/'),
        '192.168.1.10',
      );
      expect(
        ServerConfigService.cleanIp('192.168.1.10:3032'),
        '192.168.1.10',
      );
      expect(
        ServerConfigService.cleanIp('http://192.168.1.10:3032/api/Auth'),
        '192.168.1.10',
      );
    });

    test('isValidIp validates standard IPv4 addresses', () {
      expect(ServerConfigService.isValidIp('192.168.1.10'), isTrue);
      expect(ServerConfigService.isValidIp('10.0.0.1'), isTrue);
      expect(ServerConfigService.isValidIp('127.0.0.1'), isTrue);
      expect(ServerConfigService.isValidIp('0.0.0.0'), isTrue);
      expect(ServerConfigService.isValidIp('255.255.255.255'), isTrue);
      expect(ServerConfigService.isValidIp('http://192.168.1.10:3032'), isTrue);
    });

    test('isValidIp rejects invalid IP formats and empty strings', () {
      expect(ServerConfigService.isValidIp(''), isFalse);
      expect(ServerConfigService.isValidIp('   '), isFalse);
      expect(ServerConfigService.isValidIp('192.168.1'), isFalse);
      expect(ServerConfigService.isValidIp('192.168.1.1.1'), isFalse);
      expect(ServerConfigService.isValidIp('192.168.1.256'), isFalse);
      expect(ServerConfigService.isValidIp('192.168.1.999'), isFalse);
      expect(ServerConfigService.isValidIp('abc.def.ghi.jkl'), isFalse);
      expect(ServerConfigService.isValidIp('192.168.01.1'), isFalse); // Leading zero
    });

    test('formatBaseUrl generates correct URL format http://{ip}:3032', () {
      expect(
        ServerConfigService.formatBaseUrl('192.168.1.10'),
        'http://192.168.1.10:3032',
      );
      expect(
        ServerConfigService.formatBaseUrl('10.0.2.2'),
        'http://10.0.2.2:3032',
      );
      expect(
        ServerConfigService.formatBaseUrl('http://192.168.1.50:3032'),
        'http://192.168.1.50:3032',
      );
    });
  });

  group('ServerConfigService - Persistence & Local Storage', () {
    test('saveConfig persists IP and Base URL into SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ServerConfigService();

      await service.saveConfig('192.168.1.25');

      expect(service.currentIp, '192.168.1.25');
      expect(service.currentBaseUrl, 'http://192.168.1.25:3032');
      expect(service.hasConfiguredIp, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ServerConfigService.keyServerIp), '192.168.1.25');
      expect(
        prefs.getString(ServerConfigService.keyServerBaseUrl),
        'http://192.168.1.25:3032',
      );
    });

    test('init restores previously saved IP and Base URL', () async {
      SharedPreferences.setMockInitialValues({
        ServerConfigService.keyServerIp: '192.168.1.100',
        ServerConfigService.keyServerBaseUrl: 'http://192.168.1.100:3032',
      });

      final service = ServerConfigService();
      await service.init();

      expect(service.currentIp, '192.168.1.100');
      expect(service.currentBaseUrl, 'http://192.168.1.100:3032');
      expect(service.hasConfiguredIp, isTrue);
    });
  });

  group('ApiConstants.baseUrl - Platform-Specific Routing', () {
    test('Windows Desktop uses static hostname URL (http://billingapi.local:3032)', () {
      PlatformHelper.setOverrideIsMobileForTesting(false);
      PlatformHelper.setOverrideForTesting(true); // Windows desktop

      expect(PlatformHelper.isMobile, isFalse);
      expect(PlatformHelper.isWindowsDesktop, isTrue);
      expect(ApiConstants.baseUrl, 'http://billingapi.local:3032');
    });

    test('Web / Desktop fallback uses existing URL (http://192.168.1.10:3032)', () {
      PlatformHelper.setOverrideIsMobileForTesting(false);
      PlatformHelper.setOverrideForTesting(false); // Non-windows, non-mobile (e.g. Web)

      expect(PlatformHelper.isMobile, isFalse);
      expect(PlatformHelper.isWindowsDesktop, isFalse);
      expect(ApiConstants.baseUrl, 'http://192.168.1.10:3032');
    });

    test('Mobile uses dynamically configured Server IP and Base URL', () async {
      PlatformHelper.setOverrideIsMobileForTesting(true);

      expect(PlatformHelper.isMobile, isTrue);

      // Save a custom IP
      await serverConfigService.saveConfig('192.168.1.88');

      expect(ApiConstants.baseUrl, 'http://192.168.1.88:3032');

      // Update IP (Change IP workflow)
      await serverConfigService.saveConfig('192.168.1.99');

      expect(ApiConstants.baseUrl, 'http://192.168.1.99:3032');
    });
  });
}
