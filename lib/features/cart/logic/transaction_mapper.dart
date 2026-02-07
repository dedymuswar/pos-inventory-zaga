

import 'package:pos_inventory/features/cart/model/cart_item.dart';
import 'package:pos_inventory/features/payment/model/pending_transaction.dart';

class TransactionMapper {
  /// Mapping dari Cart → PendingTransaction
  static PendingTransaction fromCart({
    required List<CartItem> cartItems,
    required String cashierId,
    required String cashierName,
  }) {
    final now = DateTime.now();
    final trxCode = _generateTrxCode(now);

    final items = cartItems.map((item) {
      return PendingTransactionItem(
        productId: item.productId,
        productName: item.name,
        price: item.price,
        qty: item.qty,
        subtotal: item.total,
      );
    }).toList();

    final totalAmount =
        items.fold(0, (sum, item) => sum + item.subtotal);

    return PendingTransaction(
      trxCode: trxCode,
      cashierId: cashierId,
      cashierName: cashierName,
      createdAt: now,
      items: items,
      totalAmount: totalAmount,
    );
  }

  /// Generator kode transaksi
  static String _generateTrxCode(DateTime date) {
    final datePart =
        "${date.year.toString().substring(2)}"
        "${date.month.toString().padLeft(2, '0')}"
        "${date.day.toString().padLeft(2, '0')}";

    final random =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);

    return "TRX-$datePart-$random";
  }
}
