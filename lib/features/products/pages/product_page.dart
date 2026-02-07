import 'package:flutter/material.dart';
import '../logic/product_service.dart';
import '../data/product_model.dart';
import '../widgets/product_form_modal.dart';
import '../widgets/product_table.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductService _service = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _service.getProducts();
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat produk: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddProductModal() async{
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProductFormModal(),
    );

    // Kalau modal return true → reload data
    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: 
        AppBar(title: const Text('Master Barang')),
              body: _isLoading ? const Center(child: CircularProgressIndicator()): _products.isEmpty ? const Center(child: Text('Belum ada barang')) : 
              
              Padding(padding: const EdgeInsets.all(12),
              child: ProductTable(products: _products)
              ),

            floatingActionButton: FloatingActionButton.extended(onPressed: _openAddProductModal, label: const Text("Tambah Barang"), icon: const Icon(Icons.add),
            ),
      );
  }
}
