// lib/providers/auth/auth_provider.dart

/// 定义了 [AuthProvider]，用于管理用户的核心认证状态。
library;

import 'dart:async';
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';

/// 管理用户认证状态的核心 Provider。
///
/// 依赖 [UserService] 执行认证操作，并通过 Stream 广播状态变化。
/// 初始状态通过构造函数在应用启动时注入。
class AuthProvider {
  /// 依赖的用户服务实例。
  final UserService _userService;

  // --- 内部状态变量 ---

  User? _currentUser;
  String? _authToken;
  bool _isRefreshing = false;
  StreamSubscription? _unauthorizedSubscription;

  // --- Stream 控制器 ---

  final _currentUserController = StreamController<User?>.broadcast();
  final _isLoggedInController = StreamController<bool>.broadcast();
  final _currentUserIdController = StreamController<String?>.broadcast();
  final _isRefreshingController = StreamController<bool>.broadcast();
  final _isLoadingController = StreamController<bool>.broadcast();

  // --- Stream 获取器 ---

  /// 获取当前用户对象的流。
  Stream<User?> get currentUserStream => _currentUserController.stream;

  /// 获取用户登录状态的流。
  Stream<bool> get isLoggedInStream => _isLoggedInController.stream;

  /// 获取当前用户ID的流。
  Stream<String?> get currentUserIdStream => _currentUserIdController.stream;

  /// 获取刷新状态的流。
  Stream<bool> get isRefreshingStream => _isRefreshingController.stream;

  /// 获取总体加载状态的流。
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  // --- 同步获取器 ---

  /// 获取当前登录的用户对象。
  User? get currentUser => _currentUser;

  /// 获取当前有效的认证令牌。
  String? get authToken => _authToken;

  /// 获取当前用户是否已登录。
  bool get isLoggedIn => _currentUser != null;

  /// 获取当前用户的唯一标识符。
  String? get currentUserId => _currentUser?.id;

  /// 获取当前是否正在执行刷新操作。
  bool get isRefreshing => _isRefreshing;

  /// 获取总体加载状态。
  bool get isLoading => _isRefreshing;

  /// 获取当前用户是否为管理员。
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// 获取当前用户是否为超级管理员。
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;

  /// 创建一个 [AuthProvider] 实例。
  ///
  /// [userService] 应用中唯一的 [UserService] 实例。
  /// [authToken] 从依赖注入层传入的初始认证令牌。
  /// [currentUser] 从依赖注入层传入的初始用户对象。
  AuthProvider(
    this._userService,
    this._authToken,
    this._currentUser,
  ) {
    _listenForUnauthorizedEvent();
    _broadcastCurrentState();
  }

  /// 监听未授权事件，在收到事件时将用户登出。
  void _listenForUnauthorizedEvent() {
    if (_unauthorizedSubscription != null) return;
    _unauthorizedSubscription =
        appEventBus.on<UserSignedOutEvent>().listen((event) {
      if (_currentUser != null) {
        _updateState(user: null, token: null);
      }
    });
  }

  /// 内部核心方法，用于原子性地更新所有认证相关状态并广播。
  void _updateState({required User? user, required String? token}) {
    final bool oldIsLoggedIn = isLoggedIn;
    final String? oldUserId = currentUserId;

    _currentUser = user;
    _authToken = token;

    _currentUserController.add(_currentUser);

    if (isLoggedIn != oldIsLoggedIn) {
      _isLoggedInController.add(isLoggedIn);
    }
    if (currentUserId != oldUserId) {
      _currentUserIdController.add(currentUserId);
    }
  }

  /// 广播当前持有的状态，用于构造函数中初始化Stream。
  void _broadcastCurrentState() {
    _currentUserController.add(_currentUser);
    _isLoggedInController.add(isLoggedIn);
    _currentUserIdController.add(currentUserId);
    _isRefreshingController.add(_isRefreshing);
    _isLoadingController.add(isLoading);
  }

  /// 设置并广播刷新状态。
  void _setIsRefreshing(bool value) {
    if (_isRefreshing == value) return;
    _isRefreshing = value;
    _isRefreshingController.add(_isRefreshing);
    _isLoadingController.add(isLoading);
  }

  /// 用户登录。
  ///
  /// [email] 用户邮箱。
  /// [password] 用户密码。
  /// [rememberMe] 是否记住登录状态。
  Future<void> signIn(String email, String password, bool rememberMe) async {
    try {
      final user = await _userService.signIn(email, password, rememberMe);
      final authData = await _userService.getAuthToken();
      _updateState(user: user, token: authData?.token);
    } catch (e) {
      _updateState(user: null, token: null);
      rethrow;
    }
  }

  /// 用户登出。
  Future<void> signOut() async {
    try {
      await _userService.signOut();
    } finally {
      _updateState(user: null, token: null);
    }
  }

  /// 刷新当前用户状态。
  ///
  /// 此方法会强制从网络获取最新的用户数据。
  /// 如果发生网络错误，将保持当前状态不变。
  ///
  /// [forceRefresh] 是否强制从网络刷新，忽略所有缓存。
  Future<void> refreshUserState({bool forceRefresh = true}) async {
    if (_isRefreshing) return;
    _setIsRefreshing(true);

    try {
      final refreshedUser =
          await _userService.getCurrentUser(forceRefresh: forceRefresh);
      _updateState(user: refreshedUser, token: _authToken);
    } catch (e) {
      // 刷新失败时，保持现有状态不变。
    } finally {
      _setIsRefreshing(false);
    }
  }

  /// 更新当前用户的硬币数量。
  ///
  /// [amount] 要减少的硬币数量。
  Future<void> updateUserCoins({required int amount}) async {
    try {
      await _userService.reduceUserCoins(reduceAmount: amount);
      await refreshUserState();
    } catch (e) {
      rethrow;
    }
  }

  /// 清理资源。
  ///
  /// 当此实例不再需要时调用，以关闭所有Stream控制器和取消订阅。
  void dispose() {
    _unauthorizedSubscription?.cancel();
    _currentUserController.close();
    _isLoggedInController.close();
    _currentUserIdController.close();
    _isRefreshingController.close();
    _isLoadingController.close();
  }
}
