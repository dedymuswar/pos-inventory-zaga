import 'package:flutter/material.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/cart_item.dart';
import 'package:pos_inventory/models/product_model.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  final String cashierId = '001';
  final String cashierName = 'Kasir Dedy';

  List<CartItem> get items => List.unmodifiable(_items);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  int get discount => 0; // Logic diskon bisa ditambahkan nanti
  int get tax => 0; // Logic pajak bisa ditambahkan nanti
  int get total => subtotal - discount + tax;

  /// Mencari produk berdasarkan barcode dan menambahkannya ke keranjang
  /// Mengembalikan true jika produk ditemukan, false jika tidak
  Future<bool> handleBarcodeScan(String barcode) async {
    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (product == null) {
      return false;
    }

    _addToCart(product);
    return true;
  }

  void _addToCart(Product product) {
    final index = _items.indexWhere((item) => item.name == product.name);

    if (index == -1) {
      // Item belum ada, tambahkan baru (convert price ke int)
      _items.add(CartItem(productId: product.id!, name: product.name, price: product.price.toInt()));
    } else {
      // Item sudah ada, update quantity
      final item = _items[index];
      _items[index] = CartItem(
        productId: item.productId,
        name: item.name,
        price: item.price,
        qty: item.qty + 1,
      );
    }
    notifyListeners();
  }

  void updateQty(int index, int change) {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];
    final newQty = item.qty + change;

    if (newQty > 0) {
      // Update item dengan qty baru
      _items[index] = CartItem(productId: item.productId, name:item.name, price: item.price, qty: newQty);
    } else {
      // Hapus item jika qty menjadi 0
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  
}
