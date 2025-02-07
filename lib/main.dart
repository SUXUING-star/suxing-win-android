// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart'; // 添加这行导入

import './routes/app_routes.dart';
import './services/db_connection_service.dart';
import './services/update_service.dart';  // 添加这行
import './services/user_service.dart';
import './services/game_service.dart';
import './services/history/game_history_service.dart';
import './services/history/post_history_service.dart';
import './services/forum_service.dart';
import './services/cache/game_cache_service.dart';
import './services/cache/avatar_cache_service.dart';
import './services/cache/links_tools_cache_service.dart';
import './providers/auth_provider.dart';
import './providers/theme_provider.dart';
import './providers/db_state_provider.dart';
import './layouts/main_layout.dart';
import './layouts/app_background.dart';
import './widgets/common/loading_screen.dart';
import './widgets/dialogs/db_reset_dialog.dart';
import './utils/loading_route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final dbStateProvider = DBStateProvider();
  final dbService = DBConnectionService();
  final updateService = UpdateService();  // 添加这行
  dbService.setStateProvider(dbStateProvider);

  // 初始化数据库连接
  await dbService.initialize();

  // 初始化其他服务
  final gameCacheService = GameCacheService();
  await gameCacheService.init();

  final avatarCacheService = AvatarCacheService();
  await avatarCacheService.init();

  final linksToolsCacheService = LinksToolsCacheService();
  await linksToolsCacheService.init();

  // 初始化加载观察者
  final loadingRouteObserver = LoadingRouteObserver();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbStateProvider),
        ChangeNotifierProvider.value(value: updateService),  // 添加这行
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => UserService()),
        Provider.value(value: gameCacheService),
        Provider.value(value: avatarCacheService),
        Provider.value(value: linksToolsCacheService),
        Provider(
          create: (context) => GameService(),
          lazy: true,
        ),
        Provider(create: (_) => GameHistoryService()),
        Provider(create: (_) => PostHistoryService()),
        Provider(create: (_) => ForumService()),
      ],
      child: MyApp(loadingRouteObserver: loadingRouteObserver),
    ),
  );
}

class MyApp extends StatelessWidget {
  final LoadingRouteObserver loadingRouteObserver;

  const MyApp({Key? key, required this.loadingRouteObserver}) : super(key: key);

  void _handleReset(BuildContext context) async {
    // 使用原生方式退出应用
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0); // 在桌面端直接退出应用
    } else {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop'); // 在移动端优雅退出
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, DBStateProvider>(
      builder: (context, themeProvider, dbStateProvider, _) {
        return MaterialApp(
          title: '宿星茶会（windows版）',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorObservers: [loadingRouteObserver],
          builder: (context, child) {
            return Stack(
              children: [
                AppBackground(child: child ?? Container()),
                if (dbStateProvider.needsReset)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: DBResetDialog(
                          onReset: () => _handleReset(context),
                        ),
                      ),
                    ),
                  ),
                ValueListenableBuilder<bool>(
                  valueListenable: loadingRouteObserver.isLoading,
                  builder: (context, isLoading, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: loadingRouteObserver.isFirstLoad,
                      builder: (context, isFirstLoad, _) {
                        return LoadingScreen(
                          isLoading: isLoading,
                          isFirstLoad: isFirstLoad,
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
          home: MainLayout(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}