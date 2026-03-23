import 'package:flutter/material.dart';
import 'package:pos_inventory/features/cart/logic/cart_controller.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/features/post_transaction/bluetooth_printer_page.dart';
import 'package:pos_inventory/features/post_transaction/logic/thermal_printer_service.dart';
import 'package:pos_inventory/models/transaction_detail.dart';

class PostTransactionScreen extends StatefulWidget {
  const PostTransactionScreen({
    super.key,
    required this.trxCode,
    this.cartController,
  });
  final String trxCode;
  final CartController? cartController;

  @override
  State<PostTransactionScreen> createState() => _PostTransactionScreenState();
}

class _PostTransactionScreenState extends State<PostTransactionScreen> {
  Transactionfinal? trxDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db = DatabaseHelper.instance;
    trxDetail = await db.getTransactionDetail(widget.trxCode);
    setState(() => isLoading = false);
  }

  void _finishTransaction() {
    final cartController = widget.cartController;
    if (cartController != null) {
      try {
        cartController.clearCart();
      } catch (e) {
        debugPrint('Lewati clearCart karena controller sudah disposed: $e');
      }
    }
    // kembali ke halaman pertama
    Navigator.of(context).popUntil((route) =>route.isFirst);

  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final header = trxDetail!.header;
    final items = trxDetail!.items;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Transaksi Selesai"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _successHeader(header),
            const SizedBox(height: 16),
            _paymentSummary(header),
            const SizedBox(height: 16),
            _itemSection(items),
            const SizedBox(height: 20),
            _actionButtons(trxDetail),
          ],
        ),
      ),
    );
  }

  Widget _successHeader(TransactionDetail header) {
    return Card(
      color: Colors.green[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TRANSAKSI BERHASIL",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "Kode: ${header.trx_code}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSummary(TransactionDetail h) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row("TOTAL", h.total_amount),
            _row("BAYAR", h.received_money),
            _row("KEMBALI", h.change),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            "Rp $value",
            style: const TextStyle(
              color: Colors.pinkAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemSection(List<TransactionDetailItems> items) {
    final header = trxDetail?.header;
    final subtotal = header?.subtotal ?? 0;
    final discountAmount = header?.discount_amount ?? 0;
    final taxAmount = header?.tax_amount ?? 0;
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "RINGKASAN ITEM (${items.length})",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (i) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${i.product_name} x${i.qty}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "Rp ${i.subtotal}",
                    style: const TextStyle(color: Colors.pinkAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            _summaryRow("Subtotal", subtotal),
            _summaryRow("Diskon", discountAmount),
            _summaryRow("Pajak", taxAmount),
            _summaryRow(
              "Total",
              trxDetail?.header.total_amount ?? 0,
              isEmphasis: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int value, {bool isEmphasis = false}) {
    final textStyle = TextStyle(
      color: isEmphasis ? Colors.white : Colors.white70,
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: isEmphasis ? Colors.white : Colors.pinkAccent,
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text("Rp $value", style: valueStyle),
        ],
      ),
    );
  }

  Widget _actionButtons(Transactionfinal? trxDetail) {
    final printerService = ThermalPrinterService();
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text("CETAK STRUK"),
          onPressed: () async {

            final BluetoothInfo? device = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BluetoothPrinterPage()),
            );
            
            if (device != null) {
              // Tunggu koneksi berhasil dulu sebelum print
              await printerService.connectPrinter(device); 
              await printerService.printReceipt58mm(trxDetail!);
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _finishTransaction,
          child: const Text("TRANSAKSI BARU"),
        ),
      ],
    );
  }
}
