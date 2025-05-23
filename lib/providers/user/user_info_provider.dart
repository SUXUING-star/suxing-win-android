// lib/providers/user/user_info_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'user_data_status.dart';

class UserInfoProvider with ChangeNotifier {
  final UserService _userService;
  final Map<String, UserDataStatus> _userStatusMap = {};
  final Map<String, Completer<void>> _loadingCompleters = {};
  final Map<String, StreamController<UserDataStatus>>
      _userStatusStreamControllers = {};

  UserInfoProvider(this._userService);

  StreamController<UserDataStatus> _getOrCreateUserStreamController(
      String userId) {
    return _userStatusStreamControllers.putIfAbsent(
      userId,
      () => StreamController<UserDataStatus>.broadcast(),
    );
  }

  UserDataStatus getUserStatus(String userId) {
    return _userStatusMap[userId] ?? UserDataStatus.initial();
  }

  Stream<UserDataStatus> getUserStatusStream(String userId) {
    ensureUserInfoLoaded(userId);
    return _getOrCreateUserStreamController(userId).stream;
  }

  Future<void> ensureUserInfoLoaded(String userId) async {
    final currentStatus = _userStatusMap[userId];

    if (currentStatus != null && currentStatus.hasData) {
      return;
    }

    if (_loadingCompleters.containsKey(userId)) {
      await _loadingCompleters[userId]?.future;
      return;
    }

    final completer = Completer<void>();
    _loadingCompleters[userId] = completer;

    _userStatusMap[userId] = UserDataStatus.loading();
    _getOrCreateUserStreamController(userId).add(_userStatusMap[userId]!);

    try {
      final user = await _userService.getUserInfoById(userId);
      if (_loadingCompleters.containsKey(userId) &&
          !_loadingCompleters[userId]!.isCompleted) {
        _userStatusMap[userId] = UserDataStatus.loaded(user);
        _getOrCreateUserStreamController(userId).add(_userStatusMap[userId]!);
      }
    } catch (e) {
      if (_loadingCompleters.containsKey(userId) &&
          !_loadingCompleters[userId]!.isCompleted) {
        _userStatusMap[userId] = UserDataStatus.error(e);
        _getOrCreateUserStreamController(userId).add(_userStatusMap[userId]!);
      }
    } finally {
      final removedCompleter = _loadingCompleters.remove(userId);
      if (removedCompleter != null && !removedCompleter.isCompleted) {
        removedCompleter.complete();
      }
    }
  }

  Future<void> refreshUserInfo(String userId) async {
    _userStatusMap[userId] = UserDataStatus.loading();
    _getOrCreateUserStreamController(userId).add(_userStatusMap[userId]!);

    final existingCompleter = _loadingCompleters.remove(userId);
    if (existingCompleter != null && !existingCompleter.isCompleted) {}
    await ensureUserInfoLoaded(userId);
  }

  void clearUserInfo(String userId) {
    if (_userStatusMap.containsKey(userId)) {
      _userStatusMap.remove(userId);
      if (_userStatusStreamControllers.containsKey(userId)) {
        _getOrCreateUserStreamController(userId).add(UserDataStatus.initial());
      }
    }
    final existingCompleter = _loadingCompleters.remove(userId);
    if (existingCompleter != null && !existingCompleter.isCompleted) {}
  }

  void clearAllUserInfo() {
    List<String> userIdsToClear = _userStatusMap.keys.toList();
    for (var userId in userIdsToClear) {
      if (_userStatusStreamControllers.containsKey(userId)) {
        _userStatusStreamControllers[userId]!.add(UserDataStatus.initial());
      }
    }
    _userStatusMap.clear();

    _loadingCompleters.forEach((key, completer) {
      if (!completer.isCompleted) {}
    });
    _loadingCompleters.clear();
  }

  @override
  void dispose() {
    _loadingCompleters.forEach((key, completer) {
      if (!completer.isCompleted) {}
    });
    _loadingCompleters.clear();

    _userStatusStreamControllers.forEach((_, controller) {
      controller.close();
    });
    _userStatusStreamControllers.clear();
    super.dispose();
  }
}
