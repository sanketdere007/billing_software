import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'receipt_entry_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _navigateToAddReceipt() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReceiptMasterScreen(),
      ),
    ).then((_) {
      // Refresh list if needed after returning
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final content = _buildContent(context, isDesktop);

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
                      appBar: AppBar(title: const Text('Receipt List')),
                      body: content,
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Receipt List')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Action Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search receipts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _navigateToAddReceipt,
                icon: const Icon(Icons.add),
                label: const Text('Add Receipt'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List Area
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('No receipts found', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Click "Add Receipt" to create a new entry', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
