// lib/providers/auth/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 保留，可能其他地方用到
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  // 静态实例，确保全局唯一
  static final AuthProvider _singleton = AuthProvider._internal();

  // 工厂构造函数，始终返回同一个实例
  factory AuthProvider() {
    return _singleton;
  }

  final UserService _userService = UserService();
  User? _currentUser;
  bool _isInitializing = false;
  bool _isRefreshing = false;
  bool _initialized = false;
  final _initializationLock = Lock();

  User? get currentUser => _currentUser;
  bool get isInitializing => _isInitializing;
  bool get isRefreshing => _isRefreshing;
  bool get isLoading => _isInitializing || _isRefreshing;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get currentUserId => _currentUser?.id;

  // 私有构造函数
  AuthProvider._internal() {
    // 初始化逻辑在 initialize() 中
  }

  //公共初始化方法
  Future<void> initialize() async {
    if (_initialized || _isInitializing) return;
    await _initializationLock.synchronized(() async {
      if (_initialized || _isInitializing) return;
      print("AuthProvider: Initializing...");
      _isInitializing = true;
      notifyListeners(); // UI 显示加载
      try {
        final savedUserId = await _userService.currentUserId; // 1. 读 UserId
        if (savedUserId != null && savedUserId.isNotEmpty) {
          try {
            // 2. 尝试用 Future 获取 User
            _currentUser = await _userService.getCurrentUser();
          } catch (e) {
            _currentUser = null;
            // *** 原始版本这里会清除 Token ***
            await _userService.clearAuthData();

          }
        } else {
          _currentUser = null; // 本地无 UserId
        }
      } catch (e) {
        print("AuthProvider: Error during outer initialization steps: $e");
        _currentUser = null;
      } finally {
        // *** 关键点：finally 块总会执行 ***
        _isInitializing = false;
        _initialized = true;
        print(
            "AuthProvider: Initialization finally block. Final user state before notify: ${_currentUser?.username}");
        notifyListeners(); // *** 最后的通知 ***
      }
    });
  }
  // 公共初始化方法

  Future<void> signIn(String email, String password) async {
    // 不需要 _isLoading 状态，让调用者处理 UI
    try {
      _currentUser = await _userService.signIn(email, password);
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Sign in failed: $e");
      _currentUser = null; // 确保登录失败时用户为空
      notifyListeners(); // 通知UI状态已清除
      rethrow; // 将异常抛出给调用者处理
    }
  }

  // In AuthProvider
  Future<void> signOut() async {
    try {
      // 完全委托给 UserService 处理登出逻辑和事件发布
      await _userService.signOut();

      _currentUser = null;
      print(
          "AuthProvider: State cleared after successful user service sign out.");
    } catch (e) {
      print("AuthProvider: Error during sign out delegation: $e");
      _currentUser = null;
      print(
          "AuthProvider: State cleared despite error during sign out delegation.");
      // 可以选择性地 rethrow(e) 或处理错误
    } finally {
      // 最终确保通知 UI 更新
      notifyListeners();
    }
  }

  // 刷新用户状态
  Future<void> refreshUserState() async {
    if (_isInitializing || _isRefreshing) return;
    if (!_initialized) {
      print(
          "AuthProvider: refreshUserState called before initialized. Calling initialize()...");
      await initialize();
      return;
    }

    print("AuthProvider: Refreshing user state...");
    _isRefreshing = true;
    notifyListeners();

    try {
      final savedUserId = await _userService.currentUserId;
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          _currentUser = await _userService.getCurrentUser();
          // 如果之前没有订阅成功，或者为了确保，重新订阅
        } catch (e) {
          print("AuthProvider: Refresh - Failed to get current user: $e");
          _currentUser = null;
          await _userService.clearAuthData();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print("AuthProvider: Refresh - Error during refresh: $e");
      _currentUser = null;
    } finally {
      _isRefreshing = false;
      print("AuthProvider: Refresh finished. User: ${_currentUser?.username}");
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Lock 类保持不变
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
