import 'package:pos_inventory/models/stock_movement.dart';
import 'package:pos_inventory/repository/stock_movement_repository.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/product_model.dart';

class ProductService {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertProduct(Product product) async {
    final db = await dbHelper.database;
    await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await dbHelper.database;
    final result = await db.query('products');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> restockProduct({
    required int productId,
    required int qty,
    String? actorName,
    String? reference,
  }) async {
    if (qty <= 0) {
      throw Exception('Jumlah stok harus lebih dari 0');
    }

    final db = await dbHelper.database;
    StockMovementRepository stockMovementRepository = StockMovementRepository(
      db,
    );

    final parseQty = int.parse(qty.toString());

    await stockMovementRepository.addMovement(
      StockMovement(
        productId: productId,
        type: 'IN',
        qty: parseQty,
        source: 'RESTOCK',
        actorName: actorName,
        reference: reference,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<StockMovement>> getStockMovement(int productId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT
        sm.id,
        sm.product_id,
        sm.type,
        sm.qty,
        sm.source,
        sm.reference,
        sm.created_at,
        COALESCE(sm.actor_name, u.username) AS actor_name
      FROM stock_movements sm
      LEFT JOIN transactions t
        ON sm.source = 'SALE' AND t.trx_code = sm.reference
      LEFT JOIN users u
        ON u.id = t.cashier_id
      WHERE sm.product_id = ?
      ORDER BY datetime(sm.created_at) ASC, sm.id DESC
      ''',
      [productId],
    );
    return result.map((e) => StockMovement.fromJson(e)).toList();
  }
}
