import 'package:flutter/material.dart';
import '../logic/product_service.dart';
import '../data/product_model.dart';
import '../../cart/widgets/barcode_scanner_page.dart';

class ProductFormModal extends StatefulWidget {
  const ProductFormModal({super.key});

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeC = TextEditingController();
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _stockC = TextEditingController();

  String _selectedCategory = "Umum";
  final ProductService _service = ProductService();

  final List<String> categories = [
    "Umum",
    "Makanan",
    "Minuman",
    "Elektronik",
    "Lainnya"
  ];

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (result != null) {
      _barcodeC.text = result;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      barcode: _barcodeC.text.trim(), // Pastikan tidak ada spasi tersimpan
      name: _nameC.text,
      price: double.parse(_priceC.text),
      stock: int.parse(_stockC.text),
      category: _selectedCategory,
    );

    await _service.insertProduct(product);

    if (mounted) {
      Navigator.pop(context, true); // kirim sinyal refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barang berhasil disimpan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tambah Barang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// BARCODE
              TextFormField(
                controller: _barcodeC,
                decoration: InputDecoration(
                  labelText: "Barcode",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Barcode wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              /// NAMA
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(
                  labelText: "Nama Barang",
                  border: OutlineInputBorder(),
                ), 
                validator: (v) => v!.isEmpty ? "Nama barang wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              /// HARGA
              TextFormField(
                controller: _priceC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Harga",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Harga wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              /// STOK
              TextFormField(
                controller: _stockC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stok",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Stok wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              /// CATEGORY
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),

              /// BUTTON SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan Barang"),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
