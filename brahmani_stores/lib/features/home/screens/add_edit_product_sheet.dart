import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class AddEditProductSheet extends ConsumerStatefulWidget {
  final ProductModel? product;
  const AddEditProductSheet({super.key, this.product});

  @override
  ConsumerState<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends ConsumerState<AddEditProductSheet> {
  late TextEditingController _nameController;
  late TextEditingController _englishNameController;
  late TextEditingController _priceController;
  late bool _isAvailable;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _englishNameController = TextEditingController(text: widget.product?.englishName ?? '');
    _priceController = TextEditingController(
        text: widget.product != null ? widget.product!.price.toString() : '');
    _isAvailable = widget.product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _englishNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _convertToEnglishNumbers(String input) {
    const gujaratiToEnglish = {
      '૦': '0', '૧': '1', '૨': '2', '૩': '3', '૪': '4',
      '૫': '5', '૬': '6', '૭': '7', '૮': '8', '૯': '9',
    };
    String result = input;
    gujaratiToEnglish.forEach((guj, eng) {
      result = result.replaceAll(guj, eng);
    });
    return result;
  }

  void _save() async {
    final name = _nameController.text.trim();
    final englishName = _englishNameController.text.trim();
    String priceStr = _priceController.text.trim();
    priceStr = _convertToEnglishNumbers(priceStr);

    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('કૃપા કરીને બધી વિગતો ભરો (Please fill all details)')));
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('યોગ્ય ભાવ દાખલ કરો (Enter a valid price)')));
      return;
    }

    setState(() => _isSaving = true);
    
    final data = {
      'name': name,
      'englishName': englishName,
      'price': price,
      'isAvailable': _isAvailable,
    };

    bool success;
    if (widget.product == null) {
      success = await ref.read(productProvider.notifier).addProduct(data);
    } else {
      success = await ref.read(productProvider.notifier).updateProduct(widget.product!.id, data);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product == null ? 'પ્રોડક્ટ ઉમેરાઈ (Added)' : 'પ્રોડક્ટ અપડેટ થઈ (Updated)')));
    }
  }

  void _delete() async {
    if (widget.product == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('ખાતરી કરો (Confirm)'),
        content: const Text('શું તમે ખરેખર આ પ્રોડક્ટ ડિલીટ કરવા માંગો છો? (Are you sure?)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ના (No)', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('હા, ડિલીટ કરો (Yes)', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final success = await ref.read(productProvider.notifier).deleteProduct(widget.product!.id);
      setState(() => _isSaving = false);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('પ્રોડક્ટ ડિલીટ થઈ (Deleted)')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'પ્રોડક્ટ એડિટ કરો' : 'નવી પ્રોડક્ટ ઉમેરો',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'પ્રોડક્ટનું નામ (Gujarati Name)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _englishNameController,
              decoration: const InputDecoration(labelText: 'અંગ્રેજી નામ (English Name / Keywords) - Optional'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'ભાવ (Price)', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('સ્ટોકમાં ઉપલબ્ધ છે? (Is Available?)'),
              value: _isAvailable,
              activeColor: AppTheme.primaryGreen,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _isAvailable = val);
              },
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : Row(
                    children: [
                      if (isEditing) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _delete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('ડિલીટ'),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(isEditing ? 'સાચવો (Save)' : 'ઉમેરો (Add)'),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
