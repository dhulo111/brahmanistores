import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/product_model.dart';

class ProductState {
  final bool isLoading;
  final String? error;
  final List<ProductModel> products;

  ProductState({
    this.isLoading = false,
    this.error,
    this.products = const [],
  });

  ProductState copyWith({
    bool? isLoading,
    String? error,
    List<ProductModel>? products,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final Dio _dio;

  ProductNotifier(this._dio) : super(ProductState()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data['products'];
      final productsList = data.map((json) => ProductModel.fromJson(json)).toList();
      state = state.copyWith(isLoading: false, products: productsList);
    } catch (e) {
      print('Error fetching products: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to fetch products');
    }
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/admin/products', data: data);
      if (response.statusCode == 201) {
        final newProduct = ProductModel.fromJson(response.data['product']);
        state = state.copyWith(products: [newProduct, ...state.products]);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/admin/products/$id', data: data);
      if (response.statusCode == 200) {
        final updatedProduct = ProductModel.fromJson(response.data['product']);
        final updatedList = state.products.map((p) {
          return p.id == id ? updatedProduct : p;
        }).toList();
        state = state.copyWith(products: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _dio.delete('/admin/products/$id');
      if (response.statusCode == 200) {
        final updatedList = state.products.where((p) => p.id != id).toList();
        state = state.copyWith(products: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref.watch(apiClientProvider));
});
