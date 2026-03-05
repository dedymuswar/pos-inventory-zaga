import 'package:flutter/material.dart';
import 'package:pos_inventory/features/products/widgets/stock_card.dart';
import 'logic/product_controller.dart';
import '../../models/product_model.dart';
import 'widgets/product_form_modal.dart';
import 'widgets/product_search_section.dart';
import 'widgets/product_table.dart';
import 'widgets/restock_dialog.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  final ProductService _service = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      final name = product.name.toLowerCase();
      final barcode = product.barcode.toLowerCase();
      final category = product.category.toLowerCase();
      return name.contains(query) ||
          barcode.contains(query) ||
          category.contains(query);
    }).toList();
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
      final actorName = context.read<AuthController>().currentUser?.username;
      final productId = product.id;
      if (productId == null) {
        throw Exception('Product ID tidak ditemukan : id kosong');
      }
      await _service.restockProduct(
        productId: productId,
        qty: qty,
        actorName: actorName,
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
      MaterialPageRoute(builder: (_) => StockCard(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProducts = _filteredProducts;
    final Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : visibleProducts.isEmpty
        ? Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'Belum ada barang'
                  : 'Barang tidak ditemukan',
            ),
          )
        : ProductTable(
            products: visibleProducts,
            onRestock: _openRestockDialog,
            onStockCard: _openStockCard,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Master Barang'),
        backgroundColor: const Color(0xFF1D61E7),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          ProductSearchSection(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          Expanded(child: content),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProductModal,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
