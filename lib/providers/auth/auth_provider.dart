// lib/providers/auth/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 保留，可能其他地方用到
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/models/user/account.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isInitializing = false;
  bool _isRefreshing = false;
  bool _initialized = false;
  final _initializationLock = Lock();

  StreamSubscription? _unauthorizedSubscription;

  final Duration _refreshNotifyDelay = const Duration(milliseconds: 500);
  final Duration _signInNotifyDelay = const Duration(milliseconds: 1000);
  final Duration _signOutNotifyDelay = const Duration(milliseconds: 1000);

  User? get currentUser => _currentUser;
  bool get isInitializing => _isInitializing;
  bool get isRefreshing => _isRefreshing;
  bool get isLoading => _isInitializing || _isRefreshing;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get currentUserId => _currentUser?.id;

  final UserService _userService;
  AuthProvider(this._userService) {
    // 监听事件放在构造函数里执行
    _listenForUnauthorizedEvent();
  }
  void _listenForUnauthorizedEvent() {
    // 确保只监听一次
    if (_unauthorizedSubscription != null) return;
    _unauthorizedSubscription =
        appEventBus.on<UnauthorizedAccessEvent>().listen((event) {
      // 检查当前是否确实是登录状态，避免不必要的通知
      if (_currentUser != null) {
        _currentUser = null;
        notifyListeners(); // 通知 UI 更新 (非常重要！)
      }
    });
  }

  //公共初始化方法
  Future<void> initialize() async {
    if (_initialized || _isInitializing) return;

    await _initializationLock.synchronized(() async {
      if (_initialized || _isInitializing) return;

      _isInitializing = true;

      User? determinedUser;

      try {
        final String? token = await _userService.getToken();

        if (token == null) {
          determinedUser = null;
          // Assuming userService.getToken() already cleared data if expired
        } else {
          final savedUserId = await _userService.currentUserId;
          if (savedUserId != null && savedUserId.isNotEmpty) {
            try {
              determinedUser = await _userService.getCurrentUser();
            } catch (e) {
              determinedUser = null;
              // Consider specific error handling, e.g., logging 'e'
            }
          } else {
            determinedUser = null;
            await _userService.clearAuthData(); // Clear inconsistent state
          }
        }
      } catch (e) {
        determinedUser = null;
        try {
          await _userService.clearAuthData();
        } catch (_) {}
        // Consider specific error handling, e.g., logging 'e'
      } finally {
        _currentUser = determinedUser;
        _isInitializing = false;
        _initialized = true;
        notifyListeners();
      }
    });
  }
  // 公共初始化方法

  Future<void> signIn(String email, String password,SavedAccount? account) async {
    // 不需要 _isLoading 状态，让调用者处理 UI
    try {
      _currentUser = await _userService.signIn(email, password,account);
      await Future.delayed(_signInNotifyDelay);
      if (_currentUser != null) {
        // 再次确认用户非空（虽然理论上是的）
        notifyListeners(); // 通知 UI 登录状态已更新
      } else {}
    } catch (e) {
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
    } catch (e) {
      _currentUser = null;
      // 可以选择性地 rethrow(e) 或处理错误
    } finally {
      await Future.delayed(_signOutNotifyDelay);
      // 最终确保通知 UI 更新
      notifyListeners();
    }
  }

  // 刷新用户状态
  Future<void> refreshUserState() async {
    if (_isInitializing || _isRefreshing) return;
    if (!_initialized) {
      await initialize();
      return;
    }

    _isRefreshing = true;
    await Future.delayed(_refreshNotifyDelay);
    notifyListeners();

    try {
      final savedUserId = await _userService.currentUserId;
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          _currentUser = await _userService.getCurrentUser();
          // 如果之前没有订阅成功，或者为了确保，重新订阅
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
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future getAuthToken() {
    return _userService.getToken();
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.cancel();
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
