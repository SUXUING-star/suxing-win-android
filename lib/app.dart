// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'wrapper/initialization_wrapper.dart';
import 'providers/theme/theme_provider.dart';
import 'widgets/components/loading/loading_route_observer.dart';
import './layouts/main_layout.dart';
import 'layouts/background/app_background.dart';
import 'widgets/components/loading/loading_screen.dart';
import 'widgets/components/effects/mouse_trail_effect.dart';
import './routes/app_routes.dart';
import 'wrapper/platform_wrapper.dart';
import 'services/main/restart/restart_service.dart';
import 'services/main/network/network_manager.dart';

// 添加全局导航器键
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RestartWrapper(
      child: InitializationWrapper(
        onInitialized: (providers) => MyApp(
          providers: providers,
          loadingRouteObserver: LoadingRouteObserver(),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final List<SingleChildWidget> providers;
  final LoadingRouteObserver loadingRouteObserver;

  const MyApp({
    Key? key,
    required this.providers,
    required this.loadingRouteObserver,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  NetworkManager? _networkManager;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to get the NetworkManager when dependencies change
    try {
      _networkManager = Provider.of<NetworkManager>(context, listen: false);
    } catch (e) {
      // NetworkManager not yet available
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, refresh network status
    if (state == AppLifecycleState.resumed) {
      // Delay a bit to let network state stabilize
      Future.delayed(Duration(milliseconds: 500), () {
        // Use the stored reference instead
        _networkManager?.getNetworkStatus(); // Trigger network status update
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: widget.providers,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final particleColor = themeProvider.themeMode == ThemeMode.dark
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFB3E5FC);

          return MouseTrailEffect(
            particleColor: particleColor,
            maxParticles: 20,
            particleLifespan: const Duration(milliseconds: 800),
            child: MaterialApp(
              // 添加全局导航器键
              navigatorKey: mainNavigatorKey,
              title: '宿星茶会（跨平台版）',
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              navigatorObservers: [widget.loadingRouteObserver],
              // 这里是关键：使用带有Overlay的builder
              builder: (context, child) {
                return Stack(
                  children: [
                    AppBackground(
                      child: Navigator(
                        // 这个内部导航器确保有Overlay
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (_) => PlatformWrapper(
                            child: child ?? Container(),
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.loadingRouteObserver.isLoading,
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
            ),
          );
        },
      ),
    );
  }
}