import 'package:flutter/material.dart';
import 'package:pos_inventory/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final List<AppUser> _users = [
    AppUser(
      id: '1',
      username: 'admin',
      password: 'admin',
      role: UserRole.admin,
    ),
    AppUser(
      id: '2',
      username: 'kasir',
      password: 'kasir',
      role: UserRole.kasir,
    ),
  ];

  AppUser? _currentUser;

  List<AppUser> get user => List.unmodifiable(_users);
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  String? login(String username, String password) {
    try {
      final user = _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Username atau password salah';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  String? addUser({
    required String username,
    required String password,
    required UserRole role,
  }) {
    final exists = _users.any((user) => user.username == username);
    if (exists) {
      return 'Username sudah digunakan';
    }
    _users.add(
      AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        role: role,
      ),
    );
    notifyListeners();
    return null;
  }

  String? editUser({
    required String id,
    required String username,
    required String password,
    required UserRole role,
  }) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      return 'User tidak ditemukan';
    }

    // Cek duplikat username pada user lain (yang id-nya berbeda)
    final duplicate = _users.any((user) => user.username == username && user.id != id);
    if (duplicate) {
      return 'Username sudah digunakan';
    }
    _users[index] = _users[index].copyWith(
      username: username,
      password: password,
      role: role,
    );

    if (_currentUser?.id == id) {
      _currentUser = _users[index];
    }
    notifyListeners();
    return null;
  }

  void deleteUser(String id) {
    _users.removeWhere((user) => user.id == id);
    if (_currentUser?.id == id) {
      _currentUser = null;
    }
    notifyListeners();
  }
}
