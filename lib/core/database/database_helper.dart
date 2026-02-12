import 'package:pos_inventory/models/pending_transaction.dart';
import 'package:pos_inventory/models/transaction_detail.dart';
import 'package:pos_inventory/models/product_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT,
      name TEXT,
      price REAL,
      stock INTEGER,
      category TEXT
    )
    ''');

    // Tambahkan tabel transactions dan transaction_items di sini
    // agar fresh install langsung memiliki tabel lengkap
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trx_code TEXT NOT NULL,
        cashier_id TEXT,
        cashier_name TEXT,
        created_at TEXT,
        total_amount INTEGER,
        received_money INTEGER,
        change INTEGER,
        payment_method TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        product_id INTEGER,
        product_name TEXT,
        price INTEGER,
        qty INTEGER,
        subtotal INTEGER,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trx_code TEXT NOT NULL,
          cashier_id TEXT,
          cashier_name TEXT,
          created_at TEXT,
          total_amount INTEGER,
          received_money INTEGER,
          change INTEGER,
          payment_method TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE transaction_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER,
          product_id INTEGER,
          product_name TEXT,
          price INTEGER,
          qty INTEGER,
          subtotal INTEGER,
          FOREIGN KEY (transaction_id) REFERENCES transactions(id)
        )
      ''');
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()], // Hapus spasi tidak sengaja saat pencarian
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Product.fromMap(result.first);
  }

  Future<void> saveTransaction({
    required PendingTransaction trx,
    required int receivedMoney,
    required int change,
    required String paymentMethod,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      //insert tabel transaction
      final trxId = await txn.insert('transactions', {
        'trx_code': trx.trxCode,
        'cashier_id': trx.cashierId,
        'cashier_name': trx.cashierName,
        'created_at': trx.createdAt.toIso8601String(),
        'total_amount': trx.totalAmount,
        'received_money': receivedMoney,
        'change': change,
        'payment_method': paymentMethod,
      });

      for (final item in trx.items) {
        await txn.insert('transaction_items', {
          'transaction_id': trxId,
          'product_id': item.productId,
          'product_name': item.productName,
          'price': item.price,
          'qty': item.qty,
          'subtotal': item.subtotal,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.qty, item.productId],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
  }

  Future<Transactionfinal?> getTransactionDetail(String trxCode) async {
    final db = await database;

    // 🔹 1. Ambil header
    final headerResult = await db.query(
      'transactions',
      where: 'trx_code = ?',
      whereArgs: [trxCode],
    );

    if (headerResult.isEmpty) return null;

    final header = TransactionDetail.fromMap(headerResult.first);

    // 🔹 2. Ambil semua item transaksi
    final itemResult = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [header.id],
    );

    final items = itemResult.map((e) => TransactionDetailItems.fromMap(e)).toList();

    // 🔹 3. Gabungkan
    return Transactionfinal(header: header, items: items);
  }
}
