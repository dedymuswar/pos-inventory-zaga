import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pos_inventory/features/post_transaction/models/transaction_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThermalPrinterService {
  Future<bool> connectSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    String? mac = prefs.getString('printer_mac');

    if (mac == null) return false;

    bool connected = await PrintBluetoothThermal.connectionStatus;

    if (!connected) {
      return await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    }

    return true;
  }

  Future<void> autoPrint58mm(Transactionfinal trx) async {
    final prefs = await SharedPreferences.getInstance();
    bool autoPrint = prefs.getBool('auto_print') ?? false;

    if (!autoPrint) return;

    bool connected = await connectSavedPrinter();
    if (!connected) return;

    await printReceipt58mm(trx);
  }

  Future<bool> connectPrinter(BluetoothInfo device) async {
    return await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );
  }

  Future<void> printReceipt58mm(Transactionfinal trx) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    bytes += generator.text(
      "KIOS ZAGA",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      "Jl. Mariadei(Samp Stadion), Serui",
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr();

    for (var item in trx.items) {
      bytes += generator.text(item.product_name);
      bytes += generator.row([
        PosColumn(text: "${item.qty} x ${item.price}", width: 6),
        PosColumn(
          text: item.subtotal.toString(),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: "TOTAL", width: 6),
      PosColumn(
        text: trx.header.total_amount.toString(),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr();
    bytes += generator.text(
      "Terima Kasih",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.text(
      "Barang yang sudah dibeli\n tidak dapat dikembalikan",
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
  }
}
