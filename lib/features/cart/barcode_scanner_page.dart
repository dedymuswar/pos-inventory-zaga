import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isScanned = false;
  late MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    // Start the controller
    _controller.start().then((_) {
      print('✅ Camera started successfully');
    }).catchError((error) {
      print('❌ Camera start error: $error');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (barcodeCapture) {
              if (_isScanned) return;

              final List<Barcode> barcodes = barcodeCapture.barcodes;
              final String? code = barcodes.first.rawValue;

              if (code != null) {
                _isScanned = true;
                Navigator.pop(context, code);
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Simulator mungkin tidak support kamera.\nCoba di device fisik.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Loading indicator
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) {
              if (!value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          /// Overlay kotak scanner
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          /// Hint text
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "Arahkan barcode ke dalam kotak",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
