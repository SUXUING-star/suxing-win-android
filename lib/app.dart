// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/listeners/global_api_error_listener.dart';
import 'package:suxingchahui/providers/image/cache_manager_provider_widget.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/widgets/common/startup/initialization_screen.dart';
import 'package:suxingchahui/widgets/ui/utils/network_error_listener_widget.dart';
import 'package:suxingchahui/windows/effects/mouse_trail_effect.dart';
import 'wrapper/initialization_wrapper.dart';
import 'providers/theme/theme_provider.dart';
import './layouts/main_layout.dart';
import 'layouts/background/app_background.dart';
import './routes/app_routes.dart';
import 'wrapper/platform_wrapper.dart';
import 'wrapper/maintenance_wrapper.dart';
import 'services/main/network/network_manager.dart';

// 添加全局导航器键
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return InitializationWrapper(
      onInitialized: (providersFromInitializer) {
        return MultiProvider(
          providers: providersFromInitializer,
          child: CacheManagerProviderWidget(
            cacheKey: 'myAppGlobalCache',
            maxNrOfCacheObjects: 250,
            stalePeriod: const Duration(days: 10),
            child: const MainApp(),
          ),
        );
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // 再次检查 mounted
          NetworkManager? networkManager =
              Provider.of<NetworkManager>(context, listen: false);
          networkManager.getNetworkStatus();
          networkManager = null;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, WindowStateProvider>(
      builder: (context, themeProvider, windowState, _) {
        final particleColor = themeProvider.themeMode == ThemeMode.dark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFB3E5FC);

        return MaterialApp(
          navigatorKey: mainNavigatorKey, // 全局 Navigator Key
          title: GlobalConstants.appName,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: MainLayout(),
          builder: (builderContext, materialAppGeneratedChild) {
            Widget appContentWithCustomChrome = NetworkErrorListenerWidget(
              child: GlobalApiErrorListener(
                child: MaintenanceWrapper(
                  child: AppBackground(
                    child: MouseTrailEffect(
                      particleColor: particleColor,
                      child: Navigator(
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            settings: settings, // 把 settings 传下去
                            builder: (_) => PlatformWrapper(
                              child: materialAppGeneratedChild ??
                                  Container(), // MainLayout 被 PlatformWrapper 包裹
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );

            return Stack(
              children: [
                appContentWithCustomChrome, // 你的完整应用界面（含自定义标题栏和侧边栏）

                if (windowState.isResizingWindow)
                  Positioned.fill(
                    child: InitializationScreen(
                      status: InitializationStatus.inProgress,
                      message: " ", // 或者适当的消息
                      progress: 0.0,
                      onRetry: null,
                      onExit: null,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
