import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/features/products/widgets/barang_card.dart';
import '../../../models/product_model.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    required this.onRestock,
    required this.onStockCard,
  });

  final List<Product> products;
  final void Function(Product product) onRestock;
  final void Function(Product product) onStockCard;
  static final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return BarangCard(
          nama: product.name,
          kode: product.barcode,
          category: product.category,
          stok: product.stock,
          harga: _priceFormatter.format(product.price),
          onSelectedAction: (value) {
            if (value == 'restock') {
              onRestock(product);
              return;
            }
            if (value == 'stock_card') {
              onStockCard(product);
            }
          },
        );
      },
    );
  }
}
