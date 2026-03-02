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
        reference: reference,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<StockMovement>> getStockMovement(int productId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'datetime(created_at) ASC, id DESC',
    );
    return result.map((e) => StockMovement.fromJson(e)).toList();
  }
}
