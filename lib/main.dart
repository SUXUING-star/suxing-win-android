import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/db_connection_service.dart';
import 'services/user_service.dart';
import 'services/game_service.dart';
import 'services/history/game_history_service.dart';
import 'services/history/post_history_service.dart';
import 'services/forum_service.dart';
import 'services/cache/game_cache_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'layouts/main_layout.dart';
import 'layouts/app_background.dart';
import 'widgets/common/loading_screen.dart';
import 'utils/loading_route_observer.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 初始化数据库连接
  await DBConnectionService().initialize();

  // 初始化游戏缓存服务
  final gameCacheService = GameCacheService();
  await gameCacheService.init();

  // 初始化加载观察者
  final loadingRouteObserver = LoadingRouteObserver();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => UserService()),
        Provider.value(value: gameCacheService),
        Provider(
          create: (context) => GameService(),
          lazy: true,
        ),
        Provider(create: (_) => GameHistoryService()),
        Provider(create: (_) => PostHistoryService()),
        Provider(create: (_) => ForumService()),
      ],
      child: App(loadingRouteObserver: loadingRouteObserver),
    ),
  );
}

class App extends StatelessWidget {
  final LoadingRouteObserver loadingRouteObserver;

  const App({Key? key, required this.loadingRouteObserver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听主题变化
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
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