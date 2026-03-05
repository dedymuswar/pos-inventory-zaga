class StockMovement {
  final int? id;
  final int productId;
  final String type;
  final int qty;
  final String source;
  final String? reference;
  final String? actorName;
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.type,
    required this.qty,
    required this.source,
    this.reference,
    this.actorName,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> map) {
    return StockMovement(
      id : map['id'] as int?,
      productId: map['product_id'] as int,
      type: map['type'] as String,
      qty: map['qty'] as int,
      source: map['source'] as String,
      reference: map['reference'] as String?,
      actorName: map['actor_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }



}
