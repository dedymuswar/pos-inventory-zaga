import 'package:flutter/material.dart';
import 'package:pos_inventory/features/printer/pages/printer_setting_page.dart';
import 'package:pos_inventory/features/products/pages/product_page.dart';
import 'package:pos_inventory/features/transaction/pages/transaction_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Kasir Dedy'),
            accountEmail: Text('Pos System'),
            currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Master Barang'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Riwayat Transaksi'),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionPage()));
            } ,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Pengaturan printer'),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingPage()));
            } ,
          ),
          const Divider(),
        ],
      ),
    );
  }
}
