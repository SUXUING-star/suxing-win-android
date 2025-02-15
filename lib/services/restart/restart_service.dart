// lib/services/restart/restart_service.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/initialize/initialization_provider.dart';
import '../../providers/connection/db_state_provider.dart';
import '../../providers/theme/theme_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../db_connection_service.dart';
import '../cache/game_cache_service.dart';
import '../cache/avatar_cache_service.dart';
import '../cache/links_tools_cache_service.dart';
import '../cache/history_cache_service.dart';
import '../cache/comment_cache_service.dart';
import '../user_service.dart';

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
    try {
      // 1. 首先清理各缓存服务内的数据，但不关闭boxes
      final cleanupTasks = [
            () async {
          try {
            await UserService().clearAuthData();
          } catch (e) {
            print('Clear auth data error: $e');
          }
        },
            () async {
          try {
            await GameCacheService().clearCacheData();
          } catch (e) {
            print('Clear game cache error: $e');
          }
        },
            () async {
          try {
            await AvatarCacheService().clearCacheData();
          } catch (e) {
            print('Clear avatar cache error: $e');
          }
        },
            () async {
          try {
            await LinksToolsCacheService().clearCacheData();
          } catch (e) {
            print('Clear links tools cache error: $e');
          }
        },
            () async {
          try {
            await HistoryCacheService().clearCacheData();
          } catch (e) {
            print('Clear history cache error: $e');
          }
        },
            () async {
          try {
            await CommentsCacheService().clearCacheData();
          } catch (e) {
            print('Clear comments cache error: $e');
          }
        },
      ];

      // 并行执行清理任务
      await Future.wait(cleanupTasks.map((task) => task()));

      // 2. 关闭所有服务
      await Future.wait([
        UserService().closeBox(),
        DBConnectionService().close(),
      ]);

      // 3. 最后关闭所有Hive boxes
      await Future.delayed(const Duration(milliseconds: 100));
      await Hive.close();

      // 4. 添加额外延迟确保所有操作完成
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      print('Cleanup services error: $e');
      rethrow;
    }
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