class TransactionModel {
  final int id;
  final String trxCode;
  final String date;
  final double total_amount;

  TransactionModel({
    required this.id,
    required this.trxCode,
    required this.date,
    required this.total_amount
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      trxCode: map['trx_code'],
      date: map['created_at'] ?? '',
      total_amount: (map['total_amount'] as num).toDouble(),
    );
  }
  
}