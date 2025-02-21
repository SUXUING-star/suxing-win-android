// lib/initialization/app_initializer.dart

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/initialize/initialization_provider.dart';
import '../providers/connection/db_state_provider.dart';
import '../providers/theme/theme_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../services/main/database/db_service.dart';
import '../services/main/update/update_service.dart';
import '../services/main/game/cache/game_cache_service.dart';
import '../services/main/user/cache/info_cache_service.dart';
import '../services/main/linktool/cache/links_tools_cache_service.dart';
import '../services/main/history/cache/history_cache_service.dart';
import '../services/main/game/comment/cache/comment_cache_service.dart';
import '../services/main/forum/cache/forum_cache_service.dart';
import '../services/main/database/restart/restart_service.dart';
import '../services/main/user/cache/user_ban_cache_service.dart';
import '../services/main/message/cache/message_cache_service.dart';
import '../services/security/security_service.dart';
import '../services/security/security_error.dart';
import '../utils/decrypt/config_decrypt.dart';
import '../utils/error/error_formatter.dart';

class AppInitializer {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static Future<void> _initializeSecurityWithRetry(
      InitializationProvider initProvider,
      {int retryCount = 0}) async {
    try {
      initProvider.updateProgress('正在进行安全检查...', 0.02);

      final securityService = SecurityService();
      final checkResult = await securityService.checkSecurity();

      if (!checkResult.isValid) {
        // 如果是不可重试的安全错误，直接抛出
        if (!checkResult.canRetry) {
          initProvider.setError(checkResult.errorMessage ?? '安全检查失败');
          throw SecurityError(checkResult.errorMessage ?? '安全检查失败',
              canRetry: false);
        }
        throw Exception(checkResult.errorMessage ?? '安全检查失败');
      }
    } catch (e) {
      // 如果是安全错误且不可重试，直接设置错误并退出
      if (e is SecurityError && !e.canRetry) {
        initProvider.setError(e.message);
        throw e;
      }

      // 其他错误进行重试
      if (retryCount < _maxRetries) {
        initProvider.updateProgress(
            '安全检查失败，正在重试 (${retryCount + 1}/$_maxRetries)...', 0.02);
        await Future.delayed(_retryDelay);
        return _initializeSecurityWithRetry(initProvider,
            retryCount: retryCount + 1);
      } else {
        final errorMessage = e is SecurityError ? e.message : e.toString();
        initProvider.setError(errorMessage);
        throw e;
      }
    }
  }

  static Future<void> _initializeKeyWithRetry(
      InitializationProvider initProvider,
      {int retryCount = 0}) async {
    try {
      initProvider.updateProgress('正在获取配置...', 0.05);
      await ConfigDecrypt.initialize();
    } catch (e) {
      if (retryCount < _maxRetries) {
        initProvider.updateProgress(
            '配置获取失败，正在重试 (${retryCount + 1}/$_maxRetries)...', 0.05);
        await Future.delayed(_retryDelay);
        return _initializeKeyWithRetry(initProvider,
            retryCount: retryCount + 1);
      } else {
        throw Exception('无法获取配置: ${ErrorFormatter.formatErrorMessage(e)}');
      }
    }
  }

  static Future<Map<String, dynamic>> initializeServices(
      InitializationProvider initProvider) async {
    try {
      // 先初始化 Hive
      await Future.delayed(const Duration(milliseconds: 100));
      initProvider.updateProgress('正在初始化本地存储...', 0.1);
      await Hive.initFlutter();

      // 再进行安全检查
      await _initializeSecurityWithRetry(initProvider);

      // 初始化密钥服务
      await _initializeKeyWithRetry(initProvider);

      // 在初始化开始时检查是否是重启
      if (RestartService().restartNotifier.value) {
        await Future.delayed(const Duration(milliseconds: 500));
        RestartService().restartNotifier.value = false;
      }

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
        'historyCacheService': historyCacheService,
        'commentsCacheService': commentsCacheService,
        'forumCacheService': forumCacheService,
        'useBanCacheService': useBanCacheService,
        'messageCacheService': messageCacheService,
      };
    } catch (e) {
      print('Initialization error: $e');
      throw Exception('初始化失败: ${e.toString()}');
    }
  }

  static List<ChangeNotifierProvider> createProviders(
      Map<String, dynamic> services) {
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

}
