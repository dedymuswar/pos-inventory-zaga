import 'package:flutter/material.dart';
import 'package:pos_inventory/features/printer_settings/printer_setting_screen.dart';
import 'package:pos_inventory/features/products/product_screen.dart';
import 'package:pos_inventory/features/list_transaction/list_transaction_screen.dart';

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
                MaterialPageRoute(builder: (_) => const ProductScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Riwayat Transaksi'),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ListTransactionScreen()));
            } ,
          ),
          const Divider(),

        ],
      ),
    );
  }
}
