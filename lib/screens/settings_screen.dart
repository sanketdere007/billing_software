import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/branch.dart';
import '../services/company_service.dart';
import '../services/branch_service.dart';
import '../services/session_service.dart';
import '../services/shortcut_service.dart';
import '../services/theme_provider.dart';
import '../utils/platform_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/company_dropdown.dart';
import '../widgets/branch_dropdown.dart';
import '../widgets/direct_back_scope.dart';
import 'company_branch_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          Widget content = ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Company & Branch Selection Section
              const _CompanyBranchSettingsSection(),

              const SizedBox(height: 24),

              // Appearance Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListenableBuilder(
                listenable: themeProvider,
                builder: (context, _) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('Light Mode'),
                          value: ThemeMode.light,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark Mode'),
                          value: ThemeMode.dark,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Default Mode (System)'),
                          value: ThemeMode.system,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Database Backup Section
              const _DatabaseBackupSection(),
            ],
          );

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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Settings',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                backgroundColor: isDark
                    ? Colors.grey[900]
                    : Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: content,
            );
          }
        },
      ),
    );
  }
}

/// Company & Branch active context selector section
class _CompanyBranchSettingsSection extends StatefulWidget {
  const _CompanyBranchSettingsSection();

  @override
  State<_CompanyBranchSettingsSection> createState() =>
      _CompanyBranchSettingsSectionState();
}

class _CompanyBranchSettingsSectionState
    extends State<_CompanyBranchSettingsSection> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        companyService.getAllCompanies(isActive: true),
        branchService.getAllBranches(
          compId: sessionService.selectedCompId,
          isActive: true,
        ),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Companies and branches refreshed successfully.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _onCompanySelected(CompanyListItem? company) async {
    if (company == null) {
      await sessionService.clearSelectedCompanyAndBranch();
      return;
    }

    final int newCompId = company.compId;
    final String newCompName = company.compName;

    // Save selected company
    await sessionService.saveSelectedCompany(newCompId, newCompName);

    // Fetch branches for this company to verify or auto-select branch
    try {
      final branches = await branchService.getAllBranches(
        compId: newCompId,
        isActive: true,
      );

      // Check if current branch belongs to this company
      final currentBranchId = sessionService.selectedBranchId;
      final bool currentBranchBelongs = branches.any(
        (b) => b.branchId == currentBranchId,
      );

      if (!currentBranchBelongs && branches.isNotEmpty) {
        // Auto-select first branch of the new company
        final firstBranch = branches.first;
        await sessionService.saveSelectedBranch(
          firstBranch.branchId,
          firstBranch.branchName,
        );
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active Company set to: $newCompName'),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onBranchSelected(BranchListItem? branch) async {
    if (branch == null) return;

    await sessionService.saveSelectedBranch(branch.branchId, branch.branchName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active Branch set to: ${branch.branchName}'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sessionService,
      builder: (context, _) {
        final selectedCompId = sessionService.selectedCompId;
        final selectedCompName = sessionService.selectedCompName;
        final selectedBranchId = sessionService.selectedBranchId;
        final selectedBranchName = sessionService.selectedBranchName;
        final hasCompany = sessionService.hasSelectedCompany;
        final hasBranch = sessionService.hasSelectedBranch;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Company & Branch Selection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isRefreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hasCompany && hasBranch
                            ? (isDark
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.green.shade50)
                            : (isDark
                                  ? Colors.amber.withOpacity(0.12)
                                  : Colors.amber.shade50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasCompany && hasBranch
                              ? (isDark
                                    ? Colors.green.shade800
                                    : Colors.green.shade200)
                              : (isDark
                                    ? Colors.amber.shade800
                                    : Colors.amber.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasCompany && hasBranch
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 20,
                            color: hasCompany && hasBranch
                                ? Colors.green.shade700
                                : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Active Company: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            selectedCompName ?? 'None Selected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: hasCompany
                                              ? (isDark
                                                    ? Colors.lightBlueAccent
                                                    : Colors.blue.shade800)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Active Branch: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            selectedBranchName ??
                                            'None Selected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: hasBranch
                                              ? (isDark
                                                    ? Colors.tealAccent
                                                    : Colors.teal.shade800)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dropdowns Layout (Responsive Row/Column)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CompanyDropdown(
                                  selectedCompId: selectedCompId,
                                  labelText: 'Select Company',
                                  hintText: 'Choose Active Company',
                                  onChanged: _onCompanySelected,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: BranchDropdown(
                                  compId: selectedCompId,
                                  selectedBranchId: selectedBranchId,
                                  labelText: 'Select Branch',
                                  hintText: hasCompany
                                      ? 'Choose Active Branch'
                                      : 'Select Company First',
                                  enabled: hasCompany,
                                  onChanged: _onBranchSelected,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              CompanyDropdown(
                                selectedCompId: selectedCompId,
                                labelText: 'Select Company',
                                hintText: 'Choose Active Company',
                                onChanged: _onCompanySelected,
                              ),
                              const SizedBox(height: 16),
                              BranchDropdown(
                                compId: selectedCompId,
                                selectedBranchId: selectedBranchId,
                                labelText: 'Select Branch',
                                hintText: hasCompany
                                    ? 'Choose Active Branch'
                                    : 'Select Company First',
                                enabled: hasCompany,
                                onChanged: _onBranchSelected,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Database backup card
class _DatabaseBackupSection extends StatelessWidget {
  const _DatabaseBackupSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showShortcut = PlatformHelper.isWindowsDesktopEffective;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Database Backup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storage_rounded,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Database Backup',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (showShortcut)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white12
                                            : Colors.black12,
                                      ),
                                    ),
                                    child: Text(
                                      'Ctrl + Shift + B',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create an instant backup of your application database to protect your business records.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        shortcutService.triggerDatabaseBackup(context),
                    icon: const Icon(Icons.backup_rounded, size: 20),
                    label: const Text(
                      'Backup Database',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
