import 'package:flutter/material.dart';
import 'package:pos_inventory/features/cart/logic/cart_controller.dart';
import 'package:pos_inventory/features/payment/payment_screen.dart';
import 'package:pos_inventory/features/products/widgets/scan_barcode_page.dart';
import 'package:pos_inventory/core/widgets/app_drawer.dart';
import 'package:pos_inventory/features/cart/widgets/cart_header.dart';
import 'package:pos_inventory/features/cart/widgets/cart_summary.dart';
import 'package:pos_inventory/features/cart/widgets/cart_item_widget.dart';
import 'package:pos_inventory/features/cart/logic/cart_mapper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController _controller = CartController();
  final namaKasir = "ZAYYAN";
  Future<void> _bayarSekarang() async {
    if (_controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }

    // Gunakan _controller langsung karena ini adalah local state
    final pendingTrx = CartMapper.fromCart(
      cartItems: _controller.items,
      cashierId: "KSR01",
      cashierName: namaKasir,
    );

    // Tunggu hasil dari PaymentPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(transaction: pendingTrx, cartController: _controller),
      ),
    );

    // Jika pembayaran sukses (result == true), bersihkan keranjang
    if (result == true) {
      _controller.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran Berhasil')));
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

    final success = await _controller.handleBarcodeScan(barcode);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produk tidak ditemukan')));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: _scanAndAddItem,
              icon: const Icon(Icons.barcode_reader, size: 18),
              label: const Text('Tambah'),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            children: [
              CartHeader(kasir: namaKasir, ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _controller.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada item',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _controller.items.length,
                          itemBuilder: (context, index) => CartItemWidget(
                            item: _controller.items[index],
                            onAdd: () => _controller.updateQty(index, 1),
                            onRemove: () => _controller.updateQty(index, -1),
                          ),
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
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _bayarSekarang,
                  child: Text(
                    'BAYAR SEKARANG',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
