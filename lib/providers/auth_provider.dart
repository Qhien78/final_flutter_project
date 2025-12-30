import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // MỚI
import '../data/db/database_helper.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isDarkMode = false; // MỚI: Trạng thái Theme

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isDarkMode => _isDarkMode;

  // Khởi tạo: Load Theme từ bộ nhớ
  AuthProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Reload user để cập nhật số dư
  Future<void> reloadUser() async {
    if (_currentUser != null) {
      final updatedUser = await DatabaseHelper.instance.getUserById(_currentUser!.id!);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    final user = await DatabaseHelper.instance.login(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    String cardId = "LIB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    final newUser = User(
        username: username,
        password: password,
        role: 'customer',
        libraryCardId: cardId,
        balance: 0.0 // Tặng 0 đồng khởi nghiệp
    );
    try {
      await DatabaseHelper.instance.register(newUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}