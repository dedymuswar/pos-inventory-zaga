import 'package:pos_inventory/features/cart/model/cart_item.dart';

class PendingTransaction {
  final String trxCode;
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;
  final List<PendingTransactionItem> items;
  final int totalAmount;

  PendingTransaction({
    required this.trxCode,
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
  });
}

class PendingTransactionItem {
  final int productId;
  final String productName;
  final int price;
  final int qty;
  final int subtotal;

  PendingTransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });
}