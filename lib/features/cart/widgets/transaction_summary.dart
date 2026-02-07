import 'package:flutter/material.dart';

class TransactionSummary extends StatelessWidget {
  const TransactionSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  final int subtotal;
  final int discount;
  final int tax;
  final int total;

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      color: Colors.white,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 18 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
          _summaryRow('Subtotal', 'Rp $subtotal'),
          _summaryRow('Diskon (0%)', 'Rp $discount'), // Diskon hardcoded 0 dulu
          _summaryRow('Pajak (0%)', 'Rp $tax'), // Pajak hardcoded 0 dulu
          const Divider(color: Color.fromARGB(255, 255, 255, 255)),
          _summaryRow('Total', 'Rp $total', isTotal: true),
        ],
      ),
    );
  }
}
