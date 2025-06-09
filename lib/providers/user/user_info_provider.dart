// lib/providers/user/user_info_provider.dart

/// 该文件定义了 UserInfoProvider，管理用户数据加载状态
/// UserInfoProvider 负责按需加载、缓存和提供用户详细信息。
library;

import 'dart:async'; // 异步编程所需
import 'package:suxingchahui/services/main/user/user_service.dart'; // 用户服务，用于获取用户数据
import 'user_data_status.dart'; // 用户数据状态枚举和类

/// `UserInfoProvider` 类：管理用户详细数据加载状态的 Provider。
///
/// 该类为每个用户ID提供其数据的加载状态、缓存和实时更新。
class UserInfoProvider {
  final UserService _userService; // 用户服务实例
  final Map<String, UserDataStatus> _userStatusMap = {}; // 存储每个用户的当前数据状态
  final Map<String, Completer<void>> _loadingCompleters = {}; // 管理每个用户数据的并发加载请求
  final Map<String, StreamController<UserDataStatus>>
      _userStatusStreamControllers = {}; // 存储每个用户的状态流控制器

  /// 构造函数。
  ///
  /// 接收一个 [UserService] 实例。
  UserInfoProvider(this._userService);

  /// 私有辅助方法：获取或创建一个指定用户ID的状态流控制器。
  ///
  /// [userId]：用户的唯一标识符。
  /// 返回对应用户ID的广播 StreamController。
  StreamController<UserDataStatus> _getOrCreateUserStreamController(
      String userId) {
    return _userStatusStreamControllers.putIfAbsent(
      userId,
      () => StreamController<UserDataStatus>.broadcast(),
    );
  }

  /// 获取指定用户的当前数据状态。
  ///
  /// [userId]：用户的唯一标识符。
  /// 返回对应用户的 [UserDataStatus]，未找到则返回初始状态。
  UserDataStatus getUserStatus(String userId) {
    return _userStatusMap[userId] ?? UserDataStatus.initial();
  }

  /// 获取指定用户的状态 Stream。
  ///
  /// [userId]：用户的唯一标识符。
  /// 该方法在返回 Stream 前会启动数据加载流程。
  Stream<UserDataStatus> getUserStatusStream(String userId) {
    ensureUserInfoLoaded(userId); // 启动数据加载流程
    return _getOrCreateUserStreamController(userId).stream; // 返回状态 Stream
  }

  /// 确保指定用户的详细信息已加载。
  ///
  /// [userId]：用户的唯一标识符。
  /// 如果数据已存在或正在加载中，则等待或直接返回。
  /// 否则，启动数据加载并更新状态。
  Future<void> ensureUserInfoLoaded(String userId) async {
    final currentStatus = _userStatusMap[userId]; // 获取当前用户状态

    if (currentStatus != null && currentStatus.hasData) {
      // 数据已存在，直接返回
      return;
    }

    if (_loadingCompleters.containsKey(userId)) {
      // 该用户数据正在加载中
      await _loadingCompleters[userId]?.future; // 等待加载完成
      return;
    }

    final completer = Completer<void>(); // 创建一个新的 Completer
    _loadingCompleters[userId] = completer; // 缓存 Completer，表示加载开始

    _userStatusMap[userId] = UserDataStatus.loading(); // 设置状态为加载中
    _getOrCreateUserStreamController(userId)
        .add(_userStatusMap[userId]!); // 广播加载中状态

    try {
      final user = await _userService.getUserInfoById(userId); // 从服务获取用户数据
      if (_loadingCompleters.containsKey(userId) &&
          !_loadingCompleters[userId]!.isCompleted) {
        _userStatusMap[userId] = UserDataStatus.loaded(user); // 设置状态为加载完成
        _getOrCreateUserStreamController(userId)
            .add(_userStatusMap[userId]!); // 广播加载完成状态
      }
    } catch (e) {
      if (_loadingCompleters.containsKey(userId) &&
          !_loadingCompleters[userId]!.isCompleted) {
        _userStatusMap[userId] = UserDataStatus.error(e); // 设置状态为错误
        _getOrCreateUserStreamController(userId)
            .add(_userStatusMap[userId]!); // 广播错误状态
      }
    } finally {
      final removedCompleter =
          _loadingCompleters.remove(userId); // 从缓存中移除 Completer
      if (removedCompleter != null && !removedCompleter.isCompleted) {
        removedCompleter.complete(); // 完成 Completer
      }
    }
  }

  /// 刷新指定用户的详细信息。
  ///
  /// [userId]：用户的唯一标识符。
  /// 将用户状态设置为加载中，并强制重新加载数据。
  Future<void> refreshUserInfo(String userId) async {
    _userStatusMap[userId] = UserDataStatus.loading(); // 设置状态为加载中
    _getOrCreateUserStreamController(userId)
        .add(_userStatusMap[userId]!); // 广播加载中状态

    final existingCompleter =
        _loadingCompleters.remove(userId); // 移除旧的 Completer
    if (existingCompleter != null && !existingCompleter.isCompleted) {} // 空操作
    await ensureUserInfoLoaded(userId); // 强制重新加载用户数据
  }

  /// 清除指定用户的缓存信息。
  ///
  /// [userId]：用户的唯一标识符。
  /// 从缓存中移除用户状态，并广播初始状态。
  void clearUserInfo(String userId) {
    if (_userStatusMap.containsKey(userId)) {
      // 检查用户状态是否存在
      _userStatusMap.remove(userId); // 移除用户状态
      if (_userStatusStreamControllers.containsKey(userId)) {
        // 检查 StreamController 是否存在
        _getOrCreateUserStreamController(userId)
            .add(UserDataStatus.initial()); // 广播初始状态
      }
    }
    final existingCompleter =
        _loadingCompleters.remove(userId); // 移除旧的 Completer
    if (existingCompleter != null && !existingCompleter.isCompleted) {} // 空操作
  }

  /// 清除所有用户的缓存信息。
  ///
  /// 广播所有用户的初始状态，并清空所有内部缓存。
  void clearAllUserInfo() {
    List<String> userIdsToClear = _userStatusMap.keys.toList(); // 获取所有用户ID列表
    for (var userId in userIdsToClear) {
      // 遍历并广播初始状态
      if (_userStatusStreamControllers.containsKey(userId)) {
        _userStatusStreamControllers[userId]!.add(UserDataStatus.initial());
      }
    }
    _userStatusMap.clear(); // 清空用户状态缓存

    _loadingCompleters.forEach((key, completer) {
      // 遍历所有 Completer
      if (!completer.isCompleted) {} // 空操作
    });
    _loadingCompleters.clear(); // 清空 Completer 缓存
  }

  /// 销毁 Provider。
  ///
  /// 清理所有内部 Completer 和 StreamController 资源。
  void dispose() {
    _loadingCompleters.forEach((key, completer) {
      // 遍历所有 Completer
      if (!completer.isCompleted) {} // 空操作
    });
    _loadingCompleters.clear(); // 清空 Completer 缓存

    _userStatusStreamControllers.forEach((_, controller) {
      // 遍历所有 StreamController
      controller.close(); // 关闭 StreamController
    });
    _userStatusStreamControllers.clear(); // 清空 StreamController 缓存
  }
}
