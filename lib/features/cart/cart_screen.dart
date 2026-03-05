import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/features/cart/logic/cart_controller.dart';
import 'package:pos_inventory/features/payment/payment_screen.dart';
import 'package:pos_inventory/features/products/widgets/scan_barcode_page.dart';
import 'package:pos_inventory/features/products/logic/product_controller.dart';
import 'package:pos_inventory/core/widgets/app_drawer.dart';
import 'package:pos_inventory/features/cart/widgets/cart_header.dart';
import 'package:pos_inventory/features/cart/widgets/cart_summary.dart';
import 'package:pos_inventory/features/cart/widgets/cart_item_widget.dart';
import 'package:pos_inventory/features/cart/logic/cart_mapper.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:pos_inventory/models/product_model.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  static const Color _primaryBlueLight = Color(0xFF3A7CF5);
  static const Color _primaryBlueDark = Color(0xFF164CB7);
  final CartController _controller = CartController();
  final ProductService _productService = ProductService();

  Future<void> _bayarSekarang() async {
    final auth = context.read<AuthController>();
    if (_controller.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong')));
      return;
    }

    // Gunakan _controller langsung karena ini adalah local state
    final pendingTrx = CartMapper.fromCart(
      cartItems: _controller.items,
      cashierId: auth.currentUser!.id,
      cashierName: auth.currentUser!.username,
    );

    // Tunggu hasil dari PaymentPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentScreen(transaction: pendingTrx, cartController: _controller),
      ),
    );

    // Jika pembayaran sukses (result == true), bersihkan keranjang
    if (result == true) {
      _controller.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pembayaran Berhasil')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanAndAddItem() async {
    // buka halaman scan dan tunggu hasil barcode
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );

    debugPrint("Scan result: $barcode");

    if (barcode == null) return;
    if (!mounted) return;

    final result = await _controller.handleBarcodeScan(barcode);

    if (!mounted) return;

    if (result == AddToCartResult.productNotFound) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produk tidak ditemukan')));
      return;
    }

    if (result == AddToCartResult.outOfStock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stok kosong atau sudah habis')));
    }
  }

  Future<void> _openManualAddDialog() async {
    final products = (await _productService.getProducts())
        .where((product) => product.stock > 0)
        .toList();
    if (!mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada produk dengan stok tersedia')),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showDialog<Product>(
      context: context,
      builder: (_) => _ManualItemDialog(products: products),
    );

    if (!mounted || selected == null) return;

    final success = _controller.addProduct(selected);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok habis, produk tidak bisa ditambahkan')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selected.name} ditambahkan ke cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final namaKasir = context.select<AuthController, String>(
      (auth) => auth.currentUser?.username ?? '-',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Transaksi"),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _scanAndAddItem,
              icon: const Icon(Icons.barcode_reader, size: 18),
              label: const Text('SCAN'),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                CartHeader(kasir: namaKasir),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryBlueLight,
                          _primaryBlue,
                          _primaryBlueDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _controller.items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_shopping_cart_outlined,
                                  color: Colors.white70,
                                  size: 34,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Belum ada item',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _controller.items.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: CartItemWidget(
                                      item: _controller.items[index],
                                      onAdd: () {
                                        final success = _controller.updateQty(
                                          index,
                                          1,
                                        );
                                        if (!success && mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Stok habis, tidak bisa menambah item lagi',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onRemove: () =>
                                          _controller.updateQty(index, -1),
                                      isAddEnabled: _controller.canIncreaseQty(
                                        index,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                CartSummary(
                  subtotal: _controller.subtotal,
                  discount: _controller.discount,
                  tax: _controller.tax,
                  total: _controller.total,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.45),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.85,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.black.withValues(alpha: 0.08);
                            }
                            return null;
                          }),
                        ),
                    onPressed: _controller.items.isEmpty
                        ? null
                        : _bayarSekarang,
                    child: const Text(
                      'BAYAR SEKARANG',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openManualAddDialog,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }
}

class _ManualItemDialog extends StatefulWidget {
  const _ManualItemDialog({required this.products});

  final List<Product> products;

  @override
  State<_ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends State<_ManualItemDialog> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _query = '';

  List<Product> get _filtered {
    final query = _query.trim().toLowerCase();
    final inStockProducts = widget.products
        .where((product) => product.stock > 0)
        .toList();
    if (query.isEmpty) return inStockProducts;
    return inStockProducts.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 580),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: _primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tambah Item Manual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() => _query = value);
              },
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama atau barcode...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD8E3FB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD8E3FB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primaryBlue, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text(
                        'Barang tidak ditemukan',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Material(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, product),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD9E3FB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: _primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.barcode,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _priceFormat.format(product.price),
                                        style: const TextStyle(
                                          color: _primaryBlue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Stok ${product.stock}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
