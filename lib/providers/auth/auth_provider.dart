// lib/providers/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import '../../services/main/announcement/announcement_service.dart';

import 'dart:async';

class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = true;
  bool _disposed = false;

  // 单例模式实现，但确保在dispose后能重新创建
  static AuthProvider? _instance;

  factory AuthProvider() {
    if (_instance == null || _instance!._disposed) {
      _instance = AuthProvider._internal();
    }
    return _instance!;
  }

  // 用于监听用户信息变化的流订阅
  StreamSubscription? _userProfileSubscription;

  // 添加日志功能，帮助调试
  List<String> _logs = [];

  AuthProvider._internal() {
    _disposed = false;
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get userId => _currentUser?.id;

  // 获取日志
  List<String> get logs => List.unmodifiable(_logs);

  // 添加日志
  void _log(String message) {
    if (_disposed) return;

    _logs.add('[${DateTime.now().toString()}] $message');
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
  }

  Future<void> _init() async {
    if (_disposed) return;

    _log('开始初始化认证状态');
    try {
      // 检查是否有保存的用户ID
      final savedUserId = await _userService.currentUserId;
      _log('保存的用户ID: $savedUserId');

      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          _currentUser = await _userService.getCurrentUser();
          _log('成功获取当前用户: ${_currentUser?.username}');

          // 检查用户是否有管理员权限
          _log('用户管理员状态: isAdmin=${_currentUser?.isAdmin}, isSuperAdmin=${_currentUser?.isSuperAdmin}');

          // 开始订阅用户资料更新
          _subscribeToUserProfile();
        } catch (e) {
          _log('获取当前用户失败: $e');
          _currentUser = null;
        }
      } else {
        _log('没有保存的用户ID，未登录状态');
      }
    } catch (e) {
      _log('初始化认证状态时出错: $e');
      if (!_disposed) {
        _currentUser = null;
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
        _log('初始化完成，通知UI更新');
      }
    }
  }

  // 订阅用户资料更新
  void _subscribeToUserProfile() {
    _userProfileSubscription?.cancel();
    _userProfileSubscription = _userService.getCurrentUserProfile().listen(
            (User? updatedUser) {
          if (_disposed) return;

          if (updatedUser != null) {
            final bool shouldNotify = _currentUser == null ||
                _currentUser?.username != updatedUser.username ||
                _currentUser?.avatar != updatedUser.avatar ||
                _currentUser?.isAdmin != updatedUser.isAdmin ||
                _currentUser?.isSuperAdmin != updatedUser.isSuperAdmin;

            if (shouldNotify) {
              _log('用户资料已更新: ${updatedUser.username}, isAdmin=${updatedUser.isAdmin}, isSuperAdmin=${updatedUser.isSuperAdmin}');
              _currentUser = updatedUser;
              notifyListeners();
            }
          } else if (_currentUser != null) {
            _log('用户资料流返回null，可能已登出');
            _currentUser = null;
            notifyListeners();
          }
        },
        onError: (e) {
          _log('用户资料流出错: $e');
        }
    );
    _log('已订阅用户资料更新');
  }

  Future<void> signIn(String email, String password) async {
    if (_disposed) return;

    _log('开始登录: $email');
    try {
      _currentUser = await _userService.signIn(email, password);
      _log('登录成功: ${_currentUser?.username}, isAdmin=${_currentUser?.isAdmin}, isSuperAdmin=${_currentUser?.isSuperAdmin}');

      if (!_disposed) {
        // 登录成功后开始订阅用户资料更新
        _subscribeToUserProfile();
        notifyListeners();
      }
    } catch (e) {
      _log('登录失败: $e');
      rethrow;
    }
  }

  // 在 auth_provider.dart 中

  Future<void> signOut() async {
    if (_disposed) return;

    _log('开始登出');
    try {
      // 1. 处理所有服务实例，确保没有服务在登出后继续使用认证数据
      try {
        // 获取公告服务并解除初始化状态，但不销毁它
        // 这样可以避免在后续使用时遇到"已销毁"的错误
        final announcementService = AnnouncementService();
        await announcementService.reset();
        _log('已重置公告服务状态');

        // 这里可以添加其他需要重置的服务
      } catch (e) {
        _log('重置服务状态时出错: $e');
        // 继续执行登出流程
      }

      // 2. 调用用户服务的登出方法
      await _userService.signOut();

      // 3. 取消订阅
      _userProfileSubscription?.cancel();
      _userProfileSubscription = null;

      if (!_disposed) {
        _currentUser = null;
        _log('登出完成，已清除用户信息');
        notifyListeners();
      }
    } catch (e) {
      _log('登出过程中出错: $e');
      if (!_disposed) {
        _currentUser = null;
        notifyListeners();
      }
    }
  }

  // 强制刷新用户状态，用于解决缓存问题
  Future<void> refreshUserState() async {
    if (_disposed) return;

    _log('强制刷新用户状态');
    _isLoading = true;
    notifyListeners();

    try {
      final savedUserId = await _userService.currentUserId;
      if (savedUserId != null && savedUserId.isNotEmpty) {
        try {
          // 尝试重新获取用户信息
          _currentUser = await _userService.getCurrentUser();
          _log('刷新成功: ${_currentUser?.username}, isAdmin=${_currentUser?.isAdmin}, isSuperAdmin=${_currentUser?.isSuperAdmin}');

          // 重新订阅用户资料更新
          _subscribeToUserProfile();
        } catch (e) {
          _log('刷新用户信息失败: $e');
          // 如果获取失败，可能是登录状态已过期
          _currentUser = null;
          await _userService.clearAuthData();
        }
      } else {
        _log('刷新时没有找到用户ID，设置为未登录状态');
        _currentUser = null;
      }
    } catch (e) {
      _log('刷新用户状态时出错: $e');
      _currentUser = null;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
        _log('刷新完成，通知UI更新');
      }
    }
  }

  // 清除日志
  void clearLogs() {
    if (_disposed) return;

    _logs.clear();
    _log('日志已清除');
  }

  @override
  void dispose() {
    _log('销毁AuthProvider');
    _userProfileSubscription?.cancel();
    _userProfileSubscription = null;
    _disposed = true;
    super.dispose();
  }
}