import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterPage extends StatefulWidget {
  const BluetoothPrinterPage({super.key});

  @override
  State<BluetoothPrinterPage> createState() => _BluetoothPrinterPageState();
}

class _BluetoothPrinterPageState extends State<BluetoothPrinterPage> {
  List<BluetoothInfo> _devices = [];

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  Future<void> _getDevices() async {
    if (Platform.isAndroid) {
      // Meminta izin Bluetooth Connect & Scan (Android 12+) dan Lokasi (Android <12)
      // Tanpa izin ini, pairedBluetooths akan mengembalikan list kosong
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }

    final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
    setState(() {
      _devices = list;
    });
  }

  void _connectPrinter(BluetoothInfo printer) {
    Navigator.pop(context, printer); // kirim device ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Printer Bluetooth")),
      body: _devices.isEmpty 
          ? const Center(child: Text("Tidak ada printer terhubung.\nPastikan printer sudah dipairing di pengaturan Bluetooth HP.", textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final d = _devices[index];
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(d.name),
                  subtitle: Text(d.macAdress),
                  onTap: () => _connectPrinter(d),
                );
              },
            ),
    );
  }
}
