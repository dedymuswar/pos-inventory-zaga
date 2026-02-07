import 'package:flutter/material.dart';
import 'package:pos_inventory/features/products/pages/product_page.dart';
import 'package:pos_inventory/features/cart/pages/transaksi_page.dart';

void main(List<String> args) {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(title: 'POS MASTER BARANG', home: ProductPage());
    return MaterialApp(title: 'POS MASTER BARANG', home: TransaksiPage());
  }
}
