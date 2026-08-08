import 'package:flutter/material.dart';
import '../../services/branch_service.dart';
import '../../services/session_service.dart';

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
  List<String> _branchOptions = ['All Branches'];

  final List<String> _dateRanges = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'This Year',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadBranches();
    sessionService.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    sessionService.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await branchService.getAllBranches(
        compId: sessionService.selectedCompId,
        isActive: true,
      );
      if (mounted) {
        setState(() {
          _branchOptions = [
            'All Branches',
            ...branches.map((b) => b.branchName).where((name) => name.isNotEmpty),
          ];

          // If session has active branch and it's in list, we can keep or adapt
          if (sessionService.selectedBranchName != null &&
              _branchOptions.contains(sessionService.selectedBranchName)) {
            _selectedBranch = sessionService.selectedBranchName!;
          } else if (!_branchOptions.contains(_selectedBranch)) {
            _selectedBranch = 'All Branches';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _branchOptions = [
            'All Branches',
            ...branchService.branches.map((b) => b.name).where((name) => name.isNotEmpty),
          ];
        });
      }
    }
  }

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
                if (val != null) {
                  setState(() => _selectedDateRange = val);
                  widget.onDateRangeChanged(val);
                }
              },
            ),
            const SizedBox(width: 16),
            _buildDropdown(
              value: _branchOptions.contains(_selectedBranch) ? _selectedBranch : 'All Branches',
              items: _branchOptions,
              icon: Icons.storefront,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedBranch = val);
                  widget.onBranchChanged(val);
                }
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
    final cleanItems = items.toSet().toList(); // Ensure unique keys

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
              value: cleanItems.contains(value) ? value : (cleanItems.isNotEmpty ? cleanItems.first : null),
              items: cleanItems.map((item) {
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
