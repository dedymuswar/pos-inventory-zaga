import 'package:flutter/material.dart';

class ProductSearchSection extends StatelessWidget {
  const ProductSearchSection({
    super.key,
    required this.onChanged,
    required this.controller,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cari Barang',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF174FBF),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama, barcode, atau kategori...',
              hintStyle: const TextStyle(color: Color(0xFF7A8FB8)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1D61E7),
              ),
              suffixIcon: IconButton(
                onPressed: controller.text.isEmpty
                    ? null
                    : () {
                        controller.clear();
                        onChanged('');
                      },
                icon: const Icon(Icons.close_rounded, color: Color(0xFF1D61E7)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD0DEFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1D61E7),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
