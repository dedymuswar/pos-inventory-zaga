import 'package:flutter/material.dart';
import 'package:pos_inventory/features/products/widgets/stock_card.dart';
import 'logic/product_controller.dart';
import '../../models/product_model.dart';
import 'widgets/product_form_modal.dart';
import 'widgets/product_table.dart';
import 'widgets/restock_dialog.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
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

  Future<void> _openRestockDialog(Product product) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => RestockDialog(product: product),
    );

    if (result == null) return;

    await _restock(
      product: product,
      qty: result['qty'] as int,
      reference: result['reference'] as String?,
    );
  }
  
  Future<void> _restock({
    required Product product,
    required int qty,
    String? reference,
  }) async {
    try {
      final productId = product.id;
      if (productId == null) {
        throw Exception('Product ID tidak ditemukan : id kosong');
      }
      await _service.restockProduct(
        productId: productId,
        qty: qty,
        reference: reference,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restock berhasil')));
        await _loadProducts();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restock gagal: $e')));
    }
  }

  void _openAddProductModal() async {
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

  void _openStockCard(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockCard(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Barang')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('Belum ada barang'))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ProductTable(
                products: _products,
                onRestock: _openRestockDialog,
                onStockCard: _openStockCard,
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProductModal,
        label: const Text("Tambah Barang"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
