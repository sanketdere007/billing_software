import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart';
import '../widgets/direct_back_scope.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an option below to get in touch with our support team or find answers.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSupportCard(
                      context,
                      title: 'Call Support',
                      subtitle: 'Speak directly to our team',
                      icon: Icons.phone,
                      color: Colors.green,
                      onTap: () => _launchUrl('tel:+918411837139'),
                    ),
                    _buildSupportCard(
                      context,
                      title: 'WhatsApp Support',
                      subtitle: 'Chat with us on WhatsApp',
                      icon: Icons.message, // Fallback icon for WhatsApp
                      color: const Color(0xFF25D366),
                      onTap: () => _launchUrl('https://wa.me/918411837139'),
                    ),
                    _buildSupportCard(
                      context,
                      title: 'Email Support',
                      subtitle: 'Send us an email query',
                      icon: Icons.email,
                      color: Colors.blue,
                      onTap: () => _launchUrl('mailto:support@sankysoft.com'),
                    ),
                    _buildSupportCard(
                      context,
                      title: 'Visit Website',
                      subtitle: 'Explore our knowledge base',
                      icon: Icons.language,
                      color: Colors.indigo,
                      onTap: () => _launchUrl('https://sankysoft.netlify.app/'),
                    ),
                    _buildSupportCard(
                      context,
                      title: 'Report a Bug',
                      subtitle: 'Found an issue? Let us know',
                      icon: Icons.bug_report,
                      color: Colors.red,
                      onTap: () => _launchUrl('mailto:support@sankysoft.com?subject=Bug Report - Billing Software'),
                    ),
                    _buildSupportCard(
                      context,
                      title: 'User Guide',
                      subtitle: 'Read the documentation',
                      icon: Icons.menu_book,
                      color: Colors.orange,
                      onTap: () => _launchUrl('https://sankysoft.netlify.app/docs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 250,
                    child: AppDrawer(isPermanent: true),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Scaffold(
                      appBar: AppBar(
                        title: const Text('Help & Support'),
                      ),
                      body: content,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Help & Support'),
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: content,
            );
          }
        },
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 350),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isDark ? color.withOpacity(0.8) : color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
