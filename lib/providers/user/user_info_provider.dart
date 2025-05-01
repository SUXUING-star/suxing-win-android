// lib/providers/user/user_info_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'user_data_status.dart';

class UserInfoProvider with ChangeNotifier {
  final UserService _userService;
  final Map<String, UserDataStatus> _userStatusMap = {};
  final Map<String, Completer<void>> _loadingCompleters = {};

  UserInfoProvider(this._userService);

  /// 获取指定 userId 的当前数据状态。
  UserDataStatus getUserStatus(String userId) {
    return _userStatusMap[userId] ?? UserDataStatus.initial();
  }

  /// 确保指定 userId 的用户信息已加载或正在加载。
  /// 如果数据已存在或正在加载，则直接返回或等待现有加载完成。
  /// 如果未加载，则启动加载过程，并在完成后通知监听者。
  Future<void> ensureUserInfoLoaded(String userId) async {
    final currentStatus = _userStatusMap[userId];

    // 如果数据已加载，无需操作
    if (currentStatus != null && currentStatus.hasData) {
      return;
    }

    // 如果正在加载中，等待现有请求完成
    if (_loadingCompleters.containsKey(userId)) {
      await _loadingCompleters[userId]?.future;
      return;
    }

    // 标记开始加载过程
    final completer = Completer<void>();
    _loadingCompleters[userId] = completer;

    // 更新内部状态为 loading，但不立即通知UI
    _userStatusMap[userId] = UserDataStatus.loading();

    bool stateChanged = false; // 跟踪状态是否实际发生变化需要通知

    try {
      // 执行异步数据获取
      final user = await _userService.getUserInfoById(userId);

      // 检查请求是否仍然有效（未被中途取消或完成）
      if (_loadingCompleters.containsKey(userId) && !_loadingCompleters[userId]!.isCompleted) {
        _userStatusMap[userId] = UserDataStatus.loaded(user);
        stateChanged = true; // 状态变为 loaded
      }
    } catch (e) {
      // 检查请求是否仍然有效
      if (_loadingCompleters.containsKey(userId) && !_loadingCompleters[userId]!.isCompleted) {
        print("UserInfoProvider: Error loading user $userId: $e"); // 保留错误日志是有用的
        _userStatusMap[userId] = UserDataStatus.error(e);
        stateChanged = true; // 状态变为 error
      }
    } finally {
      // 清理 Completer
      final removedCompleter = _loadingCompleters.remove(userId);
      if (removedCompleter != null && !removedCompleter.isCompleted) {
        removedCompleter.complete();
      }

      // 如果状态确实发生了变化，则在异步操作结束后通知UI更新
      if (stateChanged) {
        notifyListeners();
      }
    }
  }

  /// 强制刷新指定用户的用户信息。
  Future<void> refreshUserInfo(String userId) async {
    // 清除现有状态和正在进行的请求（如果有）
    _userStatusMap.remove(userId);
    final existingCompleter = _loadingCompleters.remove(userId);
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      // 可以选择性地 completeError 或让其自然结束
      // existingCompleter.completeError(StateError("Request cancelled due to refresh"));
    }
    // 重新触发加载流程
    await ensureUserInfoLoaded(userId);
  }

  /// 清理指定用户的缓存数据。
  void clearUserInfo(String userId) {
    if (_userStatusMap.containsKey(userId)) {
      _userStatusMap.remove(userId);
      // 通常不需要在此处 notifyListeners，因为调用场景下 Widget 可能已销毁
    }
    // 也考虑清理进行中的请求
    final existingCompleter = _loadingCompleters.remove(userId);
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      // existingCompleter.completeError(StateError("Request cancelled due to clear"));
    }
  }

  /// 清理所有用户的缓存数据（例如登出时）。
  void clearAllUserInfo() {
    _userStatusMap.clear();
    // 取消所有正在进行的请求
    _loadingCompleters.forEach((key, completer) {
      if (!completer.isCompleted) {
        // completer.completeError(StateError("Request cancelled due to clear all"));
      }
    });
    _loadingCompleters.clear();
    notifyListeners(); // 通知 UI 可能需要重置状态
  }

  // Provider 销毁时清理资源
  @override
  void dispose() {
    _loadingCompleters.forEach((key, completer) {
      if (!completer.isCompleted) {
        // completer.completeError(StateError("Provider disposed"));
      }
    });
    _loadingCompleters.clear();
    super.dispose();
  }
}