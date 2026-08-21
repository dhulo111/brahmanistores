import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/providers/nav_provider.dart';
import '../../ledger/providers/ledger_provider.dart';
import '../providers/user_management_provider.dart';
import '../../home/providers/product_provider.dart';
import '../../ledger/models/transaction_model.dart';
import '../models/admin_user_model.dart';
import '../../home/models/product_model.dart';

class AdminAllTransactionsScreen extends ConsumerStatefulWidget {
  const AdminAllTransactionsScreen({super.key});

  @override
  ConsumerState<AdminAllTransactionsScreen> createState() => _AdminAllTransactionsScreenState();
}

class _AdminAllTransactionsScreenState extends ConsumerState<AdminAllTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminAllTransactionsProvider.notifier).fetchAllTransactions();
      ref.read(userManagementProvider.notifier).fetchUsers();
      ref.read(productProvider.notifier).fetchProducts();
    });
  }

  void _showAddEntrySheet() async {
    // Hide Bottom Nav Bar when sheet opens
    ref.read(navBarVisibilityProvider.notifier).state = false;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddGlobalEntrySheet(),
    );
    
    // Show Bottom Nav Bar when sheet closes
    if (mounted) {
      ref.read(navBarVisibilityProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAllTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('બધી એન્ટ્રીઓ (All Entries)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 28),
            onPressed: _showAddEntrySheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.transactions.isEmpty
              ? const Center(child: Text('કોઈ એન્ટ્રી નથી (No entries found)'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(adminAllTransactionsProvider.notifier).fetchAllTransactions(),
                  child: ListView.builder(
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      final isUdhar = tx.type == 'UDHAR';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUdhar ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          backgroundImage: tx.userAvatar != null && tx.userAvatar!.isNotEmpty 
                              ? NetworkImage(tx.userAvatar!) 
                              : null,
                          child: tx.userAvatar == null || tx.userAvatar!.isEmpty 
                              ? Icon(
                                  isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isUdhar ? Colors.red : Colors.green,
                                )
                              : null,
                        ),
                        title: Text(tx.userName ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${tx.description}\n${DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt)}'),
                        isThreeLine: true,
                        trailing: Text(
                          '₹${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isUdhar ? Colors.red : Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddGlobalEntrySheet extends ConsumerStatefulWidget {
  const _AddGlobalEntrySheet();

  @override
  ConsumerState<_AddGlobalEntrySheet> createState() => _AddGlobalEntrySheetState();
}

class _AddGlobalEntrySheetState extends ConsumerState<_AddGlobalEntrySheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  
  AdminUser? _selectedUser;
  ProductModel? _selectedProduct;
  bool _isSubmitting = false;

  List<BillItem> _billItems = [];

  double get _grandTotal => _billItems.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userManagementProvider.notifier).fetchUsers();
      ref.read(productProvider.notifier).fetchProducts();
    });
    _qtyController.addListener(_updateAmountFromQuantity);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _updateAmountFromQuantity() {
    if (_selectedProduct != null) {
      final qty = int.tryParse(_qtyController.text) ?? 1;
      final amount = _selectedProduct!.price * qty;
      _amountController.text = amount.toString();
    }
  }

  void _showUserSearchDialog(List<AdminUser> users) async {
    final AdminUser? selected = await showDialog<AdminUser>(
      context: context,
      builder: (context) => _SearchUserDialog(users: users),
    );
    if (selected != null) {
      setState(() => _selectedUser = selected);
    }
  }

  void _showProductSearchDialog(List<ProductModel> products) async {
    final ProductModel? selected = await showDialog<ProductModel>(
      context: context,
      builder: (context) => _SearchProductDialog(products: products),
    );
    if (selected != null) {
      _onProductSelected(selected);
    }
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        final qty = int.tryParse(_qtyController.text) ?? 1;
        _descriptionController.text = product.name;
        _amountController.text = (product.price * qty).toString();
      }
    });
  }

  void _addItemToBill() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final description = _descriptionController.text.trim();

    if (amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('કૃપા કરીને સાચી વિગત ભરો')));
      return;
    }

    setState(() {
      _billItems.add(BillItem(
        description: description,
        quantity: qty,
        subtotal: amount,
      ));
      
      _descriptionController.clear();
      _amountController.clear();
      _qtyController.text = '1';
      _selectedProduct = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _billItems.removeAt(index);
    });
  }

  void _submit(String type) async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('કૃપા કરીને ગ્રાહક પસંદ કરો')));
      return;
    }

    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('કૃપા કરીને બિલમાં વસ્તુઓ ઉમેરો')));
      return;
    }

    setState(() => _isSubmitting = true);

    final combinedDescription = _billItems
        .map((item) => '${item.description} (x${item.quantity})')
        .join(', ');

    final success = await ref.read(adminAllTransactionsProvider.notifier).addTransaction(
      userId: _selectedUser!.id,
      amount: _grandTotal,
      description: combinedDescription,
      type: type,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('બિલ સફળતાપૂર્વક ઉમેરાયું!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('બિલ ઉમેરવામાં ભૂલ થઈ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(userManagementProvider);
    final productsState = ref.watch(productProvider);
    
    final approvedUsers = usersState.users.where((u) => u.status == 'APPROVED').toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'નવું બિલ (New Bill)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () => _showUserSearchDialog(approvedUsers),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'ગ્રાહક પસંદ કરો (Select User)',
                suffixIcon: Icon(Icons.search),
              ),
              child: Text(
                _selectedUser != null 
                    ? '${_selectedUser!.firstName} ${_selectedUser!.lastName} - ${_selectedUser!.phone}' 
                    : 'ગ્રાહક પસંદ કરો (અહીં ક્લિક કરો)',
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showProductSearchDialog(productsState.products.where((p) => p.isAvailable).toList()),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'પ્રોડક્ટ પસંદ કરો (Optional)',
                      suffixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      _selectedProduct != null 
                          ? '${_selectedProduct!.name} (₹${_selectedProduct!.price})' 
                          : 'પ્રોડક્ટ પસંદ કરવા અહીં ક્લિક કરો',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'વિગત (Item)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'કુલ રકમ (Subtotal)',
                          prefixText: '₹ ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _addItemToBill,
                      icon: const Icon(Icons.add),
                      label: const Text('ઉમેરો'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: _billItems.isEmpty
                ? const Center(
                    child: Text(
                      'બિલમાં કોઈ વસ્તુ નથી',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _billItems.length,
                    itemBuilder: (context, index) {
                      final item = _billItems[index];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const Divider(color: Colors.white24, height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('કુલ બિલ (Grand Total):', style: TextStyle(fontSize: 18)),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _submit('UDHAR'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'ઉધાર બિલ સેવ કરો',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _submit('JAMA'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'જમા બિલ સેવ કરો',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class BillItem {
  final String description;
  final int quantity;
  final double subtotal;

  BillItem({
    required this.description,
    required this.quantity,
    required this.subtotal,
  });
}

class _SearchUserDialog extends StatefulWidget {
  final List<AdminUser> users;
  const _SearchUserDialog({required this.users});
  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users.where((u) {
      final query = _searchQuery.toLowerCase();
      final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
      final phone = u.phone.toLowerCase();
      return fullName.contains(query) || phone.contains(query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'ગ્રાહકનું નામ અથવા નંબર લખો...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('કોઈ ગ્રાહક મળ્યા નથી'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final u = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                                backgroundImage: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                    ? NetworkImage(u.avatarUrl!)
                                    : null,
                                child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                                    ? Text(u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?')
                                    : null,
                              ),
                              title: Text('${u.firstName} ${u.lastName}'),
                              subtitle: Text(u.phone),
                              onTap: () => Navigator.pop(context, u),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchProductDialog extends StatefulWidget {
  final List<ProductModel> products;
  const _SearchProductDialog({required this.products});
  @override
  State<_SearchProductDialog> createState() => _SearchProductDialogState();
}

class _SearchProductDialogState extends State<_SearchProductDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      final query = _searchQuery.toLowerCase();
      final name = p.name.toLowerCase();
      final englishName = (p.englishName ?? '').toLowerCase();
      return name.contains(query) || englishName.contains(query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'પ્રોડક્ટનું નામ (Gujarati or English) લખો...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('કોઈ પ્રોડક્ટ મળી નથી'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white10,
                                child: const Icon(Icons.shopping_bag, color: AppTheme.primaryGreen),
                              ),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: p.englishName != null && p.englishName!.isNotEmpty
                                  ? Text(p.englishName!)
                                  : null,
                              trailing: Text(
                                '₹${p.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16),
                              ),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

