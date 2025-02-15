import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final UserService _authService = UserService();
  User? _currentUser;
  bool _isLoading = true;

  AuthProvider() {
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get userId => _currentUser?.id;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _authService.currentUserId;
      if (userId != null) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      print('Error initializing auth state: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _currentUser = await _authService.signIn(email, password);
      notifyListeners();
    } catch (e) {
      print('Sign in error in AuthProvider: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}