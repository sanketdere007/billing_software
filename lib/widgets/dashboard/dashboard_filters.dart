import 'package:flutter/material.dart';

class DashboardFilters extends StatefulWidget {
  final Function(String) onDateRangeChanged;
  final Function(String) onBranchChanged;

  const DashboardFilters({
    super.key,
    required this.onDateRangeChanged,
    required this.onBranchChanged,
  });

  @override
  State<DashboardFilters> createState() => _DashboardFiltersState();
}

class _DashboardFiltersState extends State<DashboardFilters> {
  String _selectedDateRange = 'Today';
  String _selectedBranch = 'All Branches';

  final List<String> _dateRanges = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'This Year',
    'Custom',
  ];

  final List<String> _branches = [
    'All Branches',
    'Main Branch',
    'North Branch',
    'South Branch',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdown(
              value: _selectedDateRange,
              items: _dateRanges,
              icon: Icons.calendar_today,
              onChanged: (val) {
                setState(() => _selectedDateRange = val!);
                widget.onDateRangeChanged(val!);
              },
            ),
            const SizedBox(width: 16),
            _buildDropdown(
              value: _selectedBranch,
              items: _branches,
              icon: Icons.storefront,
              onChanged: (val) {
                setState(() => _selectedBranch = val!);
                widget.onBranchChanged(val!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
