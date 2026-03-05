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
      version: 6,
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
        cashier_id INTEGER,
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

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        qty INTEGER NOT NULL,
        source TEXT NOT NULL,
        reference TEXT,
        actor_name TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL
        )
      ''');

    await seedDefaultUsers(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trx_code TEXT NOT NULL,
          cashier_id INTEGER,
          created_at TEXT,
          total_amount INTEGER,
          received_money INTEGER,
          change INTEGER,
          payment_method TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_items (
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

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          qty INTEGER NOT NULL,
          source TEXT NOT NULL,
          reference TEXT,
          actor_name TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL
        )
      ''');
      await seedDefaultUsers(db);
    }
    if (oldVersion < 5) {
      // Recovery migration: older builds may have version metadata updated
      // without creating users table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL
        )
      ''');
      await seedDefaultUsers(db);
    }
    if (oldVersion < 6) {
      final columns = await db.rawQuery('PRAGMA table_info(stock_movements)');
      final hasActorName = columns.any(
        (column) => column['name'] == 'actor_name',
      );
      if (!hasActorName) {
        await db.execute(
          'ALTER TABLE stock_movements ADD COLUMN actor_name TEXT',
        );
      }
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
      // Validasi cashier_id untuk transaksi OUT (sale)
      if (trx.cashierId.trim().isEmpty) {
        throw Exception('cashier_id wajib untuk transaksi OUT');
      }

      final cashierId = int.tryParse(trx.cashierId);
      if (cashierId == null) {
        throw Exception('cashier_id harus berupa angka valid');
      }

      //insert tabel transaction
      final trxId = await txn.insert('transactions', {
        'trx_code': trx.trxCode,
        'cashier_id': cashierId,
        'created_at': trx.createdAt.toIso8601String(),
        'total_amount': trx.totalAmount,
        'received_money': receivedMoney,
        'change': change,
        'payment_method': paymentMethod,
      });

      for (final item in trx.items) {
        final productResult = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (productResult.isEmpty) {
          throw Exception('Produk dengan id ${item.productId} tidak ditemukan');
        }

        final currentStock = (productResult.first['stock'] as int?) ?? 0;
        if (currentStock < item.qty) {
          throw Exception(
            'Stok tidak cukup untuk produk ${item.productName}. '
            'Tersedia: $currentStock, diminta: ${item.qty}',
          );
        }

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

        await txn.insert('stock_movements', {
          'product_id': item.productId,
          'type': 'OUT',
          'qty': item.qty,
          'source': 'SALE',
          'reference': trx.trxCode,
          'actor_name': trx.cashierName,
          'created_at': trx.createdAt.toIso8601String(),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
  }

  Future<Transactionfinal?> getTransactionDetail(String trxCode) async {
    final db = await database;

    // Ambil header transaksi + nama kasir jika tersedia
    final headerResult = await db.rawQuery(
      '''
      SELECT
        t.id,
        t.trx_code,
        t.cashier_id,
        u.username AS cashier_name,
        t.created_at,
        t.total_amount,
        t.received_money,
        t.change,
        t.payment_method
      FROM transactions t
      LEFT JOIN users u ON u.id = t.cashier_id
      WHERE t.trx_code = ?
      LIMIT 1
      ''',
      [trxCode],
    );

    if (headerResult.isEmpty) return null;

    final header = TransactionDetail.fromMap(headerResult.first);

    // 🔹 2. Ambil semua item transaksi
    final itemResult = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [header.id],
    );

    final items = itemResult
        .map((e) => TransactionDetailItems.fromMap(e))
        .toList();

    // 🔹 3. Gabungkan
    return Transactionfinal(header: header, items: items);
  }

  Future<void> seedDefaultUsers(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );

    if (count == 0) {
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin',
        'role': 'admin',
      });

      await db.insert('users', {
        'username': 'kasir',
        'password': 'kasir',
        'role': 'kasir',
      });
    }
  }

  Future<Map<String, dynamic>?> loginUser({
    required String username,
    required String password,
  }) async {
    final db = await database;
    final safeUsername = username.trim();
    final safePassword = password.trim();
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [safeUsername, safePassword],
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> insertUser({
    required String username,
    required String password,
    required String role, // 'admin' / 'kasir'
  }) async {
    final db = await database;
    return db.insert('users', {
      'username': username.trim(),
      'password': password.trim(),
      'role': role,
    });
  }

  Future<int> updateUser({
    required int id,
    required String username,
    required String password,
    required String role,
  }) async {
    final db = await database;
    return db.update(
      'users',
      {'username': username.trim(), 'password': password.trim(), 'role': role},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
