import 'package:flutter/material.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/cart_item.dart';
import 'package:pos_inventory/models/product_model.dart';

enum AddToCartResult {
  success,
  productNotFound,
  outOfStock,
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  final Map<int, int> _stockByProductId = {};
  final String cashierId = '001';
  final String cashierName = 'Kasir Dedy';

  List<CartItem> get items => List.unmodifiable(_items);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  int get discount => 0; // Logic diskon bisa ditambahkan nanti
  int get tax => 0; // Logic pajak bisa ditambahkan nanti
  int get total => subtotal - discount + tax;

  /// Mencari produk berdasarkan barcode dan menambahkannya ke keranjang
  /// Mengembalikan true jika produk ditemukan, false jika tidak
  Future<AddToCartResult> handleBarcodeScan(String barcode) async {
    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (product == null) {
      return AddToCartResult.productNotFound;
    }

    final added = _addToCart(product);
    return added ? AddToCartResult.success : AddToCartResult.outOfStock;
  }

  bool addProduct(Product product) {
    if (product.id == null) return false;
    return _addToCart(product);
  }

  bool _addToCart(Product product) {
    if (product.id == null || product.stock <= 0) return false;
    _stockByProductId[product.id!] = product.stock;
    final index = _items.indexWhere((item) => item.productId == product.id);

    if (index == -1) {
      // Item belum ada, tambahkan baru (convert price ke int)
      _items.add(
        CartItem(
          productId: product.id!,
          name: product.name,
          price: product.price.toInt(),
        ),
      );
    } else {
      // Item sudah ada, update quantity
      final item = _items[index];
      final stockLimit = _stockByProductId[item.productId] ?? product.stock;
      if (item.qty >= stockLimit) {
        return false;
      }
      _items[index] = CartItem(
        productId: item.productId,
        name: item.name,
        price: item.price,
        qty: item.qty + 1,
      );
    }
    notifyListeners();
    return true;
  }

  bool canIncreaseQty(int index) {
    if (index < 0 || index >= _items.length) return false;
    final item = _items[index];
    final stockLimit = _stockByProductId[item.productId];
    if (stockLimit == null) return true;
    return item.qty < stockLimit;
  }

  bool updateQty(int index, int change) {
    if (index < 0 || index >= _items.length) return false;

    final item = _items[index];
    final newQty = item.qty + change;
    if (change > 0) {
      final stockLimit = _stockByProductId[item.productId];
      if (stockLimit != null && newQty > stockLimit) {
        return false;
      }
    }

    if (newQty > 0) {
      // Update item dengan qty baru
      _items[index] = CartItem(
        productId: item.productId,
        name: item.name,
        price: item.price,
        qty: newQty,
      );
    } else {
      // Hapus item jika qty menjadi 0
      _items.removeAt(index);
    }
    notifyListeners();
    return true;
  }

  void clearCart() {
    _items.clear();
    _stockByProductId.clear();
    notifyListeners();
  }
}
