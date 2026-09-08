import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';

class RouteMasterScreen extends StatefulWidget {
  final RouteListItem? routeToEdit;
  final int? routeId;

  const RouteMasterScreen({super.key, this.routeToEdit, this.routeId});

  @override
  State<RouteMasterScreen> createState() => _RouteMasterScreenState();
}

class _RouteMasterScreenState extends State<RouteMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = routeService;
  final SessionService _sessionService = sessionService;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  int _currentEmpId = 0;
  int _routeId = 0;

  bool get isEditing => _routeId > 0 || widget.routeToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _saveButtonFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initUserData() async {
    try {
      final user = await _sessionService.getUserData();
      if (user?.empId != null) {
        _currentEmpId = user!.empId!;
      }
    } catch (_) {}
  }

  void _initFormData() {
    if (widget.routeToEdit != null) {
      _populateRouteFields(widget.routeToEdit!);
    } else if (widget.routeId != null && widget.routeId! > 0) {
      _fetchRouteDetails(widget.routeId!);
    } else {
      _isActive = true;
    }
  }

  Future<void> _fetchRouteDetails(int routeId) async {
    setState(() {
      _isFetchingDetails = true;
    });

    try {
      final route = _routeService.getRouteByIdFromCache(routeId);
      if (route != null && mounted) {
        _populateRouteFields(route);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Failed to load route details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _populateRouteFields(RouteListItem route) {
    _routeId = route.routeId;
    _nameController.text = route.routeName;
    _descriptionController.text = route.routeDescription;
    _isActive = route.routeIsActive;
  }

  Future<void> _saveRoute({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = RouteUpsertRequest(
        routeId: isEditing ? _routeId : 0,
        routeName: _nameController.text.trim(),
        routeDescription: _descriptionController.text.trim(),
        routeIsActive: _isActive,
        routeBranchId: (isEditing &&
                widget.routeToEdit != null &&
                widget.routeToEdit!.routeBranchId > 0)
            ? widget.routeToEdit!.routeBranchId
            : ((sessionService.selectedBranchId != null &&
                    sessionService.selectedBranchId! > 0)
                ? sessionService.selectedBranchId!
                : 1),
        routeCompId: (isEditing &&
                widget.routeToEdit != null &&
                widget.routeToEdit!.routeCompId > 0)
            ? widget.routeToEdit!.routeCompId
            : ((sessionService.selectedCompId != null &&
                    sessionService.selectedCompId! > 0)
                ? sessionService.selectedCompId!
                : 1),
        routeCreatedBy: widget.routeToEdit == null
            ? _currentEmpId
            : (widget.routeToEdit?.routeCreatedBy ?? _currentEmpId),
        routeModifiedBy: widget.routeToEdit != null ? _currentEmpId : 0,
      );

      final response = await _routeService.insertOrUpdateRoute(request);

      if (!mounted) return;

      if (!response.status) {
        if (!mounted) return;
        await showErrorDialog(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to save route.',
        );
        return;
      }

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing
              ? 'Route updated successfully!'
              : 'Route created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _descriptionController.clear();

        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _nameFocusNode.requestFocus();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        e.toString().replaceAll('ApiException: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveRoute(saveAndNew: false);
      },
      onClear: () {
        if (!isEditing) {
          _formKey.currentState?.reset();
          _nameController.clear();
          _descriptionController.clear();
          setState(() {
            _isActive = true;
          });
          _nameFocusNode.requestFocus();
        }
      },
      child: DirectBackScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            if (_isFetchingDetails) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading route details...'),
                    ],
                  ),
                ),
              );
            }

            final formContent = _buildFormCard(context, isDesktop);

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
                          title: Text(
                            isEditing ? 'Edit Route' : 'Add New Route',
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to Route List',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        body: Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.12),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 24,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 860,
                                      ),
                                      child: formContent,
                                    ),
                                  ),
                                ),
                              ),
                              _buildStickyActionBar(context, isDesktop),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile / Tablet View
            return Scaffold(
              appBar: AppBar(
                title: Text(isEditing ? 'Edit Route' : 'Add New Route'),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: formContent,
                    ),
                  ),
                  _buildStickyActionBar(context, isDesktop),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Basic Information
          _buildCardSection(
            context,
            title: 'Basic Information',
            icon: Icons.map_outlined,
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNameField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDescriptionField()),
                    ],
                  ),
                ] else ...[
                  _buildNameField(),
                  const SizedBox(height: 14),
                  _buildDescriptionField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 2: Status Switch
          Card(
            elevation: isDesktop ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isActive ? Colors.green : Colors.grey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isActive
                          ? Icons.check_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: _isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isActive
                              ? 'Active - Available'
                              : 'Inactive - Hidden',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: Colors.green,
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          if (!isEditing) ...[
            FilledButton.tonalIcon(
              onPressed: _isLoading ? null : () => _saveRoute(saveAndNew: true),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Save & Add Another'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            focusNode: _saveButtonFocusNode,
            onPressed: _isLoading ? null : () => _saveRoute(saveAndNew: false),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isLoading ? 'Saving...' : 'Save Route'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      decoration: const InputDecoration(
        labelText: 'Route Name *',
        hintText: 'Enter route name',
        prefixIcon: Icon(Icons.map),
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter route name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter route description',
        prefixIcon: Icon(Icons.description_outlined),
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveButtonFocusNode.requestFocus(),
    );
  }
}
