// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'services/common/image_manager_service.dart';
import 'services/main/history/game_history_service.dart';
import 'services/main/history/post_history_service.dart';
import './initialization/initialization_wrapper.dart';
import 'providers/theme/theme_provider.dart';
import 'utils/load/loading_route_observer.dart';
import './layouts/main_layout.dart';
import 'layouts/background/app_background.dart';
import 'widgets/common/load/loading_screen.dart';
import 'widgets/components/effects/mouse_trail_effect.dart';
import './routes/app_routes.dart';
import 'services/main/user/user_service.dart';
import 'services/main/user/user_checkin_service.dart';
import 'services/main/user/user_level_service.dart';
import 'services/main/forum/forum_service.dart';
import 'services/main/user/user_ban_service.dart';
import 'services/main/restart/restart_service.dart';
import 'services/main/audio/audio_service.dart';
import 'services/main/game/collection/game_collection_service.dart';
import 'services/main/activity/activity_service.dart';


class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RestartWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InitializationWrapper(
          onInitialized: (providers) => MyApp(
            providers: providers,
            loadingRouteObserver: LoadingRouteObserver(),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final List<ChangeNotifierProvider> providers;
  final LoadingRouteObserver loadingRouteObserver;


  const MyApp({
    Key? key,
    required this.providers,
    required this.loadingRouteObserver,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...providers, // 包含了所有从 AppInitializer.createProviders 创建的服务
        // 其他不需要特殊初始化的服务
        Provider<ForumService>(
          create: (_) => ForumService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<UserActivityService>(  // 添加用户动态服务
          create: (_) => UserActivityService(),
        ),
        Provider<UserFollowService>(
          create: (_) => UserFollowService(),
        ),
        Provider<UserCheckInService>(
          create: (_) => UserCheckInService(),
        ),
        Provider<UserLevelService>(
          create: (_) => UserLevelService(),
        ),
        Provider<ImageManagerService>(
          create: (_) => ImageManagerService(),
        ),
        Provider<GameHistoryService>(
          create: (_) => GameHistoryService(),
        ),
        Provider<PostHistoryService>(
          create: (_) => PostHistoryService(),
        ),
        Provider<GameCollectionService>(
          create: (_) => GameCollectionService(),
        ),
        Provider<UserBanService>(
          create: (_) => UserBanService(),
        ),
        Provider<RestartService>(
            create: (_) => RestartService()
        ),
        Provider<AudioService>(
          create: (_) => AudioService(),
        ),
      ],
      child: MaterialApp(
        title: '宿星茶会（windows版）',
        home: AppContent(loadingRouteObserver: loadingRouteObserver),
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  final LoadingRouteObserver loadingRouteObserver;

  const AppContent({
    Key? key,
    required this.loadingRouteObserver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final particleColor = themeProvider.themeMode == ThemeMode.dark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFB3E5FC);

        final app = MaterialApp(
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
                    return LoadingScreen(
                      isLoading: isLoading,
                      message: isLoading ? '加载中...' : null,
                    );
                  },
                ),
              ],
            );
          },
          home: MainLayout(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );

        return MouseTrailEffect(
          particleColor: particleColor,
          maxParticles: 20,
          particleLifespan: const Duration(milliseconds: 800),
          child: app,
        );
      },
    );
  }
}