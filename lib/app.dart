// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/listeners/global_api_error_listener.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/image/cache_manager_provider_widget.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/email/email_service.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
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
  bool _hasInitializedProviders = false;
  bool _hasInitializedStateService = false;
  late final SidebarProvider _sidebarProvider;
  late final NetworkManager _networkManager;
  late final AuthProvider _authProvider;
  late final WindowStateProvider _windowStateProvider;
  late final MessageService _messageService;
  late final GameService _gameService;
  late final GameCollectionService _gameCollectionService;
  late final UserService _userService;
  late final ForumService _forumService;
  late final UserFollowService _followService;
  late final UserActivityService _activityService;
  late final LinkToolService _linkToolService;
  late final AnnouncementService _announcementService;
  late final UserInfoProvider _infoProvider;
  late final InputStateService _inputStateService;
  late final EmailService _emailService;
  late final UserCheckInService _checkInService;
  late final MaintenanceService _maintenanceService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedProviders) {
      _sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
      _networkManager = Provider.of<NetworkManager>(context, listen: false);
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _windowStateProvider =
          Provider.of<WindowStateProvider>(context, listen: false);
      _messageService = context.read<MessageService>();
      _announcementService = context.read<AnnouncementService>();
      _maintenanceService = context.read<MaintenanceService>();
      _forumService = context.read<ForumService>();
      _userService = context.read<UserService>();
      _gameService = context.read<GameService>();
      _gameCollectionService = context.read<GameCollectionService>();
      _followService = context.read<UserFollowService>();
      _activityService = context.read<UserActivityService>();
      _linkToolService = context.read<LinkToolService>();
      _emailService = context.read<EmailService>();
      _checkInService = context.read<UserCheckInService>();
      _infoProvider = Provider.of<UserInfoProvider>(context, listen: false);
      _inputStateService =
          Provider.of<InputStateService>(context, listen: false);
      _hasInitializedProviders = true;
    }
    if (!_hasInitializedStateService && _hasInitializedProviders) {
      _hasInitializedStateService = true;
      _checkInService.initialize();
      _followService.initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          // 再次检查 mounted
          _networkManager.getNetworkStatus();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sidebarProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitializedProviders) {
      return const Center(child: CircularProgressIndicator());
    }

    // ThemeProvider 仍然可以通过 Consumer 或 context.watch 获取，因为它影响粒子颜色等
    // 但 WindowStateProvider 的 isResizingWindow 将通过 StreamBuilder 处理
    return Consumer<ThemeProvider>(
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
          onGenerateRoute: (routeSettings) => AppRoutes.onGenerateRoute(
              routeSettings,
              _authProvider,
              _userService,
              _forumService,
              _gameService,
              _followService,
              _activityService,
              _linkToolService,
              _messageService,
              _gameCollectionService,
              _infoProvider,
              _inputStateService,
              _emailService,
              _checkInService,
              _announcementService,
              _maintenanceService),
          home: MainLayout(
            checkInService: _checkInService,
            inputStateService: _inputStateService,
            announcementService: _announcementService,
            sidebarProvider: _sidebarProvider,
            messageService: _messageService,
            authProvider: _authProvider,
            userService: _userService,
            gameService: _gameService,
            forumService: _forumService,
            linkToolService: _linkToolService,
            activityService: _activityService,
            followService: _followService,
            infoProvider: _infoProvider,
          ),
          builder: (builderContext, materialAppGeneratedChild) {
            // 构建基础的应用内容，这里不再包含顶层的 Stack 和 InitializationScreen
            Widget baseAppContent = NetworkErrorListenerWidget(
              child: GlobalApiErrorListener(
                child: MaintenanceWrapper(
                  maintenanceService: _maintenanceService,
                  authProvider: _authProvider,
                  child: AppBackground(
                    windowStateProvider: _windowStateProvider,
                    child: MouseTrailEffect(
                      particleColor: particleColor, // 来自 ThemeProvider
                      child: Navigator(
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            settings: settings,
                            builder: (_) => PlatformWrapper(
                              checkInService: _checkInService,
                              messageService: _messageService,
                              sidebarProvider: _sidebarProvider,
                              authProvider: _authProvider,
                              announcementService: _announcementService,
                              child: materialAppGeneratedChild ?? Container(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );

            // 使用 StreamBuilder 来监听 isResizingWindowStream，控制 InitializationScreen
            return StreamBuilder<bool>(
              stream: _windowStateProvider.isResizingWindowStream,
              initialData:
                  _windowStateProvider.isResizingWindow, // 使用 getter 获取初始值
              builder: (context, snapshot) {
                final bool isResizing =
                    snapshot.data ?? _windowStateProvider.isResizingWindow;
                return Stack(
                  children: [
                    baseAppContent, // 基础应用内容
                    if (isResizing) // 根据 Stream 的结果来决定是否显示
                      Positioned.fill(
                        child: InitializationScreen(
                          status: InitializationStatus.inProgress,
                          message: " ", // 或者 "正在调整窗口大小..."
                          progress: 0.0, // 可以设为 null 如果不显示进度条
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
      },
    );
  }
}
