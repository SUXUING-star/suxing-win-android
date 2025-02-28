import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';

class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = true;
  bool _disposed = false;

  AuthProvider() {
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get userId => _currentUser?.id;

  Future<void> _init() async {
    if (_disposed) return;

    try {
      final userId = await _userService.currentUserId;
      if (_disposed) return;  // 再次检查，以防在获取userId期间被dispose

      if (userId != null) {
        _currentUser = await _userService.getCurrentUser();
        if (_disposed) return;  // 再次检查，以防在获取用户信息期间被dispose
      }
    } catch (e) {
      print('Error initializing auth state: $e');
      if (!_disposed) {
        _currentUser = null;
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    if (_disposed) return;

    try {
      _currentUser = await _userService.signIn(email, password);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      print('Sign in error in AuthProvider: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_disposed) return;

    await _userService.signOut();
    if (!_disposed) {
      _currentUser = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}