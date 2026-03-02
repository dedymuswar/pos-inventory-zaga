import 'package:pos_inventory/models/stock_movement.dart';
import 'package:sqflite/sqflite.dart';

class StockMovementRepository {
  final Database db;

  StockMovementRepository(this.db);

  Future<void> addMovement(StockMovement movement) async {
    await db.transaction((txn) async {
      // 1. insert ke tabel stock_movements
      await txn.insert('stock_movements', {
        'product_id': movement.productId,
        'type': movement.type,
        'qty': movement.qty,
        'source': movement.source,
        'reference': movement.reference,
        'created_at': movement.createdAt.toIso8601String(),
      });
    
      // 2. update stock di tabel products
      final stockChange = movement.type == 'IN' ? movement.qty : -movement.qty;

      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [stockChange, movement.productId],
      );
    
    });
  }
}