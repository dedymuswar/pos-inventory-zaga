import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class DashboardController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<DashboardData> loadDashboard() async {
    final database = await _db.database;
    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);

    final today = await _rangeSummary(
      database: database,
      start: todayStart,
      end: tomorrowStart,
    );
    final yesterday = await _rangeSummary(
      database: database,
      start: yesterdayStart,
      end: todayStart,
    );
    final month = await _rangeSummary(
      database: database,
      start: monthStart,
      end: nextMonthStart,
    );
    final previousMonth = await _rangeSummary(
      database: database,
      start: prevMonthStart,
      end: monthStart,
    );

    final topProductsRaw = await database.rawQuery('''
      SELECT
        product_name,
        SUM(qty) as sold_qty,
        SUM(subtotal) as sold_total
      FROM transaction_items
      GROUP BY product_name
      ORDER BY sold_qty DESC, sold_total DESC
      LIMIT 5
    ''');

    final criticalStockRaw = await database.rawQuery('''
      SELECT
        name,
        category,
        stock,
        price
      FROM products
      ORDER BY
        CASE WHEN stock <= 10 THEN 0 ELSE 1 END,
        stock ASC,
        name ASC
      LIMIT 10
    ''');

    final inventoryRaw = await database.rawQuery('''
      SELECT COALESCE(SUM(stock * price), 0) as total_inventory_value
      FROM products
    ''');

    final topProducts = topProductsRaw
        .map(
          (row) => TopProduct(
            name: (row['product_name'] ?? '-').toString(),
            soldQty: _toInt(row['sold_qty']),
            soldTotal: _toDouble(row['sold_total']),
          ),
        )
        .toList();

    final criticalStocks = criticalStockRaw
        .map(
          (row) => CriticalStockItem(
            name: (row['name'] ?? '-').toString(),
            category: (row['category'] ?? '-').toString(),
            stock: _toInt(row['stock']),
            price: _toDouble(row['price']),
          ),
        )
        .toList();

    return DashboardData(
      today: today,
      yesterday: yesterday,
      month: month,
      previousMonth: previousMonth,
      topProducts: topProducts,
      criticalStocks: criticalStocks,
      inventoryValue: _toDouble(inventoryRaw.first['total_inventory_value']),
    );
  }

  Future<SalesSummary> _rangeSummary({
    required Database database,
    required DateTime start,
    required DateTime end,
  }) async {
    final txRaw = await database.rawQuery(
      '''
      SELECT
        COALESCE(COUNT(*), 0) as trx_count,
        COALESCE(SUM(total_amount), 0) as total_sales
      FROM transactions
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    final itemRaw = await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(ti.qty), 0) as sold_items
      FROM transaction_items ti
      INNER JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.created_at >= ? AND t.created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return SalesSummary(
      transactions: _toInt(txRaw.first['trx_count']),
      salesAmount: _toDouble(txRaw.first['total_sales']),
      soldItems: _toInt(itemRaw.first['sold_items']),
    );
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DashboardData {
  DashboardData({
    required this.today,
    required this.yesterday,
    required this.month,
    required this.previousMonth,
    required this.topProducts,
    required this.criticalStocks,
    required this.inventoryValue,
  });

  final SalesSummary today;
  final SalesSummary yesterday;
  final SalesSummary month;
  final SalesSummary previousMonth;
  final List<TopProduct> topProducts;
  final List<CriticalStockItem> criticalStocks;
  final double inventoryValue;
}

class SalesSummary {
  SalesSummary({
    required this.transactions,
    required this.salesAmount,
    required this.soldItems,
  });

  final int transactions;
  final double salesAmount;
  final int soldItems;
}

class TopProduct {
  TopProduct({
    required this.name,
    required this.soldQty,
    required this.soldTotal,
  });

  final String name;
  final int soldQty;
  final double soldTotal;
}

class CriticalStockItem {
  CriticalStockItem({
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
  });

  final String name;
  final String category;
  final int stock;
  final double price;
}
