import 'package:flutter/material.dart';
import 'package:pos_inventory/features/auth/pages/login_page.dart';
import 'package:pos_inventory/features/products/product_screen.dart';
import 'package:pos_inventory/features/list_transaction/list_transaction_screen.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
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
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red),),
            onTap: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            },
          )
        ],
      ),
    );
  }
}
