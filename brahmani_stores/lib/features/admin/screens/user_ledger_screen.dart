import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ledger/providers/ledger_provider.dart';
import '../../../core/theme.dart';
import '../../../core/providers/nav_provider.dart';
import '../../home/providers/product_provider.dart';
import '../../home/models/product_model.dart';
import 'package:intl/intl.dart';

class UserLedgerScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const UserLedgerScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserLedgerScreen> createState() => _UserLedgerScreenState();
}

class _UserLedgerScreenState extends ConsumerState<UserLedgerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productProvider.notifier).fetchProducts();
    });
  }

  void _showAddTransactionSheet() async {
    ref.read(navBarVisibilityProvider.notifier).state = false;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddUserEntrySheet(userId: widget.userId, userName: widget.userName),
    );
    
    if (mounted) {
      ref.read(navBarVisibilityProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerState = ref.watch(adminUserLedgerProvider(widget.userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} નું ખાતું'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 28),
            onPressed: _showAddTransactionSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ledgerState.isLoading && ledgerState.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBalanceCard(context, ledgerState.balance),
                Expanded(
                  child: ledgerState.transactions.isEmpty
                      ? const Center(child: Text('કોઈ એન્ટ્રી નથી (No entries)'))
                      : ListView.builder(
                          itemCount: ledgerState.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = ledgerState.transactions[index];
                            final isUdhar = tx.type == 'UDHAR';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUdhar ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                child: Icon(
                                  isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isUdhar ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt)),
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
              ],
            ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    final isNegative = balance < 0; 
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Transparent glass effect
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'કુલ બાકી (Total Due)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.green : Colors.red,
            ),
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

class _AddUserEntrySheet extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  const _AddUserEntrySheet({required this.userId, required this.userName});

  @override
  ConsumerState<_AddUserEntrySheet> createState() => _AddUserEntrySheetState();
}

class _AddUserEntrySheetState extends ConsumerState<_AddUserEntrySheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  
  ProductModel? _selectedProduct;
  bool _isSubmitting = false;

  List<BillItem> _billItems = [];

  double get _grandTotal => _billItems.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateAmountFromQuantity);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
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
        _descController.text = product.name;
        _amountController.text = (product.price * qty).toString();
      }
    });
  }

  void _addItemToBill() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final description = _descController.text.trim();

    if (amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને સાચી વિગત ભરો')),
      );
      return;
    }

    setState(() {
      _billItems.add(BillItem(
        description: description,
        quantity: qty,
        subtotal: amount,
      ));
      
      // Reset inputs for next item
      _descController.clear();
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
    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને બિલમાં વસ્તુઓ ઉમેરો')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final combinedDescription = _billItems
        .map((item) => '${item.description} (x${item.quantity})')
        .join(', ');

    final success = await ref
        .read(adminUserLedgerProvider(widget.userId).notifier)
        .addTransaction(
          amount: _grandTotal,
          description: combinedDescription,
          type: type,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('બિલ સફળતાપૂર્વક ઉમેરાયું')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('બિલ ઉમેરવામાં ભૂલ થઈ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);
    
    // Bottom Sheet gets max height limit so listview can scroll
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'નવું બિલ (New Bill)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.userName,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add Item Form
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
                        controller: _descController,
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
          
          // Bill Items List
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
          
          // Grand Total
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
          
          // Action Buttons
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
