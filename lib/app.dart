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
import './utils/loading_route_observer.dart';
import './layouts/main_layout.dart';
import './layouts/app_background.dart';
import 'widgets/loading/loading_screen.dart';
import './widgets/dialogs/db_reset_dialog.dart';
import './routes/app_routes.dart';
import 'services/user_service.dart';
import 'services/forum_service.dart';
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
        Provider<RestartService>(create: (_) => RestartService()),
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
    return Consumer2<ThemeProvider, DBStateProvider>(
      builder: (context, themeProvider, dbStateProvider, _) {
        return MaterialApp(
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
                          onReset: () {
                            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                              exit(0);
                            } else {
                              SystemNavigator.pop();
                            }
                          },
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