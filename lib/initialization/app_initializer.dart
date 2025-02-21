// lib/initialization/app_initializer.dart

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/initialize/initialization_provider.dart';
import '../providers/connection/db_state_provider.dart';
import '../providers/theme/theme_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../services/main/database/db_service.dart';
import '../services/update/update_service.dart';
import '../services/main/game/cache/game_cache_service.dart';
import '../services/main/user/cache/info_cache_service.dart';
import '../services/main/linktool/cache/links_tools_cache_service.dart';
import '../services/main/history/cache/history_cache_service.dart';
import '../services/main/game/comment/cache/comment_cache_service.dart';
import '../services/main/forum/cache/forum_cache_service.dart';
import '../services/main/database/restart/restart_service.dart';
import '../services/main/user/cache/user_ban_cache_service.dart';
import '../services/main/message/cache/message_cache_service.dart';

import '../utils/decrypt/config_decrypt.dart';

class AppInitializer {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static Future<void> _initializeKeyWithRetry(
      InitializationProvider initProvider,
      {int retryCount = 0}
      ) async {
    try {
      initProvider.updateProgress('正在获取配置...', 0.05);
      await ConfigDecrypt.initialize();
    } catch (e) {
      if (retryCount < _maxRetries) {
        initProvider.updateProgress(
            '配置获取失败，正在重试 (${retryCount + 1}/$_maxRetries)...',
            0.05
        );
        await Future.delayed(_retryDelay);
        return _initializeKeyWithRetry(initProvider, retryCount: retryCount + 1);
      } else {
        throw Exception('无法获取配置: ${_formatErrorMessage(e)}');
      }
    }
  }

  static Future<Map<String, dynamic>> initializeServices(
      InitializationProvider initProvider
      ) async {
    try {
      // 首先初始化密钥服务
      await _initializeKeyWithRetry(initProvider);

      // 在初始化开始时检查是否是重启
      if (RestartService().restartNotifier.value) {
        await Future.delayed(const Duration(milliseconds: 500));
        RestartService().restartNotifier.value = false;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在初始化本地存储...', 0.1);
      await Hive.initFlutter();

      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在连接数据库...', 0.3);
      final dbStateProvider = DBStateProvider();
      final dbService = DBService();
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

      final messageCacheService = MessageCacheService();
      await messageCacheService.init();

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
        'messageCacheService' : messageCacheService,
      };
    } catch (e) {
      print('Initialization error: $e');
      throw Exception('初始化失败: ${e.toString()}');
    }
  }

  static List<ChangeNotifierProvider> createProviders(Map<String, dynamic> services) {
    final dbService = services['dbService'] as DBService;
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