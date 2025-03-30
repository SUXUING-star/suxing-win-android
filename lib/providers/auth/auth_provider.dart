// lib/providers/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import '../../services/main/announcement/announcement_service.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  // 静态实例，确保全局唯一
  static final AuthProvider _singleton = AuthProvider._internal();

  // 工厂构造函数，始终返回同一个实例
  factory AuthProvider() {
    return _singleton;
  }

  // 私有构造函数
  AuthProvider._internal() {
    _init();
  }

  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = true;
  bool _initialized = false;

  StreamSubscription? _userProfileSubscription;

  // 重要：添加一个初始化锁，防止并发初始化
  final _initializationLock = Lock();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get currentUserId => _currentUser?.id;

  Future<void> _init() async {
    // 使用锁确保只初始化一次
    await _initializationLock.synchronized(() async {
      if (_initialized) return;

      try {
        final savedUserId = await _userService.currentUserId;

        if (savedUserId != null && savedUserId.isNotEmpty) {
          try {
            _currentUser = await _userService.getCurrentUser();
            _subscribeToUserProfile();
          } catch (e) {
            _currentUser = null;
          }
        }
      } catch (e) {
        _currentUser = null;
      } finally {
        _isLoading = false;
        _initialized = true;
        notifyListeners();
      }
    });
  }

  void _subscribeToUserProfile() {

    _userProfileSubscription?.cancel();

    _userProfileSubscription = _userService.getCurrentUserProfile().listen(
            (User? updatedUser) {
          if (updatedUser != null) {
            final bool shouldNotify = _currentUser == null ||
                _currentUser?.username != updatedUser.username ||
                _currentUser?.avatar != updatedUser.avatar ||
                _currentUser?.isAdmin != updatedUser.isAdmin ||
                _currentUser?.isSuperAdmin != updatedUser.isSuperAdmin;

            if (shouldNotify) {
              _currentUser = updatedUser;
              notifyListeners();
            }
          } else if (_currentUser != null) {
            _currentUser = null;
            notifyListeners();
          }
        },
        onError: (e) {
          // 处理错误
        }
    );
  }

  Future<void> signIn(String email, String password) async {
    try {
      _currentUser = await _userService.signIn(email, password);
      _subscribeToUserProfile();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final announcementService = AnnouncementService();
      await announcementService.reset();

      await _userService.signOut();
      _userProfileSubscription?.cancel();
      _userProfileSubscription = null;

      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> refreshUserState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUserId = await _userService.currentUserId;
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          _currentUser = await _userService.getCurrentUser();
          _subscribeToUserProfile();
        } catch (e) {
          _currentUser = null;
          await _userService.clearAuthData();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    _userProfileSubscription = null;
    super.dispose();
  }
}

// 新增：简单的同步锁类
class Lock {
  bool _isLocked = false;
  final List<Completer<void>> _queue = [];

  Future<T> synchronized<T>(Future<T> Function() action) async {
    if (_isLocked) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _isLocked = true;
    try {
      return await action();
    } finally {
      _isLocked = false;
      if (_queue.isNotEmpty) {
        final nextCompleter = _queue.removeAt(0);
        nextCompleter.complete();
      }
    }
  }
}