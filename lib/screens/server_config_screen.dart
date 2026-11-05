import 'package:flutter/material.dart';
import '../services/server_config_service.dart';
import 'login_screen.dart';

class ServerConfigScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ServerConfigScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ipController;
  final FocusNode _ipFocusNode = FocusNode();

  bool _isConnecting = false;
  String? _connectionError;
  String? _connectionSuccess;
  String _previewUrl = '';

  @override
  void initState() {
    super.initState();
    final initialIp = serverConfigService.currentIp ?? '';
    _ipController = TextEditingController(text: initialIp);
    _updatePreview(initialIp);

    _ipController.addListener(() {
      _updatePreview(_ipController.text);
      if (_connectionError != null || _connectionSuccess != null) {
        setState(() {
          _connectionError = null;
          _connectionSuccess = null;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ipFocusNode.requestFocus();
      }
    });
  }

  void _updatePreview(String rawInput) {
    final cleaned = ServerConfigService.cleanIp(rawInput);
    setState(() {
      if (cleaned.isNotEmpty) {
        _previewUrl = ServerConfigService.formatBaseUrl(cleaned);
      } else {
        _previewUrl = 'http://{ipaddress}:${ServerConfigService.defaultPort}';
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ipFocusNode.dispose();
    super.dispose();
  }

  /// Perform connection test and save configuration
  Future<void> _handleConnectAndSave({bool skipConnectionCheck = false}) async {
    if (_isConnecting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawInput = _ipController.text.trim();
    final cleanIp = ServerConfigService.cleanIp(rawInput);

    setState(() {
      _isConnecting = true;
      _connectionError = null;
      _connectionSuccess = null;
    });

    try {
      if (!skipConnectionCheck) {
        // Test connectivity to the API server
        final result = await serverConfigService.testConnection(cleanIp);

        if (!result.isSuccess) {
          if (!mounted) return;
          setState(() {
            _isConnecting = false;
            _connectionError = result.message;
          });
          return;
        }
      }

      // Save locally to SharedPreferences
      await serverConfigService.saveConfig(cleanIp);

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _connectionSuccess = 'Connected to ${ServerConfigService.formatBaseUrl(cleanIp)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Server IP saved: ${ServerConfigService.formatBaseUrl(cleanIp)}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to destination
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (widget.isInitialSetup) {
        // First launch: replace route with Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/login'),
            builder: (context) => const LoginScreen(),
          ),
        );
      } else {
        // From Login Screen: pop back with success
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _connectionError = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'Server Configuration' : 'Change Server IP',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: !widget.isInitialSetup,
        leading: !widget.isInitialSetup
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, false),
              )
            : null,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.white,
                    Colors.blue.shade100,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Icon & Title
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blue.shade900.withOpacity(0.3)
                                      : Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.dns_rounded,
                                  size: 40,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isInitialSetup
                                  ? 'Connect to Server'
                                  : 'Update Server IP',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your laptop or host server\'s local IP address to connect the mobile application.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // IP Address Text Field
                            TextFormField(
                              controller: _ipController,
                              focusNode: _ipFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleConnectAndSave(),
                              decoration: InputDecoration(
                                labelText: 'Laptop / Server IP Address',
                                hintText: '192.168.1.10',
                                prefixIcon: Icon(
                                  Icons.computer_rounded,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700,
                                ),
                                suffixIcon: _ipController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _ipController.clear();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade500,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the server IP address';
                                }
                                if (!ServerConfigService.isValidIp(value)) {
                                  return 'Please enter a valid IPv4 address (e.g. 192.168.1.10)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Generated Dynamic URL Preview
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.blue.shade800
                                      : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Generated API Base URL',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SelectableText(
                                          _previewUrl,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.blue.shade200
                                                : Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error Display
                            if (_connectionError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _connectionError!,
                                            style: TextStyle(
                                              color: Colors.red.shade900,
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _isConnecting
                                            ? null
                                            : () => _handleConnectAndSave(
                                                  skipConnectionCheck: true,
                                                ),
                                        icon: const Icon(
                                          Icons.save_outlined,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Save Anyway',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red.shade900,
                                          backgroundColor: Colors.red.shade100,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Success Display
                            if (_connectionSuccess != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _connectionSuccess!,
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Connect / Save Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blue.shade500,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isConnecting
                                    ? null
                                    : () => _handleConnectAndSave(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isConnecting
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Testing Connection...',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.wifi_protected_setup_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Connect / Save',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            if (!widget.isInitialSetup) ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _isConnecting
                                    ? null
                                    : () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Help Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How to find your Laptop\'s IP Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildHelpStep(
                            number: '1',
                            text:
                                'Open Command Prompt on your laptop (Win + R, type "cmd").',
                            isDark: isDark,
                          ),
                          _buildHelpStep(
                            number: '2',
                            text:
                                'Type "ipconfig" and press Enter.',
                            isDark: isDark,
                          ),
                          _buildHelpStep(
                            number: '3',
                            text:
                                'Look for "IPv4 Address" under Wi-Fi (e.g. 192.168.1.10).',
                            isDark: isDark,
                          ),
                          _buildHelpStep(
                            number: '4',
                            text:
                                'Ensure laptop and mobile are on the same Wi-Fi network.',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpStep({
    required String number,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
