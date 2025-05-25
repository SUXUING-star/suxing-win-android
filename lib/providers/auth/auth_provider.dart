// lib/providers/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 仍然需要，因为 ChangeNotifier 依赖它
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isInitializing = false;
  bool _isRefreshing = false;
  bool _initialized = false;
  final _initializationLock = Lock();

  StreamSubscription? _unauthorizedSubscription;

  // --- Stream Controllers ---
  final _currentUserController = StreamController<User?>.broadcast();
  final _isLoggedInController = StreamController<bool>.broadcast();
  final _currentUserIdController = StreamController<String?>.broadcast();
  final _isInitializingController = StreamController<bool>.broadcast();
  final _isRefreshingController = StreamController<bool>.broadcast();
  final _isLoadingController = StreamController<bool>.broadcast();

  // --- Stream Getters ---
  Stream<User?> get currentUserStream => _currentUserController.stream;
  Stream<bool> get isLoggedInStream => _isLoggedInController.stream;
  Stream<String?> get currentUserIdStream => _currentUserIdController.stream;
  Stream<bool> get isInitializingStream => _isInitializingController.stream;
  Stream<bool> get isRefreshingStream => _isRefreshingController.stream;
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  final Duration _refreshNotifyDelay = const Duration(milliseconds: 500);
  final Duration _signInNotifyDelay = const Duration(milliseconds: 1000);
  final Duration _signOutNotifyDelay = const Duration(milliseconds: 1000);

  // --- Getters for initial state or non-stream access (仅用于确保初始值正确或极少数情况) ---
  User? get currentUser => _currentUser;
  bool get isInitializing => _isInitializing;
  bool get isRefreshing => _isRefreshing;
  bool get isLoading =>
      _isInitializing || _isRefreshing; // 这个 getter 仍然可以保留，用于内部逻辑或初始值
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get currentUserId => _currentUser?.id;

  final UserService _userService;

  AuthProvider(this._userService) {
    _listenForUnauthorizedEvent();
    // 初始化时，isLoading 可能为 true (如果 isInitializing 默认为 true)
    // 或者在 initialize 开始时设置
    _updateLoadingState(); // 确保 isLoadingStream 初始值正确
  }

  void _listenForUnauthorizedEvent() {
    if (_unauthorizedSubscription != null) return;
    _unauthorizedSubscription =
        appEventBus.on<UnauthorizedAccessEvent>().listen((event) {
      if (_currentUser != null) {
        _updateCurrentUser(null);
      }
    });
  }

  // --- Helper method to update user and notify streams ---
  void _updateCurrentUser(User? newUser) {
    final bool oldIsLoggedIn = _currentUser != null; // 直接比较
    final String? oldUserId = _currentUser?.id;

    _currentUser = newUser;

    _currentUserController.add(_currentUser);

    final bool newIsLoggedIn = _currentUser != null;
    if (newIsLoggedIn != oldIsLoggedIn) {
      _isLoggedInController.add(newIsLoggedIn);
    }
    if (_currentUser?.id != oldUserId) {
      _currentUserIdController.add(_currentUser?.id);
    }
    // notifyListeners(); // 保留以防万一，但如果所有UI都用Stream，可以考虑移除
  }

  // --- Helper methods for loading states ---
  void _setIsInitializing(bool value) {
    if (_isInitializing == value) return;
    _isInitializing = value;
    _isInitializingController.add(_isInitializing);
    _updateLoadingState();
    // notifyListeners(); // 同上
  }

  void _setIsRefreshing(bool value) {
    if (_isRefreshing == value) return;
    _isRefreshing = value;
    _isRefreshingController.add(_isRefreshing);
    _updateLoadingState();
    // notifyListeners(); // 同上
  }

  void _updateLoadingState() {
    _isLoadingController
        .add(isLoading); // isLoading getter 计算 _isInitializing || _isRefreshing
  }

  Future<void> initialize() async {
    if (_initialized || _isInitializing) return; // 防止重入

    await _initializationLock.synchronized(() async {
      if (_initialized || _isInitializing) return; // 再次检查锁内

      _setIsInitializing(true);

      User? determinedUser;
      try {
        final String? token = await _userService.getToken();
        if (token == null) {
          determinedUser = null;
          // userService.getToken() 应该已经处理了清除过期token的情况
        } else {
          final savedUserId = await _userService.currentUserId;
          if (savedUserId != null && savedUserId.isNotEmpty) {
            try {
              determinedUser = await _userService.getCurrentUser();
            } catch (e) {
              // 获取用户失败，可能token有效但用户数据有问题，或网络问题
              determinedUser = null;
              // 考虑记录错误 e
              // 此时不应该清除 token，除非确定 token 无效
            }
          } else {
            // 有 token 但没有 userId，数据不一致，清除
            determinedUser = null;
            await _userService.clearAuthData();
          }
        }
      } catch (e) {
        // 获取 token 或 userId 过程中发生异常
        determinedUser = null;
        try {
          await _userService.clearAuthData(); // 尝试清除认证数据
        } catch (_) {
          // 清除数据也失败，忽略
        }
        // 考虑记录错误 e
      } finally {
        _updateCurrentUser(determinedUser);
        _setIsInitializing(false); // ⭐ 更新 isInitializing 状态和 Stream
        _initialized = true; // 标记为已初始化
        // notifyListeners(); // _updateCurrentUser 和 _setIsInitializing 已处理
      }
    });
  }

  Future<void> signIn(String email, String password, bool rememberMe) async {
    // UI 可以通过 isLoadingStream 显示加载状态，这里不需要管理局部加载状态
    try {
      // 可以选择在 signIn 开始时设置一个特定于 signIn 的 loading 状态的 Stream (如果需要更细粒度)
      // 或者就依赖 initialize/refresh 的 isLoadingStream
      final user = await _userService.signIn(email, password, rememberMe);
      await Future.delayed(_signInNotifyDelay); // 模拟网络延迟或处理
      _updateCurrentUser(user);
    } catch (e) {
      _updateCurrentUser(null); // 确保登录失败时用户状态被清除
      rethrow; // 将异常抛给 UI 处理
    }
  }

  Future<void> signOut() async {
    // UI 可以通过 isLoadingStream (如果适用) 或其他方式显示加载状态
    try {
      await _userService.signOut(); // UserService 应该处理清除 token 和本地数据
      // UserService 也可能通过事件总线发出登出事件，但 AuthProvider 作为状态中心，自己更新最直接
      _updateCurrentUser(null); // 清除 AuthProvider 中的用户状态
    } catch (e) {
      // 登出失败，理论上本地状态也应该尝试清除
      _updateCurrentUser(null);
      // 可以选择性地 rethrow(e) 或记录错误
    } finally {
      await Future.delayed(_signOutNotifyDelay); // 模拟处理
      // _updateCurrentUser(null); // 已在 try/catch 中处理
    }
  }

  Future<void> refreshUserState() async {
    if (_isInitializing || _isRefreshing) return; // 防止重入
    if (!_initialized) {
      // 如果还未初始化，则执行初始化流程
      await initialize();
      return;
    }

    _setIsRefreshing(true); // ⭐ 更新 isRefreshing 状态和 Stream
    await Future.delayed(_refreshNotifyDelay); // 模拟延迟，给UI反应时间
    // notifyListeners(); // _setIsRefreshing 已处理

    try {
      final savedUserId = await _userService.currentUserId;
      User? refreshedUser; // 显式声明
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          refreshedUser = await _userService.getCurrentUser();
        } catch (e) {
          // 获取用户失败，可能意味着需要登出或清除本地数据
          refreshedUser = null;
          await _userService.clearAuthData(); // 清除认证数据
          // 考虑记录错误 e
        }
      } else {
        // 没有 savedUserId，意味着用户已登出或从未登录
        refreshedUser = null;
        // 确保本地数据也清除（userService.currentUserId 为空时，signOut/clearAuthData 可能已执行）
      }
      _updateCurrentUser(refreshedUser);
    } catch (e) {
      // 刷新过程中发生其他异常
      _updateCurrentUser(null); // 发生错误，清除用户状态
      // 考虑记录错误 e
    } finally {
      _setIsRefreshing(false); // ⭐ 更新 isRefreshing 状态和 Stream
      // notifyListeners(); // _setIsRefreshing 和 _updateCurrentUser 已处理
    }
  }

  Future<String?> getAuthToken() {
    // 返回 String? 更准确
    return _userService.getToken();
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.cancel();
    _currentUserController.close();
    _isLoggedInController.close();
    _currentUserIdController.close();
    _isInitializingController.close();
    _isRefreshingController.close();
    _isLoadingController.close(); // ⭐ 关闭 isLoadingController
    super.dispose();
  }
}

// Lock 类保持不变 (或者你也可以用 async 包里的 `Lock` )
class Lock {
  Completer<void>? _completer;

  Future<void> _lock() async {
    if (_completer != null) {
      await _completer!.future;
      return _lock(); // Re-check if another lock acquired it
    }
    _completer = Completer<void>();
  }

  void _unlock() {
    final completer = _completer;
    _completer = null;
    completer?.complete();
  }

  Future<T> synchronized<T>(Future<T> Function() action) async {
    await _lock();
    try {
      return await action();
    } finally {
      _unlock();
    }
  }
}
