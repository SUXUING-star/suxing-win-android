// lib/services/restart_service.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/initialization_provider.dart';
import '../providers/db_state_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_connection_service.dart';
import '../services/cache/game_cache_service.dart';
import '../services/cache/avatar_cache_service.dart';
import '../services/cache/links_tools_cache_service.dart';
import '../services/cache/history_cache_service.dart';
import '../services/cache/comment_cache_service.dart';

class RestartService {
  static final RestartService _instance = RestartService._internal();
  factory RestartService() => _instance;
  RestartService._internal();

  final _restartNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get restartNotifier => _restartNotifier;

  Future<void> restartApp() async {
    try {
      // 1. 清理所有缓存和服务
      await _cleanupServices();

      // 2. 触发重启
      _restartNotifier.value = true;

    } catch (e) {
      print('Restart error: $e');
      // 如果重启失败，重置状态
      _restartNotifier.value = false;
      rethrow;
    }
  }

  Future<void> _cleanupServices() async {
    // 关闭所有Hive boxes
    await Hive.close();

    // 清理各种缓存服务
    await GameCacheService().clearCache();
    await AvatarCacheService().clearCache();
    await LinksToolsCacheService().clearCache();
    await HistoryCacheService().clearAllCache();
    await CommentsCacheService().clearAllCache();

    // 关闭数据库连接
    final dbService = DBConnectionService();
    await dbService.close();
  }
}

// 用于重建整个应用的Widget
class RestartWrapper extends StatefulWidget {
  final Widget child;

  const RestartWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  static void restartApp(BuildContext context) {
    final service = RestartService();
    service.restartApp();
  }

  @override
  State<RestartWrapper> createState() => _RestartWrapperState();
}

class _RestartWrapperState extends State<RestartWrapper> {
  Key _key = UniqueKey();

  @override
  void initState() {
    super.initState();
    final service = RestartService();
    service.restartNotifier.addListener(_handleRestart);
  }

  @override
  void dispose() {
    final service = RestartService();
    service.restartNotifier.removeListener(_handleRestart);
    super.dispose();
  }

  void _handleRestart() {
    setState(() {
      // 通过改变key强制重建整个Widget树
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}