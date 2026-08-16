import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/nav_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'add_edit_product_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN';
    final state = ref.watch(productProvider);

    final filteredProducts = state.products.where((p) {
      final query = _searchQuery.toLowerCase();
      final nameMatches = p.name.toLowerCase().contains(query);
      final englishNameMatches = p.englishName?.toLowerCase().contains(query) ?? false;
      return nameMatches || englishNameMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('પ્રોડક્ટ્સ'), // Products
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28, color: AppTheme.primaryGreen),
              tooltip: 'પ્રોડક્ટ ઉમેરો',
              onPressed: () async {
                ref.read(navBarVisibilityProvider.notifier).state = false;
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const AddEditProductSheet(),
                );
                ref.read(navBarVisibilityProvider.notifier).state = true;
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.products.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(productProvider.notifier).fetchProducts(),
                        child: const Text('ફરી પ્રયાસ કરો (Retry)'),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'પ્રોડક્ટ શોધો... (Search product)',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(productProvider.notifier).fetchProducts(),
                        child: filteredProducts.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(
                                    child: Text('કોઈ પ્રોડક્ટ નથી (No products)', style: TextStyle(color: AppTheme.textSecondary)),
                                  )
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return _ProductCard(product: product, isAdmin: isAdmin);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool isAdmin;
  
  const _ProductCard({required this.product, required this.isAdmin});

  void _showEditSheet(BuildContext context, WidgetRef ref) async {
    ref.read(navBarVisibilityProvider.notifier).state = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditProductSheet(product: product),
    );
    ref.read(navBarVisibilityProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAdmin ? () => _showEditSheet(context, ref) : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryDark,
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.textSecondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹ ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isAvailable 
                              ? AppTheme.primaryGreen.withOpacity(0.15) 
                              : AppTheme.errorColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: product.isAvailable ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          product.isAvailable ? 'ઉપલબ્ધ છે' : 'સ્ટોક નથી',
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: product.isAvailable ? AppTheme.primaryGreen : AppTheme.errorColor,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 8),
                        const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 20),
                      ]
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

