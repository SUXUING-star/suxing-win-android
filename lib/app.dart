// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/listeners/global_api_error_listener.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/image/cache_manager_provider_widget.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/services/main/user/cache/search_history_cache_service.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/slide_fade_page_route.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/email/email_service.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/utils/navigation/sidebar_updater_observer.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'wrapper/initialization_wrapper.dart';
import 'providers/theme/theme_provider.dart';
import './layouts/main_layout.dart';
import 'layouts/background/app_background_effect.dart';
import './routes/app_routes.dart';
import 'wrapper/platform_wrapper.dart';
import 'wrapper/maintenance_wrapper.dart';
import 'services/main/network/network_manager.dart';

// 添加全局导航器键
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
  const MainApp({
    super.key,
  });
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _hasInitializedProviders = false;
  bool _hasInitializedStateService = false;

  late final ThemeProvider _themeProvider;
  late final SidebarProvider _sidebarProvider;
  late final NetworkManager _networkManager;
  late final AuthProvider _authProvider;
  late final WindowStateProvider _windowStateProvider;
  late final MessageService _messageService;
  late final GameService _gameService;
  late final GameCollectionService _gameCollectionService;
  late final UserService _userService;
  late final PostService _postService;
  late final UserFollowService _followService;
  late final ActivityService _activityService;
  late final LinkToolService _linkToolService;
  late final AnnouncementService _announcementService;
  late final UserInfoService _infoService;
  late final SearchHistoryCacheService _searchHistoryCacheService;
  late final GameListFilterProvider _gameListFilterProvider;
  late final InputStateService _inputStateService;
  late final EmailService _emailService;
  late final UserCheckInService _checkInService;
  late final MaintenanceService _maintenanceService;
  late final PostListFilterProvider _postListFilterProvider;
  late final RateLimitedFileUpload _fileUploadService;

  late final Widget _mainLayout;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedProviders) {
      _themeProvider = context.read<ThemeProvider>();
      _sidebarProvider = context.read<SidebarProvider>();
      _networkManager = context.read<NetworkManager>();
      _authProvider = context.read<AuthProvider>();
      _windowStateProvider = context.read<WindowStateProvider>();
      _gameListFilterProvider = context.read<GameListFilterProvider>();
      _postListFilterProvider = context.read<PostListFilterProvider>();
      _fileUploadService = context.read<RateLimitedFileUpload>();
      _messageService = context.read<MessageService>();
      _announcementService = context.read<AnnouncementService>();
      _maintenanceService = context.read<MaintenanceService>();
      _postService = context.read<PostService>();
      _userService = context.read<UserService>();
      _gameService = context.read<GameService>();
      _gameCollectionService = context.read<GameCollectionService>();
      _followService = context.read<UserFollowService>();
      _activityService = context.read<ActivityService>();
      _linkToolService = context.read<LinkToolService>();
      _emailService = context.read<EmailService>();
      _checkInService = context.read<UserCheckInService>();
      _infoService = context.read<UserInfoService>();
      _searchHistoryCacheService = context.read<SearchHistoryCacheService>();
      _inputStateService = context.read<InputStateService>();
      _hasInitializedProviders = true;
    }
    if (!_hasInitializedStateService && _hasInitializedProviders) {
      _hasInitializedStateService = true;
      _checkInService.initialize();
      _followService.initialize();
      _mainLayout = _buildMainLayout();
    }
  }

  @override
  void dispose() {
    _sidebarProvider.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  Route<dynamic> _buildAppRoutes(RouteSettings routeSettings) {
    return AppRoutes.onGenerateRoute(
      routeSettings,
      _authProvider,
      _userService,
      _postService,
      _gameService,
      _followService,
      _activityService,
      _linkToolService,
      _messageService,
      _gameCollectionService,
      _infoService,
      _inputStateService,
      _emailService,
      _checkInService,
      _announcementService,
      _maintenanceService,
      _gameListFilterProvider,
      _sidebarProvider,
      _postListFilterProvider,
      _fileUploadService,
      _windowStateProvider,
      _searchHistoryCacheService,
    );
  }

  Widget _buildMainLayout() {
    return MainLayout(
      key: const ValueKey('MainLayoutKey'),
      gameListFilterProvider: _gameListFilterProvider,
      checkInService: _checkInService,
      inputStateService: _inputStateService,
      announcementService: _announcementService,
      sidebarProvider: _sidebarProvider,
      messageService: _messageService,
      authProvider: _authProvider,
      userService: _userService,
      gameService: _gameService,
      postService: _postService,
      linkToolService: _linkToolService,
      activityService: _activityService,
      followService: _followService,
      infoService: _infoService,
      windowStateProvider: _windowStateProvider,
      postListFilterProvider: _postListFilterProvider,
      fileUpload: _fileUploadService,
    );
  }

  Widget _buildBaseContent(
    ThemeMode themeMode,
    Color particleColor,
    List<Color> backgroundGradientColor,
    Widget? materialAppGeneratedChild,
  ) {
    return NoAuthorlizedListener(
      child: MaintenanceNetworkWrapper(
        networkManager: _networkManager,
        maintenanceService: _maintenanceService,
        authProvider: _authProvider,
        child: AppBackgroundEffect(
          backgroundGradientColor: backgroundGradientColor,
          particleColor: particleColor,
          windowStateProvider: _windowStateProvider,
          child: Navigator(
            key: rootNavigatorKey,
            onGenerateRoute: (settings) {
              return SlideFadePageRoute(
                routeSettings: settings,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitializedProviders) {
      return const LoadingWidget();
    }

    return StreamBuilder<ThemeMode>(
      stream: _themeProvider.themeModeStream,
      initialData: _themeProvider.currentThemeMode,
      builder: (context, snapshot) {
        final themeMode = snapshot.data!;
        final isDark = themeMode == ThemeMode.dark;
        final particleColor =
            isDark ? const Color(0xFFE0E0E0) : const Color(0xFFB3E5FC);
        final List<Color> backgroundGradientColors = isDark // 渐变颜色
            ? [
                const Color.fromRGBO(0, 0, 0, 0.6),
                const Color.fromRGBO(0, 0, 0, 0.4)
              ]
            : [
                const Color.fromRGBO(255, 255, 255, 0.7),
                const Color.fromRGBO(255, 255, 255, 0.5)
              ];

        return MaterialApp(
          navigatorKey: mainNavigatorKey,
          title: GlobalConstants.appName,
          theme: _themeProvider.lightTheme,
          darkTheme: _themeProvider.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [
            routeObserver,
            SidebarUpdaterObserver(
              sidebarProvider: _sidebarProvider,
            ),
          ],
          onGenerateRoute: (routeSettings) => _buildAppRoutes(routeSettings),
          home: _mainLayout,
          builder: (builderContext, materialAppGeneratedChild) {
            return _buildBaseContent(
              themeMode,
              particleColor,
              backgroundGradientColors,
              materialAppGeneratedChild,
            ); // 基础应用内容
          },
        );
      },
    );
  }
}
