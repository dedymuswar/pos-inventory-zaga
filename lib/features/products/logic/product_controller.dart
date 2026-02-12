
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
}