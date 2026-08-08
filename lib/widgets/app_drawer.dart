import 'package:flutter/material.dart';
import 'package:billing_software/services/auth_service.dart';
import 'package:billing_software/services/session_service.dart';
import '../services/database_backup_service.dart';
import '../widgets/database_backup_dialog.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/suppliers/supplier_list_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/categories/category_list_screen.dart';
import '../screens/subcategories/subcategory_list_screen.dart';
import '../screens/brands/brand_list_screen.dart';
import '../screens/units/unit_list_screen.dart';
import '../screens/hsn_sac/hsn_sac_list_screen.dart';
import '../screens/gst/gst_list_screen.dart';
import '../screens/companies/company_list_screen.dart';
import '../screens/cities/city_list_screen.dart';
import '../screens/areas/area_list_screen.dart';
import '../screens/branches/branch_list_screen.dart';
import '../screens/warehouses/warehouse_list_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/roles/role_list_screen.dart';
import '../screens/salespersons/salesperson_list_screen.dart';
import '../screens/bank_accounts/bank_account_list_screen.dart';
import '../screens/payment_modes/payment_mode_list_screen.dart';
import '../screens/price_lists/price_list_screen.dart';
import '../screens/expense_categories/expense_category_list_screen.dart';
import '../screens/income_categories/income_category_list_screen.dart';
import '../screens/barcode_settings/barcode_settings_list_screen.dart';
import '../screens/currencies/currency_list_screen.dart';
import '../screens/printer_settings/printer_settings_list_screen.dart';
import '../screens/terms_conditions/terms_conditions_list_screen.dart';
import '../screens/sales/sales_order/add_sales_order_screen.dart';
import '../screens/sales/sales_entry/add_sales_entry_screen.dart';
import '../screens/sales/sales_return/add_sales_return_screen.dart';
import '../screens/purchases/purchase_order/add_purchase_order_screen.dart';
import '../screens/purchases/purchase_entry/add_purchase_entry_screen.dart';
import '../screens/purchases/purchase_return/add_purchase_return_screen.dart';
import '../services/shortcut_service.dart';
import '../utils/platform_helper.dart';
import '../screens/about_screen.dart';
import '../screens/help_support_screen.dart';
import '../widgets/support_info_footer.dart';

class AppDrawer extends StatefulWidget {
  final bool isPermanent;

  const AppDrawer({super.key, this.isPermanent = false});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Static variables to maintain the expansion state across different screens
  static bool _isMasterMenuExpanded = false;
  static bool _isBusinessMastersExpanded = false;
  static bool _isOrganizationMastersExpanded = false;
  static bool _isConfigurationMastersExpanded = false;
  static bool _isSalesMenuExpanded = false;
  static bool _isPurchaseMenuExpanded = false;

  @override
  void initState() {
    super.initState();
    if (authService.currentUser == null) {
      authService.loadSessionUser();
    }
  }

  Color _getIconColor(BuildContext context, MaterialColor baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? baseColor.shade300 : baseColor.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          // App Drawer Header with Company Branding & Logged-in User Name (emp_FirstName + emp_LastName)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Background decorative elements
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main branding content with entrance animation
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Icon container with rotating animation
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: 6.2831853,
                                ), // 2*PI
                                duration: const Duration(milliseconds: 1400),
                                curve: Curves.easeInOutCubic,
                                builder: (context, rotationValue, child) {
                                  return Transform.rotate(
                                    angle: rotationValue,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.4),
                                        Colors.purple.withOpacity(0.4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_mosaic_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Texts - Active Company & Branch
                              Expanded(
                                child: ListenableBuilder(
                                  listenable: sessionService,
                                  builder: (context, _) {
                                    final compName = sessionService.selectedCompName?.trim();
                                    final branchName = sessionService.selectedBranchName?.trim();
                                    final displayCompany = (compName != null && compName.isNotEmpty)
                                        ? compName.toUpperCase()
                                        : 'COMPANY NAME';
                                    final displayBranch = (branchName != null && branchName.isNotEmpty)
                                        ? branchName
                                        : 'Billing & Management';

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            displayCompany,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.2,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withOpacity(0.5),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(
                                                16,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (branchName != null && branchName.isNotEmpty) ...[
                                                  Icon(
                                                    Icons.storefront,
                                                    size: 11,
                                                    color: Colors.teal.shade200,
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  displayBranch,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.blue.shade100,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                        fontSize: 10.5,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Logged-in User Profile Bar (emp_FirstName + emp_LastName)
                        ListenableBuilder(
                          listenable: authService,
                          builder: (context, _) {
                            final user = authService.currentUser;
                            final String displayName = () {
                              if (user != null) {
                                final first = (user.empFirstName ?? '').trim();
                                final last = (user.empLastName ?? '').trim();
                                final combined = '$first $last'.trim();
                                if (combined.isNotEmpty) return combined;
                                if (user.empUserName != null &&
                                    user.empUserName!.trim().isNotEmpty) {
                                  return user.empUserName!.trim();
                                }
                              }
                              return 'User';
                            }();

                            final String initials = () {
                              if (user != null) {
                                final first = (user.empFirstName ?? '').trim();
                                final last = (user.empLastName ?? '').trim();
                                if (first.isNotEmpty && last.isNotEmpty) {
                                  return '${first[0]}${last[0]}'.toUpperCase();
                                } else if (first.isNotEmpty) {
                                  return first[0].toUpperCase();
                                } else if (user.empUserName != null &&
                                    user.empUserName!.trim().isNotEmpty) {
                                  return user.empUserName!.trim()[0].toUpperCase();
                                }
                              }
                              return 'U';
                            }();

                            final String roleText = () {
                              if (user != null) {
                                if (user.empRole != null &&
                                    user.empRole!.trim().isNotEmpty) {
                                  return user.empRole!.trim();
                                }
                                if (user.empDesignation != null &&
                                    user.empDesignation!.trim().isNotEmpty) {
                                  return user.empDesignation!.trim();
                                }
                                if (user.empUserName != null &&
                                    user.empUserName!.trim().isNotEmpty) {
                                  return '@${user.empUserName!.trim()}';
                                }
                              }
                              return 'Active User';
                            }();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // User Avatar with Initials
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade500,
                                          Colors.indigo.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // User Name (emp_FirstName + emp_LastName) & Role
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            // Active green dot
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors
                                                    .greenAccent
                                                    .shade400,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.greenAccent
                                                        .withOpacity(0.6),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          roleText,
                                          style: TextStyle(
                                            color: Colors.blue.shade200,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  iconColor: _getIconColor(context, Colors.blue),
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: AppRoutes.dashboard,
                        ),
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                ExpansionTile(
                  initiallyExpanded: _isMasterMenuExpanded,
                  onExpansionChanged: (expanded) {
                    _isMasterMenuExpanded = expanded;
                  },
                  leading: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: _getIconColor(context, Colors.indigo),
                  ),
                  title: Text(
                    'Master Menu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: ExpansionTile(
                        initiallyExpanded: _isBusinessMastersExpanded,
                        onExpansionChanged: (expanded) {
                          _isBusinessMastersExpanded = expanded;
                        },
                        leading: Icon(
                          Icons.business_center_rounded,
                          color: _getIconColor(context, Colors.deepPurple),
                        ),
                        title: Text(
                          'Business Masters',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        children: [
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.people_alt_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Customer Master',
                            shortcutKey: 'Ctrl+C',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CustomerListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.local_shipping_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Supplier Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SupplierListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.inventory_2_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Product Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProductListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.category_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Category Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CategoryListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.subdirectory_arrow_right_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Subcategory Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SubcategoryListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.branding_watermark_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Brand Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const BrandListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.straighten_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'Unit Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UnitListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.account_balance_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'HSN/SAC Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HsnSacListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.receipt_long_rounded,
                            iconColor: _getIconColor(context, Colors.purple),
                            title: 'GST Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const GstListScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: ExpansionTile(
                        initiallyExpanded: _isOrganizationMastersExpanded,
                        onExpansionChanged: (expanded) {
                          _isOrganizationMastersExpanded = expanded;
                        },
                        leading: Icon(
                          Icons.corporate_fare_rounded,
                          color: _getIconColor(context, Colors.teal),
                        ),
                        title: Text(
                          'Organization Masters',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        children: [
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.domain_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Company Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CompanyListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.store_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Branch Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BranchListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.location_city_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'City Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CityListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.place_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Area Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AreaListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.warehouse_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Warehouse Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WarehouseListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.manage_accounts_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'User Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.security_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Role & Permission Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RoleListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.support_agent_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Salesperson Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SalespersonListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: _getIconColor(context, Colors.teal),
                            title: 'Bank Account Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BankAccountListScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: ExpansionTile(
                        initiallyExpanded: _isConfigurationMastersExpanded,
                        onExpansionChanged: (expanded) {
                          _isConfigurationMastersExpanded = expanded;
                        },
                        leading: Icon(
                          Icons.tune_rounded,
                          color: _getIconColor(context, Colors.orange),
                        ),
                        title: Text(
                          'Configuration Masters',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        children: [
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.payments_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Payment Mode Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PaymentModeListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.request_quote_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Price List Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PriceListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.money_off_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Expense Category Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ExpenseCategoryListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.attach_money_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Income Category Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const IncomeCategoryListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.currency_exchange_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Currency Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CurrencyListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.qr_code_2_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Barcode Settings',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BarcodeSettingsListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.print_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Printer Settings',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrinterSettingsListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.gavel_rounded,
                            iconColor: _getIconColor(
                              context,
                              Colors.deepOrange,
                            ),
                            title: 'Terms & Conditions Master',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsConditionsListScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ExpansionTile(
                  initiallyExpanded: _isSalesMenuExpanded,
                  onExpansionChanged: (expanded) {
                    _isSalesMenuExpanded = expanded;
                  },
                  leading: Icon(
                    Icons.point_of_sale_rounded,
                    color: _getIconColor(context, Colors.cyan),
                  ),
                  title: Text(
                    'Sales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    // _buildDrawerItem(
                    //   context: context,
                    //   icon: Icons.add_shopping_cart_rounded,
                    //   iconColor: _getIconColor(context, Colors.cyan),
                    //   title: 'Sales Order',
                    //   shortcutKey: 'F4',
                    //   onTap: () {
                    //     shortcutService.navigateToNamedScreen(
                    //       AppRoutes.salesOrderAdd,
                    //       () => const AddSalesOrderScreen(),
                    //     );
                    //   },
                    // ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.receipt_rounded,
                      iconColor: _getIconColor(context, Colors.cyan),
                      title: 'Sales Entry (Invoice)',
                      shortcutKey: 'F5',
                      onTap: () {
                        shortcutService.navigateToNamedScreen(
                          AppRoutes.salesEntryAdd,
                          () => const AddSalesEntryScreen(),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.assignment_return_rounded,
                      iconColor: _getIconColor(context, Colors.cyan),
                      title: 'Sales Return',
                      shortcutKey: 'Ctrl+F5',
                      onTap: () {
                        shortcutService.navigateToNamedScreen(
                          AppRoutes.salesReturnAdd,
                          () => const AddSalesReturnScreen(),
                        );
                      },
                    ),
                  ],
                ),

                ExpansionTile(
                  initiallyExpanded: _isPurchaseMenuExpanded,
                  onExpansionChanged: (expanded) {
                    _isPurchaseMenuExpanded = expanded;
                  },
                  leading: Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: _getIconColor(context, Colors.indigo),
                  ),
                  title: Text(
                    'Purchases',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    // _buildDrawerItem(
                    //   context: context,
                    //   icon: Icons.add_business_rounded,
                    //   iconColor: _getIconColor(context, Colors.indigo),
                    //   title: 'Purchase Order',
                    //   shortcutKey: 'F6',
                    //   onTap: () {
                    //     shortcutService.navigateToNamedScreen(
                    //       AppRoutes.purchaseOrderAdd,
                    //       () => const AddPurchaseOrderScreen(),
                    //     );
                    //   },
                    // ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      iconColor: _getIconColor(context, Colors.indigo),
                      title: 'Purchase Entry',
                      shortcutKey: 'F7',
                      onTap: () {
                        shortcutService.navigateToNamedScreen(
                          AppRoutes.purchaseEntryAdd,
                          () => const AddPurchaseEntryScreen(),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.assignment_returned_rounded,
                      iconColor: _getIconColor(context, Colors.indigo),
                      title: 'Purchase Return',
                      shortcutKey: 'Ctrl+F7',
                      onTap: () {
                        shortcutService.navigateToNamedScreen(
                          AppRoutes.purchaseReturnAdd,
                          () => const AddPurchaseReturnScreen(),
                        );
                      },
                    ),
                  ],
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  iconColor: _getIconColor(context, Colors.blueGrey),
                  title: 'Settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: AppRoutes.settings),
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_rounded,
                  iconColor: _getIconColor(context, Colors.blue),
                  title: 'About Us',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: AppRoutes.about),
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_rounded,
                  iconColor: _getIconColor(context, Colors.green),
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: AppRoutes.helpSupport,
                        ),
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          _buildDrawerItem(
            context: context,
            icon: Icons.logout_rounded,
            iconColor: _getIconColor(context, Colors.red),
            title: 'Logout',
            shortcutKey: 'Ctrl+Shift+L',
            onTap: () => shortcutService.triggerLogout(context),
          ),
          // const SupportInfoFooter(isCompact: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? shortcutKey,
  }) {
    final bool isRootItem =
        title == 'Dashboard' ||
        title == 'Settings' ||
        title == 'Logout' ||
        title == 'About Us' ||
        title == 'Help & Support';

    final bool showShortcut =
        shortcutKey != null && PlatformHelper.isWindowsDesktopEffective;

    return Padding(
      padding: EdgeInsets.only(left: isRootItem ? 0.0 : 12.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: showShortcut
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black12,
                  ),
                ),
                child: Text(
                  shortcutKey,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              )
            : null,
        onTap: () {
          // First handle drawer closing logic if it's not widget.isPermanent
          if (!widget.isPermanent) {
            Navigator.of(context).pop();
          }

          // Then execute the item's specific action
          onTap();
        },
      ),
    );
  }
}
