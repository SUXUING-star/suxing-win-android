// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/listeners/global_api_error_listener.dart';
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
  NetworkManager? _networkManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _networkManager = Provider.of<NetworkManager>(context, listen: false);
    } catch (e) {
      // NetworkManager not yet available
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Delay a bit to let network state stabilize
      Future.delayed(Duration(milliseconds: 500), () {
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

          return MaterialApp(
            navigatorKey: mainNavigatorKey,
            title: GlobalConstants.appName,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [routeObserver],
            builder: (context, child) {
              return GlobalApiErrorListener(
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
