import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportInfoFooter extends StatelessWidget {
  final bool isCompact;

  const SupportInfoFooter({super.key, this.isCompact = false});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final iconColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _launchUrl('https://www.sankysoft.in'),
              child: Row(
                children: [
                  Icon(Icons.language, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    'www.sankysoft.in',
                    style: TextStyle(color: iconColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl('tel:+918411837139'),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    '+91 84118 37139',
                    style: TextStyle(color: iconColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoItem(
                  icon: Icons.language,
                  text: 'www.sankysoft.in',
                  color: iconColor,
                  onTap: () => _launchUrl('https://www.sankysoft.in'),
                ),
                const SizedBox(width: 24.0),
                _buildInfoItem(
                  icon: Icons.phone,
                  text: '+91 84118 37139',
                  color: iconColor,
                  onTap: () => _launchUrl('tel:+918411837139'),
                ),
                const SizedBox(width: 24.0),
                _buildInfoItem(
                  icon: Icons.email,
                  text: 'sankysoft@gmail.com',
                  color: iconColor,
                  onTap: () => _launchUrl('mailto:sankysoft@gmail.com'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Text(
            '© 2026 SankySoft Solutions. All Rights Reserved.',
            style: TextStyle(color: textColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
