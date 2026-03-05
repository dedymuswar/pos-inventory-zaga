import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthController extends ChangeNotifier {
  List<AppUser> _users = [];

  AppUser? _currentUser;

  List<AppUser> get user => List.unmodifiable(_users);
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> loadUsers() async {
    DatabaseHelper db = DatabaseHelper.instance;
    final rows = await db.getAllUsers();
    _users = rows.map((row) {
      return AppUser(
        id: row['id'].toString(),
        username: row['username'] as String,
        password: row['password'] as String,
        role: (row['role'] == 'admin') ? UserRole.admin : UserRole.kasir,
      );
    }).toList();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    DatabaseHelper db = DatabaseHelper.instance;
    try {
      final row = await db.loginUser(
        username: username.trim(),
        password: password.trim(),
      );
      if (row == null) return false;

      _currentUser = AppUser(
        id: row['id'].toString(),
        username: row['username'] as String,
        password: row['password'] as String,
        role: (row['role'] == 'admin') ? UserRole.admin : UserRole.kasir,
      );
      notifyListeners();
      return true;
    } on DatabaseException catch (e, st) {
      debugPrint('Database login error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    } catch (e, st) {
      debugPrint('Unexpected login error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> addUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    DatabaseHelper db = DatabaseHelper.instance;
    try {
      await db.insertUser(
        username: username,
        password: password,
        role: role.name,
      );
      await loadUsers();
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return 'Username sudah digunakan';
      return 'Gagal menambah user';
    }
  }

  Future<String?> editUser({
    required String id,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    try {
      DatabaseHelper db = DatabaseHelper.instance;
      await db.updateUser(
        id: int.parse(id),
        username: username,
        password: password,
        role: role.name,
      );

      if (_currentUser?.id == id) {
        _currentUser = _currentUser!.copyWith(
          username: username.trim(),
          password: password.trim(),
          role: role,
        );
      }

      await loadUsers();
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return 'Username sudah digunakan';
      return 'Gagal mengubah user';
    }
  }

  Future<void> deleteUser(String id) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.deleteUser(int.parse(id));
    if (_currentUser?.id == id) _currentUser = null;
    await loadUsers();
  }
}
