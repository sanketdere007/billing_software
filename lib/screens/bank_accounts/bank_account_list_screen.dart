import 'package:flutter/material.dart';
import '../../models/bank_account.dart';
import '../../services/bank_account_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_bank_account_screen.dart';

class BankAccountListScreen extends StatefulWidget {
  const BankAccountListScreen({super.key});

  @override
  State<BankAccountListScreen> createState() => _BankAccountListScreenState();
}

class _BankAccountListScreenState extends State<BankAccountListScreen> {
  final BankAccountService _bankAccountService = BankAccountService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bankAccountService.initializeDummyData();
    _bankAccountService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _bankAccountService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<BankAccount> get _filteredBankAccounts {
    if (_searchQuery.isEmpty) {
      return _bankAccountService.bankAccounts;
    }
    return _bankAccountService.bankAccounts.where((b) {
      final query = _searchQuery.toLowerCase();
      return b.bankName.toLowerCase().contains(query) ||
             b.accountHolderName.toLowerCase().contains(query) ||
             b.accountNumber.toLowerCase().contains(query);
    }).toList();
  }

  void _navigateToAddBankAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBankAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search bank accounts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final bankAccounts = _filteredBankAccounts;
                  
                  if (bankAccounts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No bank accounts found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(bankAccounts);
                  } else {
                    return _buildListView(bankAccounts);
                  }
                },
              ),
            ),
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
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Bank Account Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Refreshing list...')),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAddBankAccount,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Bank Account'),
                          ),
                        ),
                      ],
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
              title: const Text('Bank Account Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing list...')),
                    );
                  },
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAddBankAccount,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bank Account'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAddBankAccount,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<BankAccount> bankAccounts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: bankAccounts.length,
      itemBuilder: (context, index) {
        final bankAccount = bankAccounts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                bankAccount.bankName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(
              bankAccount.bankName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('A/c: ${bankAccount.accountNumber}'),
                const SizedBox(height: 4),
                Text('Holder: ${bankAccount.accountHolderName}'),
              ],
            ),
            trailing: Chip(
              label: Text(
                bankAccount.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: bankAccount.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: bankAccount.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<BankAccount> bankAccounts) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Holder Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Account No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('IFSC', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: bankAccounts.map((bankAccount) {
                return DataRow(
                  cells: [
                    DataCell(Text(bankAccount.bankName)),
                    DataCell(Text(bankAccount.accountHolderName)),
                    DataCell(Text(bankAccount.accountNumber)),
                    DataCell(Text(bankAccount.ifscCode)),
                    DataCell(Text('₹${bankAccount.openingBalance.toStringAsFixed(2)}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bankAccount.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bankAccount.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: bankAccount.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
