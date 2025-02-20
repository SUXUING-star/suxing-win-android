// lib/initialization/app_initializer.dart

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/initialize/initialization_provider.dart';
import '../providers/connection/db_state_provider.dart';
import '../providers/theme/theme_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../services/db_connection_service.dart';
import '../services/update/update_service.dart';
import '../services/cache/game_cache_service.dart';
import '../services/cache/info_cache_service.dart';
import '../services/cache/links_tools_cache_service.dart';
import '../services/cache/history_cache_service.dart';
import '../services/cache/comment_cache_service.dart';
import '../services/cache/forum_cache_service.dart';
import '../services/restart/restart_service.dart';
import '../services/cache/user_ban_cache_service.dart';

class AppInitializer {
  static Future<Map<String, dynamic>> initializeServices(
      InitializationProvider initProvider
      ) async {
    try {
      // 在初始化开始时检查是否是重启
      if (RestartService().restartNotifier.value) {
        // 如果是重启，等待一小段时间确保之前的清理完成
        await Future.delayed(const Duration(milliseconds: 500));
        // 重置重启标志
        RestartService().restartNotifier.value = false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在初始化本地存储...', 0.1);
      await Hive.initFlutter();

      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在连接数据库...', 0.3);
      final dbStateProvider = DBStateProvider();
      final dbService = DBConnectionService();
      final updateService = UpdateService();

      dbService.setStateProvider(dbStateProvider);

      try {
        await dbService.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('数据库连接超时，请检查网络连接');
          },
        );
      } catch (e) {
        throw Exception('数据库连接失败: ${e.toString()}');
      }

      // 仅在数据库连接成功后继续初始化其他服务
      if (!dbService.isConnected) {
        throw Exception('数据库连接失败');
      }

      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在初始化缓存服务...', 0.6);

      // 初始化依赖数据库连接的服务
      final gameCacheService = GameCacheService();
      await gameCacheService.init();

      final infoCacheService = InfoCacheService();
      await infoCacheService.init();

      final linksToolsCacheService = LinksToolsCacheService();
      await linksToolsCacheService.init();

      final historyCacheService = HistoryCacheService();
      await historyCacheService.init();

      final commentsCacheService = CommentsCacheService();
      await commentsCacheService.init();

      final forumCacheService = ForumCacheService();
      await forumCacheService.init();

      final useBanCacheService = UserBanCacheService();
      await useBanCacheService.init();

      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('初始化完成', 1.0);

      return {
        'dbService': dbService,
        'dbStateProvider': dbStateProvider,
        'updateService': updateService,
        'gameCacheService': gameCacheService,
        'infoCacheService': infoCacheService,
        'linksToolsCacheService': linksToolsCacheService,
        'historyCacheService' : historyCacheService,
        'commentsCacheService' : commentsCacheService,
        'forumCacheService' : forumCacheService,
        'useBanCacheService' : useBanCacheService,

      };
    } catch (e) {
      print('Initialization error: $e');
      throw Exception('初始化失败: ${e.toString()}');
    }
  }

  static List<ChangeNotifierProvider> createProviders(Map<String, dynamic> services) {
    final dbService = services['dbService'] as DBConnectionService;
    if (!dbService.isConnected) {
      throw Exception('数据库未连接，无法创建服务');
    }

    return [
      ChangeNotifierProvider<DBStateProvider>.value(
        value: services['dbStateProvider'] as DBStateProvider,
      ),
      ChangeNotifierProvider<UpdateService>.value(
        value: services['updateService'] as UpdateService,
      ),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ];
  }

  static String _formatErrorMessage(dynamic error) {
    String message = error.toString();

    // 检查是否包含MongoDB连接错误
    if (message.contains('MongoDB ConnectionException') ||
        message.contains('SocketException')) {
      return '无法连接到服务器，请检查网络连接是否正常。\n\n如果网络正常但仍然无法连接，可能是：\n1. 网络不稳定\n2. 服务器正在维护\n3. 防火墙设置阻止了连接';
    }

    // 检查是否为超时错误
    if (message.contains('TimeoutException')) {
      return '连接服务器超时，请检查网络状态后重试。';
    }

    // 隐藏具体的技术错误信息
    if (message.contains('Exception:')) {
      // 只保留冒号后面的用户友好信息，如果没有则返回通用错误
      final colonIndex = message.indexOf(':');
      if (colonIndex != -1 && message.length > colonIndex + 2) {
        message = message.substring(colonIndex + 2).trim();
        // 如果消息中包含敏感信息，返回通用错误
        if (message.contains('mongodb://') ||
            message.contains('localhost') ||
            message.contains('error code') ||
            message.contains('errno =')) {
          return '应用初始化失败，请稍后重试。';
        }
        return message;
      }
    }

    // 默认错误信息
    return '应用初始化失败，请稍后重试。';
  }

}