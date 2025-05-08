// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/listeners/global_api_error_listener.dart';
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
      onInitialized: (providers) => MainApp(
        providers: providers,
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final List<SingleChildWidget> providers;

  const MainApp({
    super.key,
    required this.providers,
  });

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
        // 仍然可以通过 Provider 获取 NetworkManager 实例来更新状态
        // NetworkErrorListenerWidget 也会监听到这个更新
        if (mounted) {
          // 再次检查 mounted
          final networkManager =
              Provider.of<NetworkManager?>(context, listen: false);
          networkManager?.getNetworkStatus();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // NetworkManager 相关的监听器清理已移至 NetworkErrorListenerWidget
    super.dispose();
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

          return MaterialApp(
            navigatorKey: mainNavigatorKey,
            title: GlobalConstants.appName,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [routeObserver],
            builder: (context, child) {
              return NetworkErrorListenerWidget(
                child: GlobalApiErrorListener(
                  child: MaintenanceWrapper(
                    child: Stack(
                      children: [
                        AppBackground(
                          child: MouseTrailEffect(
                            particleColor: particleColor,
                            child: Navigator(
                              onGenerateRoute: (settings) => MaterialPageRoute(
                                builder: (_) => PlatformWrapper(
                                  child: child ?? Container(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            home: MainLayout(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
