import 'package:flutter/material.dart';

class InvoiceFooter extends StatelessWidget {
  const InvoiceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1.0),
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Thank you for your business!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'sankysoft.netlify.app',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              SizedBox(width: 16),
              Icon(Icons.phone, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                '+91 84118 37139',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              SizedBox(width: 16),
              Icon(Icons.email, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'support@sankysoft.com',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
