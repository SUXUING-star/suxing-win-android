// lib/providers/auth/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 保留，可能其他地方用到
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

  // ... (其他代码，包括 _internal, initialize, _userService, _currentUser, isLoading 状态等保持不变) ...
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isInitializing = true;
  bool _isRefreshing = false;
  bool _initialized = false;
  StreamSubscription? _userProfileSubscription;
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

  // 公共初始化方法
  Future<void> initialize() async {
    if (_initialized) return;
    await _initializationLock.synchronized(() async {
      if (_initialized) return;
      print("AuthProvider: Initializing...");
      _isInitializing = true;
      notifyListeners();
      try {
        final savedUserId = await _userService.currentUserId;
        if (savedUserId != null && savedUserId.isNotEmpty) {
          try {
            _currentUser = await _userService.getCurrentUser();
            _subscribeToUserProfile();
          } catch (e) {
            print("AuthProvider: Failed to get current user during init: $e");
            _currentUser = null;
            await _userService.clearAuthData();
          }
        } else {
          _currentUser = null;
        }
      } catch (e) {
        print("AuthProvider: Error during initialization: $e");
        _currentUser = null;
      } finally {
        _isInitializing = false;
        _initialized = true;
        print("AuthProvider: Initialization finished. User: ${_currentUser?.username}");
        notifyListeners();
      }
    });
  }

  void _subscribeToUserProfile() {
    _userProfileSubscription?.cancel();
    // 假设 _userService.getCurrentUserProfile() 返回 Stream<User?>
    try {
      _userProfileSubscription = _userService.getCurrentUserProfile().listen(
              (User? updatedUser) {
            // 优化：仅在数据实际改变时通知
            bool changed = false;
            if (_currentUser?.id != updatedUser?.id ||
                _currentUser?.username != updatedUser?.username ||
                _currentUser?.avatar != updatedUser?.avatar ||
                _currentUser?.isAdmin != updatedUser?.isAdmin ||
                _currentUser?.isSuperAdmin != updatedUser?.isSuperAdmin)
            {
              changed = true;
            }

            if (changed) {
              _currentUser = updatedUser; // 更新为 null 或新用户
              print("AuthProvider: User profile updated via stream. New user: ${_currentUser?.username}");
              notifyListeners();
            } else if (_currentUser != null && updatedUser == null){
              // 处理从有用户变为无用户的情况（虽然上面逻辑已包含）
              _currentUser = null;
              print("AuthProvider: User profile updated via stream. User set to null.");
              notifyListeners();
            }
          },
          onError: (e) {
            print("AuthProvider: Error in user profile stream: $e");
            // 根据错误类型决定是否登出用户
            // 例如，如果是权限错误，可能需要登出
            // if (isPermissionError(e)) {
            //   _currentUser = null;
            //   _userService.clearAuthData();
            //   notifyListeners();
            // }
          }
      );
    } catch (e) {
      print("AuthProvider: Failed to subscribe to user profile: $e");
    }
  }

  Future<void> signIn(String email, String password) async {
    // 不需要 _isLoading 状态，让调用者处理 UI
    try {
      _currentUser = await _userService.signIn(email, password);
      _subscribeToUserProfile(); // 登录成功后开始监听
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Sign in failed: $e");
      _currentUser = null; // 确保登录失败时用户为空
      notifyListeners(); // 通知UI状态已清除
      rethrow; // 将异常抛出给调用者处理
    }
  }

  // *** 改回原来的 signOut 接口，不需要 BuildContext ***
  Future<void> signOut() async {
    // 可能需要一个加载状态，但暂时移除，保持接口干净
    // _isRefreshing = true;
    // notifyListeners();
    try {
      // *** 这里是关键改动 ***
      // 尝试直接创建 AnnouncementService 实例来调用 reset
      // 这假设 AnnouncementService 的 reset 方法不依赖于特定的实例状态
      // 并且 AnnouncementService 可以被这样实例化。
      // 如果 AnnouncementService 是单例或需要 Provider 注入，这可能需要调整。
      // 这是一个常见的折衷方案，以避免修改 signOut 接口。
      try {
        final announcementService = AnnouncementService(); // 直接创建实例
        await announcementService.reset();
        print("AuthProvider: AnnouncementService reset called successfully.");
      } catch (e) {
        print("AuthProvider: Failed to reset AnnouncementService during sign out: $e");
        // 这个失败通常不应该阻止登出流程
      }

      // 继续执行登出
      await _userService.signOut();
      _userProfileSubscription?.cancel(); // 取消监听
      _userProfileSubscription = null;
      _currentUser = null; // 清除本地用户状态

    } catch (e) {
      print("AuthProvider: Error during sign out: $e");
      // 即使 UserService 的 signOut 失败，也要确保本地状态被清除
      _userProfileSubscription?.cancel();
      _userProfileSubscription = null;
      _currentUser = null;
    } finally {
      // _isRefreshing = false; // 如果使用加载状态，在这里结束
      notifyListeners(); // 最终通知 UI 用户已登出
    }
  }

  // 刷新用户状态
  Future<void> refreshUserState() async {
    if (_isInitializing || _isRefreshing) return;
    if (!_initialized) {
      print("AuthProvider: refreshUserState called before initialized. Calling initialize()...");
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
          _subscribeToUserProfile();
        } catch (e) {
          print("AuthProvider: Refresh - Failed to get current user: $e");
          _currentUser = null;
          await _userService.clearAuthData();
          _userProfileSubscription?.cancel();
          _userProfileSubscription = null;
        }
      } else {
        _currentUser = null;
        _userProfileSubscription?.cancel();
        _userProfileSubscription = null;
      }
    } catch (e) {
      print("AuthProvider: Refresh - Error during refresh: $e");
      _currentUser = null;
      _userProfileSubscription?.cancel();
      _userProfileSubscription = null;
    } finally {
      _isRefreshing = false;
      print("AuthProvider: Refresh finished. User: ${_currentUser?.username}");
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