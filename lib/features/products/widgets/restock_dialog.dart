import 'package:flutter/material.dart';
import 'package:pos_inventory/models/product_model.dart';

class RestockDialog extends StatelessWidget {
  RestockDialog({super.key, required this.product});

  final Product product;
  final formKey = GlobalKey<FormState>();
  final qtyC = TextEditingController();
  final refC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Restock ${product.name}'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: qtyC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity masuk',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final q = int.tryParse((value ?? '').trim());
                if (q == null || q <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: refC,
              decoration: const InputDecoration(
                labelText: 'Reference',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final qty = int.parse(qtyC.text.trim());
              final reference = refC.text.trim().isEmpty ? null : refC.text.trim();
              Navigator.pop(context, {'qty': qty, 'reference': reference});
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
