import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.discountLabel,
    required this.tax,
    required this.taxLabel,
    required this.total,
  });

  final int subtotal;
  final int discount;
  final String discountLabel;
  final int tax;
  final String taxLabel;
  final int total;

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      color: Colors.white,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 18 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A7CF5),
            Color(0xFF1D61E7),
            Color(0xFF164CB7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D61E7).withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Transaksi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow('Subtotal', 'Rp $subtotal'),
          _summaryRow(discountLabel, 'Rp $discount'),
          _summaryRow(taxLabel, 'Rp $tax'),
          const Divider(color: Color.fromARGB(255, 255, 255, 255)),
          _summaryRow('Total', 'Rp $total', isTotal: true),
        ],
      ),
    );
  }
}
