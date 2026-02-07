import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/features/printer/logic/printer_setting_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterSettingPage extends StatefulWidget {
  const PrinterSettingPage({super.key});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {
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
      appBar: AppBar(title: const Text("Printer Setting")),
      body: Column(
        children: [
          // dropdown printer
          DropdownButtonFormField <BluetoothInfo>(
                hint: const Text("Pilih Printer"),
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

          // refresh button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadDevices,
            ),
          ),

          // Auto print checkbox
          CheckboxListTile(
            title: const Text("Auto Print"),
            value: autoPrint,
            onChanged: (value) async {
              autoPrint = value ?? false;
              await PrinterSettingService.setAutoPrint(autoPrint);
              setState(() {});
            },
          ),

          const SizedBox(height: 10),

          // status
          Text(
            isConnected ? "Status: Connected" : "Status: Disconnected",
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Connect
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: connectPrinter,
                child: const Text("CONNECT"),
              ),
            ),

            const SizedBox(height: 10),

            // Disconnect
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: disconnectPrinter,
                child: const Text("DISCONNECT"),
              ),
            ),

            const SizedBox(height: 10),

            // test print
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: testPrint, child: const Text("TestPrint"))
            )
        ],
      ),
    );
  }
}
