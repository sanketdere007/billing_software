import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/branch.dart';
import '../services/company_service.dart';
import '../services/branch_service.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../services/shortcut_service.dart';
import '../widgets/support_info_footer.dart';
import '../widgets/company_dropdown.dart';
import '../widgets/branch_dropdown.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// Dedicated screen for selecting Company & Branch context.
/// Can be used immediately after login or from Settings.
class CompanyBranchSelectionScreen extends StatefulWidget {
  final bool isChangeMode;

  const CompanyBranchSelectionScreen({
    super.key,
    this.isChangeMode = false,
  });

  @override
  State<CompanyBranchSelectionScreen> createState() =>
      _CompanyBranchSelectionScreenState();
}

class _CompanyBranchSelectionScreenState
    extends State<CompanyBranchSelectionScreen> {
  final CompanyService _companyService = companyService;
  final BranchService _branchService = branchService;

  List<CompanyListItem> _companies = [];
  List<BranchListItem> _branches = [];

  CompanyListItem? _selectedCompany;
  BranchListItem? _selectedBranch;

  bool _isLoadingCompanies = false;
  bool _isLoadingBranches = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Initial load of companies and default selection logic
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingCompanies = true;
      _errorMessage = null;
    });

    try {
      final companies = await _companyService.getAllCompanies(isActive: true);

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _isLoadingCompanies = false;
      });

      if (companies.isEmpty) {
        setState(() {
          _errorMessage =
              'No active companies found. Please contact your system administrator.';
        });
        return;
      }

      // Selection logic:
      // 1. If only 1 Company exists -> Auto-select it
      // 2. If in change mode and already has selected company -> Pre-select it
      // 3. Else wait for user
      if (companies.length == 1) {
        _onCompanyChanged(companies.first);
      } else if (widget.isChangeMode && sessionService.hasSelectedCompany) {
        final existingComp = companies.firstWhere(
          (c) => c.compId == sessionService.selectedCompId,
          orElse: () => companies.first,
        );
        _onCompanyChanged(existingComp);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCompanies = false;
        _errorMessage = 'Failed to load companies: $e';
      });
    }
  }

  /// When a company is selected (manually or automatically)
  Future<void> _onCompanyChanged(CompanyListItem? company) async {
    if (company == null) {
      setState(() {
        _selectedCompany = null;
        _selectedBranch = null;
        _branches = [];
      });
      return;
    }

    setState(() {
      _selectedCompany = company;
      _selectedBranch = null;
      _branches = [];
      _isLoadingBranches = true;
      _errorMessage = null;
    });

    try {
      final branches = await _branchService.getAllBranches(
        compId: company.compId,
        isActive: true,
      );

      if (!mounted) return;

      setState(() {
        _branches = branches;
        _isLoadingBranches = false;
      });

      // Branch selection logic:
      // 1. If only 1 Company and only 1 Branch exist in initial mode -> Auto-save & proceed directly
      // 2. If only 1 Branch exists under this company -> Auto-select it
      // 3. If in change mode and existing branch belongs to this company -> Pre-select it
      if (branches.length == 1) {
        setState(() {
          _selectedBranch = branches.first;
        });

        if (!widget.isChangeMode && _companies.length == 1) {
          // Immediately save and navigate to Dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _saveAndContinue();
            }
          });
          return;
        }
      } else if (widget.isChangeMode && sessionService.hasSelectedBranch) {
        final existingBranch = branches.where(
          (b) => b.branchId == sessionService.selectedBranchId,
        );
        if (existingBranch.isNotEmpty) {
          setState(() {
            _selectedBranch = existingBranch.first;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBranches = false;
        _errorMessage = 'Failed to load branches for ${company.compName}: $e';
      });
    }
  }

  /// Validate and save selection to persistent storage
  Future<void> _saveAndContinue() async {
    if (_isSaving) return;

    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Please select a Company to continue.'),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedBranch == null) {
      final message = _branches.isEmpty
          ? 'No active branches available for ${_selectedCompany!.compName}. Please contact administrator.'
          : 'Please select a Branch to continue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Persist both company and branch to SharedPreferences & SessionService
      await sessionService.setSelectedCompanyAndBranch(
        compId: _selectedCompany!.compId,
        compName: _selectedCompany!.compName,
        branchId: _selectedBranch!.branchId,
        branchName: _selectedBranch!.branchName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Working with: ${_selectedCompany!.compName} (${_selectedBranch!.branchName})',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.isChangeMode) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.dashboard),
            builder: (context) => const DashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save selection: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Handle Logout during initial selection
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout Confirmation'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.login),
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isChangeMode
              ? 'Change Company & Branch'
              : 'Select Company & Branch',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: !isDesktop,
        automaticallyImplyLeading: widget.isChangeMode,
        actions: [
          if (!widget.isChangeMode)
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _logout,
            ),
          IconButton(
            tooltip: 'Refresh Lists',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade50, Colors.black87]
                : [Colors.blue.shade50, Colors.white, Colors.indigo.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header Banner
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade600,
                                          Colors.indigo.shade700,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.business_center_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.isChangeMode
                                              ? 'Switch Organization'
                                              : 'Organization Context',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Select the company and branch to operate in.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),

                              // Error banner if any
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // 1. Company Selection
                              Row(
                                children: [
                                  Text(
                                    '1. Select Company',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_companies.length == 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Auto-selected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingCompanies)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                )
                              else
                                CompanyDropdown(
                                  selectedCompId: _selectedCompany?.compId,
                                  onChanged: _onCompanyChanged,
                                  isRequired: true,
                                  labelText: 'Select Company',
                                  hintText: 'Choose Company...',
                                  prefixIcon: const Icon(Icons.apartment_rounded),
                                ),

                              const SizedBox(height: 20),

                              // 2. Branch Selection
                              Row(
                                children: [
                                  Text(
                                    '2. Select Branch',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_branches.length == 1 &&
                                      _selectedBranch != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Auto-selected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingBranches)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                )
                              else
                                BranchDropdown(
                                  compId: _selectedCompany?.compId,
                                  selectedBranchId: _selectedBranch?.branchId,
                                  onChanged: (branch) {
                                    setState(() {
                                      _selectedBranch = branch;
                                    });
                                  },
                                  isRequired: true,
                                  enabled: _selectedCompany != null,
                                  labelText: 'Select Branch',
                                  hintText: _selectedCompany == null
                                      ? 'Select a company first'
                                      : 'Choose Branch...',
                                  prefixIcon: const Icon(Icons.storefront_rounded),
                                ),

                              const SizedBox(height: 24),

                              // Active Context Preview Card
                              if (_selectedCompany != null ||
                                  _selectedBranch != null)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800.withOpacity(0.6)
                                        : Colors.blue.shade50.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Context Preview',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.business_rounded,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedCompany?.compName ??
                                                  'None',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.store_rounded,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedBranch?.branchName ??
                                                  'None',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 28),

                              // Save & Continue Button
                              SizedBox(
                                height: 50,
                                child: FilledButton(
                                  onPressed: (_isLoadingCompanies ||
                                          _isLoadingBranches ||
                                          _isSaving)
                                      ? null
                                      : _saveAndContinue,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isSaving
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Saving Context...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              widget.isChangeMode
                                                  ? 'Save & Apply Changes'
                                                  : 'Save & Continue to Dashboard',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              if (widget.isChangeMode) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SupportInfoFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
