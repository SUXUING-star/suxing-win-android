// lib/providers/auth/auth_provider.dart

/// 该文件定义了 AuthProvider，一个管理用户认证状态的 ChangeNotifier。
/// AuthProvider 负责处理用户的登录、登出、状态初始化和刷新。
/// 它提供相应的状态流供 UI 订阅。
///
/// AuthProvider 依赖 UserService 执行认证相关的API调用和本地数据存储。
library;


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ChangeNotifier 使用该包的功能
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'dart:async';

/// `AuthProvider` 类：管理用户认证状态的核心 Provider。
///
/// 该类通过 StreamController 提供状态更新。
class AuthProvider with ChangeNotifier {
  // --- 内部状态变量 ---
  User? _currentUser; // 当前登录用户的信息
  bool _isInitializing = false; // 认证模块初始化状态
  bool _isRefreshing = false; // 用户状态刷新状态
  bool _initialized = false; // 认证模块已完成首次初始化标记
  final _initializationLock = Lock(); // 用于保证 initialize 方法单次执行的锁

  StreamSubscription? _unauthorizedSubscription; // 监听未授权事件的订阅器

  // --- Stream 控制器 ---
  // 用于向监听者广播认证状态变化的 StreamController
  final _currentUserController =
      StreamController<User?>.broadcast(); // 广播当前用户状态
  final _isLoggedInController = StreamController<bool>.broadcast(); // 广播登录状态
  final _currentUserIdController =
      StreamController<String?>.broadcast(); // 广播当前用户ID
  final _isInitializingController =
      StreamController<bool>.broadcast(); // 广播初始化状态
  final _isRefreshingController = StreamController<bool>.broadcast(); // 广播刷新状态
  final _isLoadingController = StreamController<bool>.broadcast(); // 广播总体的加载状态

  // --- Stream 获取器 ---
  // 提供给 UI 订阅以获取实时状态更新的 Stream
  Stream<User?> get currentUserStream =>
      _currentUserController.stream; // 获取当前用户信息的 Stream
  Stream<bool> get isLoggedInStream =>
      _isLoggedInController.stream; // 获取登录状态的 Stream
  Stream<String?> get currentUserIdStream =>
      _currentUserIdController.stream; // 获取用户ID的 Stream
  Stream<bool> get isInitializingStream =>
      _isInitializingController.stream; // 获取初始化状态的 Stream
  Stream<bool> get isRefreshingStream =>
      _isRefreshingController.stream; // 获取刷新状态的 Stream
  Stream<bool> get isLoadingStream =>
      _isLoadingController.stream; // 获取总加载状态的 Stream

  // --- 延迟时间常量 ---
  // 用于模拟处理时间的延迟
  final Duration _refreshNotifyDelay =
      const Duration(milliseconds: 500); // 刷新操作的通知延迟
  final Duration _signInNotifyDelay =
      const Duration(milliseconds: 1000); // 登录操作的通知延迟
  final Duration _signOutNotifyDelay =
      const Duration(milliseconds: 1000); // 登出操作的通知延迟

  // --- 同步获取器 ---
  // 提供当前同步状态值。
  User? get currentUser => _currentUser; // 获取当前用户对象
  bool get isInitializing => _isInitializing; // 获取当前初始化状态
  bool get isRefreshing => _isRefreshing; // 获取当前刷新状态
  bool get isLoading => _isInitializing || _isRefreshing; // 获取总加载状态（初始化或刷新）
  bool get isLoggedIn => _currentUser != null; // 获取当前登录状态
  bool get isAdmin => _currentUser?.isAdmin ?? false; // 获取当前用户是否为管理员
  bool get isSuperAdmin =>
      _currentUser?.isSuperAdmin ?? false; // 获取当前用户是否为超级管理员
  String? get currentUserId => _currentUser?.id; // 获取当前用户ID

  final UserService _userService; // 依赖的用户服务实例

  /// 构造函数
  /// 接收一个 [UserService] 实例，并立即监听未授权事件。
  AuthProvider(this._userService) {
    _listenForUnauthorizedEvent(); // 订阅未授权事件
    _updateLoadingState(); // 初始化 isLoadingStream 的值
  }

  /// 监听 `UnauthorizedAccessEvent` 事件。
  /// 收到未授权事件时，清除当前用户状态。
  void _listenForUnauthorizedEvent() {
    if (_unauthorizedSubscription != null) return; // 避免重复订阅
    _unauthorizedSubscription =
        appEventBus.on<UnauthorizedAccessEvent>().listen((event) {
      if (_currentUser != null) {
        _updateCurrentUser(null); // 收到未授权事件，清除当前用户状态
      }
    });
  }

  /// 私有辅助方法：更新当前用户状态并通知所有相关的 Stream。
  ///
  /// [newUser]：新的用户对象，null 表示用户登出。
  void _updateCurrentUser(User? newUser) {
    final bool oldIsLoggedIn = _currentUser != null; // 记录旧的登录状态
    final String? oldUserId = _currentUser?.id; // 记录旧的用户ID

    _currentUser = newUser; // 更新内部用户对象

    _currentUserController.add(_currentUser); // 向 currentUserStream 广播新的用户对象

    final bool newIsLoggedIn = _currentUser != null;
    if (newIsLoggedIn != oldIsLoggedIn) {
      _isLoggedInController.add(newIsLoggedIn); // 如果登录状态改变，广播新的登录状态
    }
    if (_currentUser?.id != oldUserId) {
      _currentUserIdController.add(_currentUser?.id); // 如果用户ID改变，广播新的用户ID
    }
  }

  // --- 私有辅助方法：更新加载状态 ---
  /// 私有辅助方法：设置并广播 `_isInitializing` 状态。
  ///
  /// [value]：表示是否正在初始化。
  void _setIsInitializing(bool value) {
    if (_isInitializing == value) return; // 状态未改变则不处理
    _isInitializing = value; // 更新内部状态
    _isInitializingController.add(_isInitializing); // 广播初始化状态
    _updateLoadingState(); // 更新总加载状态
  }

  /// 私有辅助方法：设置并广播 `_isRefreshing` 状态。
  ///
  /// [value]：表示是否正在刷新。
  void _setIsRefreshing(bool value) {
    if (_isRefreshing == value) return; // 状态未改变则不处理
    _isRefreshing = value; // 更新内部状态
    _isRefreshingController.add(_isRefreshing); // 广播刷新状态
    _updateLoadingState(); // 更新总加载状态
  }

  /// 私有辅助方法：根据 `_isInitializing` 和 `_isRefreshing` 更新并广播总加载状态。
  void _updateLoadingState() {
    _isLoadingController.add(isLoading); // `isLoading` getter 计算状态
  }

  /// 初始化认证模块。
  ///
  /// 该方法在应用启动时调用，用于检查本地认证信息并获取当前用户信息。
  /// 它使用一个锁确保只执行一次。
  Future<void> initialize() async {
    if (_initialized || _isInitializing) return; // 阻止重复初始化或在初始化过程中再次调用

    // 使用锁确保初始化逻辑的同步执行
    await _initializationLock.synchronized(() async {
      if (_initialized || _isInitializing) return; // 锁内二次检查

      _setIsInitializing(true); // 设置为初始化中状态

      User? determinedUser; // 最终确定的用户对象
      try {
        final String? token = await _userService.getToken(); // 获取本地存储的认证 Token
        if (token == null) {
          determinedUser = null; // 无 Token，则无用户
        } else {
          final savedUserId = await _userService.currentUserId; // 获取本地存储的用户ID
          if (savedUserId != null && savedUserId.isNotEmpty) {
            try {
              determinedUser =
                  await _userService.getCurrentUser(); // 尝试通过 Token 获取当前用户数据
            } catch (e) {
              // 获取用户失败
              determinedUser = null;
            }
          } else {
            // 有 Token 但没有 userId，数据不一致，清除认证数据。
            determinedUser = null;
            await _userService.clearAuthData();
          }
        }
      } catch (e) {
        // 获取 Token 或 UserID 过程中发生异常
        determinedUser = null;
        try {
          await _userService.clearAuthData(); // 尝试清除认证数据
        } catch (_) {
          // 清除数据失败
        }
      } finally {
        _updateCurrentUser(determinedUser); // 更新当前用户状态
        _setIsInitializing(false); // 设置为非初始化中状态
        _initialized = true; // 标记为已完成初始化
      }
    });
  }

  /// 用户登录方法。
  ///
  /// [email]：用户邮箱。
  /// [password]：用户密码。
  /// [rememberMe]：是否记住登录状态。
  ///
  /// 成功登录后，更新当前用户状态。失败则抛出异常。
  Future<void> signIn(String email, String password, bool rememberMe) async {
    try {
      final user = await _userService.signIn(
          email, password, rememberMe); // 调用 UserService 执行登录
      await Future.delayed(_signInNotifyDelay); // 模拟延迟
      _updateCurrentUser(user); // 登录成功，更新当前用户状态
    } catch (e) {
      _updateCurrentUser(null); // 登录失败时清除用户状态
      rethrow; // 将异常重新抛出
    }
  }

  /// 用户登出方法。
  ///
  /// 调用 UserService 执行登出操作，并清除本地认证数据。
  /// 清除 AuthProvider 中的用户状态。
  Future<void> signOut() async {
    try {
      await _userService.signOut(); // 调用 UserService 执行登出
      _updateCurrentUser(null); // 清除 AuthProvider 中的用户状态
    } catch (e) {
      // 登出失败
      _updateCurrentUser(null); // 尝试清除本地用户状态
    } finally {
      await Future.delayed(_signOutNotifyDelay); // 模拟延迟
    }
  }

  /// 刷新当前用户状态。
  ///
  /// 阻止在初始化或刷新过程中重复调用。
  /// 未初始化时执行初始化流程。
  /// 否则，从 UserService 获取最新的用户数据。
  /// 获取失败时清除认证数据。
  Future<void> refreshUserState() async {
    if (_isInitializing || _isRefreshing) return; // 阻止重复刷新
    if (!_initialized) {
      // 未初始化时执行初始化流程
      await initialize();
      return;
    }

    _setIsRefreshing(true); // 设置为刷新中状态
    await Future.delayed(_refreshNotifyDelay); // 模拟延迟

    try {
      final savedUserId = await _userService.currentUserId; // 获取本地存储的用户ID
      User? refreshedUser; // 刷新后的用户对象
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          refreshedUser = await _userService.getCurrentUser(); // 尝试获取最新的用户数据
        } catch (e) {
          // 获取用户失败
          refreshedUser = null;
          await _userService.clearAuthData(); // 清除认证数据
        }
      } else {
        // 没有 savedUserId，用户未登录
        refreshedUser = null;
      }
      _updateCurrentUser(refreshedUser); // 更新当前用户状态
    } catch (e) {
      // 刷新过程中发生异常
      _updateCurrentUser(null); // 清除用户状态
    } finally {
      _setIsRefreshing(false); // 设置为非刷新中状态
    }
  }

  /// 获取当前用户的认证 Token。
  ///
  /// 从 UserService 获取 Token。
  Future<String?> getAuthToken() {
    return _userService.getToken();
  }

  /// 清理资源。
  ///
  /// 当 `AuthProvider` 实例不再需要时调用，取消所有 Stream 订阅并关闭 StreamController。
  @override
  void dispose() {
    _unauthorizedSubscription?.cancel(); // 取消未授权事件的订阅
    _currentUserController.close(); // 关闭所有 StreamController
    _isLoggedInController.close();
    _currentUserIdController.close();
    _isInitializingController.close();
    _isRefreshingController.close();
    _isLoadingController.close(); // 关闭 isLoadingController
    super.dispose(); // 调用父类的 dispose 方法
  }
}

/// 简单的异步锁实现。
///
/// 用于防止异步操作的并发执行。
class Lock {
  Completer<void>? _completer; // 用于控制锁的状态

  /// 获取锁。
  /// 如果锁已被占用，等待直到锁被释放。
  Future<void> _lock() async {
    if (_completer != null) {
      await _completer!.future; // 如果锁已被占用，等待其完成
      return _lock(); // 等待完成后再次尝试获取锁
    }
    _completer = Completer<void>(); // 创建新的 Completer，表示锁已被占用
  }

  /// 释放锁。
  /// 完成当前的 Completer。
  void _unlock() {
    final completer = _completer;
    _completer = null; // 清除 Completer，表示锁已被释放
    completer?.complete(); // 完成 Completer，通知所有等待者
  }

  /// 同步执行一个异步操作。
  ///
  /// [action]：一个返回 `Future<T>` 的函数。
  /// 确保 `action` 在任何时候都只有一个实例在运行。
  Future<T> synchronized<T>(Future<T> Function() action) async {
    await _lock(); // 获取锁
    try {
      return await action(); // 执行操作
    } finally {
      _unlock(); // 无论操作成功或失败，都释放锁
    }
  }
}
