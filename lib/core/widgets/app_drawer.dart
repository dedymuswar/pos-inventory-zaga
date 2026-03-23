import 'package:flutter/material.dart';
import 'package:pos_inventory/features/auth/pages/login_page.dart';
import 'package:pos_inventory/features/auth/pages/manage_users_page.dart';
import 'package:pos_inventory/features/cart/cart_screen.dart';
import 'package:pos_inventory/features/dashboard/dashboard_screen.dart';
import 'package:pos_inventory/features/discount_tax/discount_tax_setting_screen.dart';
import 'package:pos_inventory/features/printer_settings/printer_setting_screen.dart';
import 'package:pos_inventory/features/products/product_screen.dart';
import 'package:pos_inventory/features/list_transaction/list_transaction_screen.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _primaryBlue = Color(0xFF1D61E7);

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Future.microtask(() {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final displayName = auth.currentUser?.username ?? 'User';
    final roleLabel = auth.currentUser?.role.name.toUpperCase() ?? 'ROLE';
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A7CF5),
                    Color(0xFF1D61E7),
                    Color(0xFF164CB7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: _primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                children: [
                  _DrawerMenuTile(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () {
                      _openPage(context, const DashboardScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.calculate_outlined,
                    title: 'Transaksi',
                    onTap: () {
                      _openPage(context, const CartScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Master Barang',
                    onTap: () {
                      _openPage(context, const ProductScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.receipt_long,
                    title: 'Riwayat Transaksi',
                    onTap: () {
                      _openPage(context, const ListTransactionScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.print_outlined,
                    title: 'Pengaturan printer',
                    onTap: () {
                      _openPage(context, const PrinterSettingScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.percent,
                    title: 'Diskon & Pajak',
                    onTap: () {
                      _openPage(context, const DiscountTaxSettingScreen());
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFE2E8F7)),
                  _DrawerMenuTile(
                    icon: Icons.person_3_outlined,
                    title: 'Manage User',
                    onTap: () {
                      _openPage(context, const ManageUsersPage());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _DrawerMenuTile(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: const Color(0xFFDC2626),
                textColor: const Color(0xFFDC2626),
                onTap: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
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

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF1D61E7),
    this.textColor = const Color(0xFF0F172A),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
