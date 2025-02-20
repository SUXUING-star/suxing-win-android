// lib/app.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/history/game_history_service.dart';
import 'services/history/post_history_service.dart';
import './initialization/initialization_wrapper.dart';
import 'providers/initialize/initialization_provider.dart';
import 'providers/theme/theme_provider.dart';
import 'providers/connection/db_state_provider.dart';
import 'utils/load/loading_route_observer.dart';
import './layouts/main_layout.dart';
import 'layouts/background/app_background.dart';
import 'widgets/loading/loading_screen.dart';
import 'widgets/effects/mouse_trail_effect.dart';
import './routes/app_routes.dart';
import 'services/user_service.dart';
import 'services/forum_service.dart';
import 'services/ban/user_ban_service.dart';
import 'services/restart/restart_service.dart';


class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RestartWrapper(  // 添加 RestartWrapper
      child: ChangeNotifierProvider(
        create: (_) => InitializationProvider(),
        child: InitialScreen(),

      ),
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InitializationWrapper(
        onInitialized: (providers) => MyApp(
          providers: providers,
          loadingRouteObserver: LoadingRouteObserver(),
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
        ...providers,
        // 添加 ForumService provider
        Provider<ForumService>(
          create: (_) => ForumService(),
        ),
        // 添加 UserService provider
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        // 添加 GameHistoryService和PostHistoryService provider
        Provider<GameHistoryService>(
          create: (_) => GameHistoryService(),
        ),
        Provider<PostHistoryService>(
          create: (_) => PostHistoryService(),
        ),
        Provider<UserBanService>(
          create: (_) => UserBanService(),
        ),
        Provider<RestartService>(create: (_) => RestartService()),
      ],
      child: MaterialApp(
        title: '宿星茶会（windows版）',
        home: AppContent(loadingRouteObserver: loadingRouteObserver),
      ),
    );
  }
}

// lib/app.dart 中的 AppContent 类修改

class AppContent extends StatelessWidget {
  final LoadingRouteObserver loadingRouteObserver;

  const AppContent({
    Key? key,
    required this.loadingRouteObserver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, DBStateProvider>(
      builder: (context, themeProvider, dbStateProvider, _) {
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
                if (dbStateProvider.needsReset)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(32),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  dbStateProvider.errorMessage ?? '连接已断开',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '正在准备重启应用...',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
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