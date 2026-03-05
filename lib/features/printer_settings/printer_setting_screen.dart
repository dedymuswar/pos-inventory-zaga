import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/features/printer_settings/logic/printer_setting_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  List<BluetoothInfo> devices = [];
  BluetoothInfo? selectedDevice;
  bool autoPrint = false;
  bool isConnected = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadSavedSettings();
    loadDevices();
  }

  Future<void> loadDevices() async {
    final list = await PrintBluetoothThermal.pairedBluetooths;
    setState(() {
      devices = list;
    });
  }

  Future<void> loadSavedSettings() async {
    String? mac = await PrinterSettingService.getPrinter();
    autoPrint = await PrinterSettingService.getAutoPrint();
    if (mac != null) {
      selectedDevice = BluetoothInfo(name: "Saved Printer", macAdress: mac);
    }

    isConnected = await PrintBluetoothThermal.connectionStatus;
    setState(() {});
  }

  // connect printer
  Future<void> connectPrinter() async {
    if (selectedDevice == null) return;

    bool result = await PrintBluetoothThermal.connect(
      macPrinterAddress: selectedDevice!.macAdress,
    );

    setState(() {
      isConnected = result;
    });
  }

  // disconnect printer
  Future<void> disconnectPrinter() async {
    await PrintBluetoothThermal.disconnect;
    setState(() {
      isConnected = false;
    });
  }

  // test Print
  Future<void> testPrint() async {
    bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      await connectPrinter();
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    bytes += generator.text(
      "TEST PRINT",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();
    bytes += generator.text("Printer berhasil terhubung");
    bytes += generator.feed(2);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Printer Setting"),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF1FF), Color(0xFFDDE9FF)],
                ),
                border: Border.all(color: const Color(0xFFBBD0FF)),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<BluetoothInfo>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Pilih Printer",
                      hintStyle: const TextStyle(color: Color(0xFF6D84B3)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DEFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue),
                      ),
                    ),
                    value: selectedDevice,
                    items: devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text("${device.name} (${device.macAdress})"),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      selectedDevice = value;
                      await PrinterSettingService.savePrinter(value.macAdress);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryBlue,
                      ),
                      icon: const Icon(Icons.refresh),
                      onPressed: loadDevices,
                    ),
                  ),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _primaryBlue,
                    title: const Text("Auto Print"),
                    value: autoPrint,
                    onChanged: (value) async {
                      autoPrint = value ?? false;
                      await PrinterSettingService.setAutoPrint(autoPrint);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isConnected ? "Status: Connected" : "Status: Disconnected",
                style: TextStyle(
                  color: isConnected ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: isConnected
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: const BorderSide(color: _primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: disconnectPrinter,
                      child: const Text("DISCONNECT"),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: selectedDevice == null ? null : connectPrinter,
                      child: const Text("CONNECT"),
                    ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: testPrint,
                child: const Text("Test Print"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
