import 'package:flutter/material.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/features/cart/logic/cart_controller.dart';
import 'package:pos_inventory/models/pending_transaction.dart';
import 'package:pos_inventory/features/payment/logic/payment_controller.dart';
import 'package:pos_inventory/features/post_transaction/post_transaction_screen.dart';
import 'package:pos_inventory/features/post_transaction/logic/thermal_printer_service.dart';
import 'package:sqflite/sqlite_api.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.transaction,
    required this.cartController,
  });
  final PendingTransaction transaction;
  final CartController cartController;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentController controller = PaymentController();
  int terimaUang = 0;
  bool isLoading = false;
  int get kembalian => terimaUang - widget.transaction.totalAmount;

  void _tambahUang(int uang) {
    setState(() {
      terimaUang += uang;
    });
  }

  Future<void> prosesPembayaran() async {
    if (kembalian < 0) return;

    setState(() => isLoading = true);

    // Kirim terimaUang ke controller
    final success = await controller.prosesPembayaran(
      widget.transaction,
      terimaUang,
    );

    setState(() => isLoading = false);

    if (success) {
      if (!mounted) return;

      final printerService = ThermalPrinterService();
      final db = DatabaseHelper.instance;
      final trxFinal = await db.getTransactionDetail(
        widget.transaction.trxCode,
      );
      if (trxFinal != null) {
        await printerService.autoPrint58mm(trxFinal);
      }

      // reset cart
      widget.cartController.clearCart();

      // Kembali ke halaman sebelumnya dengan hasil true
      // Navigator.pop(context, true);
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PostTransactionScreen( trxCode:widget.transaction.trxCode, cartController: widget.cartController)));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PostTransactionScreen(
            trxCode: widget.transaction.trxCode,
            cartController: widget.cartController,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) =>
            const AlertDialog(content: Text('Gagal memproses pembayaran')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trx = widget.transaction;

    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Info Transaksi
            Card(
              child: ListTile(
                title: Text(trx.trxCode),
                subtitle: Text("Kasir: ${trx.cashierName}"),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Total Tagihan
            Text(
              "TOTAL TAGIHAN",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "Rp ${trx.totalAmount}",
              style: Theme.of(context).textTheme.headlineLarge,
            ),

            const SizedBox(height: 24),

            // 🔹 Uang diterima
            Text("Uang Diterima"),
            Text(
              "Rp $terimaUang",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 12),

            // 🔹 Tombol uang cepat
            Wrap(
              spacing: 10,
              children: [
                _moneyButton(10000),
                _moneyButton(20000),
                _moneyButton(50000),
                _moneyButton(trx.totalAmount), // PAS
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 Kembalian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kembalian"),
                Text(
                  "Rp ${kembalian < 0 ? 0 : kembalian}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),

            const Spacer(),

            // 🔹 Tombol Proses
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: kembalian >= 0 ? prosesPembayaran : null,
                child: const Text("PROSES PEMBAYARAN"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyButton(int amount) {
    return ElevatedButton(
      onPressed: () => _tambahUang(amount),
      child: Text("+Rp $amount"),
    );
  }
}
