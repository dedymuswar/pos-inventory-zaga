class TransactionDetail {
  final int id;
  final String trx_code;
  final int cashierId;
  final String? cashierName;
  final DateTime createdAt;
  final int total_amount;
  final int received_money;
  final int change;
  final String payment_method;

  TransactionDetail({
    required this.id,
    required this.trx_code,
    required this.cashierId,
    this.cashierName,
    required this.createdAt,
    required this.total_amount,
    required this.received_money,
    required this.change,
    required this.payment_method,
  });

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    final rawCashierId = map['cashier_id'];
    return TransactionDetail(
      id: map['id'],
      trx_code: map['trx_code'],
      cashierId: rawCashierId is int
          ? rawCashierId
          : int.tryParse(rawCashierId?.toString() ?? '') ?? 0,
      cashierName: map['cashier_name'],
      createdAt: DateTime.parse(map['created_at']),
      total_amount: map['total_amount'],
      received_money: map['received_money'],
      change: map['change'],
      payment_method: map['payment_method'],
    );
  }
}


class TransactionDetailItems {
  final int id;
  final int transaction_id;
  final int product_id;
  final String product_name;
  final int price;
  final int qty;
  final int subtotal;

  TransactionDetailItems({
    required this.id,
    required this.transaction_id,
    required this.product_id,
    required this.product_name,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  factory TransactionDetailItems.fromMap(Map<String, dynamic> map) {
    return TransactionDetailItems(
      id: map['id'],
      transaction_id: map['transaction_id'],
      product_id: map['product_id'],
      product_name: map['product_name'],
      price: map['price'],
      qty: map['qty'],
      subtotal: map['subtotal'],
    );
  }
}

class Transactionfinal {
  final TransactionDetail header;
  final List<TransactionDetailItems> items;

  Transactionfinal({
    required this.header,
    required this.items,
  });
}

