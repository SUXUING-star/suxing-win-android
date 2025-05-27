// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/screens/game/collection/game_collection_screen.dart';
import 'package:suxingchahui/screens/message/message_screen.dart';
import 'package:suxingchahui/screens/search/search_game_screen.dart';
import 'package:suxingchahui/screens/search/search_post_screen.dart';
import 'package:suxingchahui/screens/webview/webview_screen.dart';
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
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/screens/home/home_screen.dart';
import 'package:suxingchahui/screens/common/notfound_screen.dart';
import 'package:suxingchahui/screens/common/about_screen.dart';
import 'package:suxingchahui/screens/auth/login_screen.dart';
import 'package:suxingchahui/screens/auth/register_screen.dart';
import 'package:suxingchahui/screens/auth/forgot_password_screen.dart';
import 'package:suxingchahui/screens/auth/reset_password_screen.dart';
import 'package:suxingchahui/screens/game/detail/game_detail_screen.dart';
import 'package:suxingchahui/screens/game/list/hot_games_screen.dart';
import 'package:suxingchahui/screens/game/list/latest_games_screen.dart';
import 'package:suxingchahui/screens/game/list/games_list_screen.dart';
import 'package:suxingchahui/screens/game/collection/game_collection_list_screen.dart';
import 'package:suxingchahui/screens/game/edit/add_game_screen.dart';
import 'package:suxingchahui/screens/game/edit/edit_game_screen.dart';
import 'package:suxingchahui/screens/linkstools/linkstools_screen.dart';
import 'package:suxingchahui/screens/profile/profile_screen.dart';
import 'package:suxingchahui/screens/profile/open/open_profile_screen.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/screens/forum/post_list_screen.dart';
import 'package:suxingchahui/screens/forum/post/post_detail_screen.dart';
import 'package:suxingchahui/screens/forum/post/create_post_screen.dart';
import 'package:suxingchahui/screens/forum/post/edit_post_screen.dart';
import 'package:suxingchahui/screens/profile/history/history_screen.dart';
import 'package:suxingchahui/screens/profile/myposts/my_posts_screen.dart';
import 'package:suxingchahui/screens/profile/favorite/favorites_screen.dart';
import 'package:suxingchahui/screens/profile/settings/settings_screen.dart';
import 'package:suxingchahui/screens/profile/mygames/my_games_screen.dart';
import 'package:suxingchahui/screens/admin/admin_dashboard.dart';
import 'package:suxingchahui/screens/checkin/checkin_screen.dart';
import 'package:suxingchahui/screens/profile/follow/user_follows_screen.dart';
import 'package:suxingchahui/screens/activity/activity_feed_screen.dart';
import 'package:suxingchahui/screens/activity/activity_detail_screen.dart';
import 'package:suxingchahui/screens/activity/my_activity_feed_screen.dart';
import 'package:suxingchahui/screens/common/route_error_screen.dart';

class AppRoutes {
  // 路由常量 (虽然不再直接使用，但保留以供参考)
  static const String home = '/';
  static const String about = '/about';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String gameDetail = '/game/detail';
  static const String hotGames = '/hot-games';
  static const String latestGames = '/latest-games';
  static const String gamesList = '/games';
  static const String externalLinks = '/links';
  static const String profile = '/profile';
  static const String searchGame = '/search-game';
  static const String searchPost = '/search-post';
  static const String openProfile = '/open-profile';
  static const String addGame = '/game/add';
  static const String editGame = '/game/edit';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String myPosts = '/my-posts';
  static const String settingPage = '/settings';
  static const String wantToPlayGames = '/collections/want-to-play';
  static const String playingGames = '/collections/playing';
  static const String playedGames = '/collections/played';
  static const String allCollections = '/collections/all';
  static const String myCollections = '/my-collections';
  static const String myGames = '/my-games';
  static const String forum = '/forum';
  static const String postDetail = '/forum/post';
  static const String createPost = '/forum/post/create';
  static const String editPost = '/forum/post/edit';
  static const String adminDashboard = '/admin';
  static const String tags = '/tags';
  static const String checkin = '/checkin';
  static const String userFollows = '/user-follows';
  static const String activityFeed = '/activity-feed';
  static const String userActivities = '/user-activities';
  static const String activityDetail = '/activity/detail';
  static const String webView = '/webview';
  static const String message = '/message';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AuthProvider authProvider,
    UserService userService,
    PostService postService,
    GameService gameService,
    UserFollowService followService,
    ActivityService activityService,
    LinkToolService linkToolService,
    MessageService messageService,
    GameCollectionService gameCollectionService,
    UserInfoProvider infoProvider,
    InputStateService inputStateService,
    EmailService emailService,
    UserCheckInService checkInService,
    AnnouncementService announcementService,
    MaintenanceService maintenanceService,
    GameListFilterProvider gameListFilterProvider,
    SidebarProvider sidebarProvider,
    PostListFilterProvider postListFilterProvider,
    RateLimitedFileUpload fileUploadService,
  ) {
    String routeName = settings.name ?? '/'; // 默认路由，防止 settings.name 为 null

    switch (routeName) {
      // 在 app_routes.dart 中更新根路由的处理
      case home:
        // 检查是否有传递标签索引参数
        if (settings.arguments != null) {
          if (settings.arguments is Map<String, dynamic> &&
              (settings.arguments as Map<String, dynamic>)
                  .containsKey('tab_index')) {
            // 获取标签索引
            final int tabIndex = (settings.arguments
                as Map<String, dynamic>)['tab_index'] as int;

            // 返回主页面并在下一帧设置标签索引
            return MaterialPageRoute(builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NavigationUtils.navigateToHome(sidebarProvider, context,
                    tabIndex: tabIndex);
              });
              return HomeScreen(
                infoProvider: infoProvider,
                authProvider: authProvider,
                followService: followService,
                gameService: gameService,
                postService: postService,
              );
            });
          }
        }

        // 默认行为，无参数时直接返回主页面
        return MaterialPageRoute(
            builder: (_) => HomeScreen(
                  infoProvider: infoProvider,
                  authProvider: authProvider,
                  followService: followService,
                  gameService: gameService,
                  postService: postService,
                ));
      case about:
        return MaterialPageRoute(builder: (_) => AboutScreen());
      case login:
        return MaterialPageRoute(
            builder: (_) => LoginScreen(
                  sidebarProvider: sidebarProvider,
                  authProvider: authProvider,
                  inputStateService: inputStateService,
                ));
      case register:
        return MaterialPageRoute(
            builder: (_) => RegisterScreen(
                  emailService: emailService,
                  inputStateService: inputStateService,
                  authProvider: authProvider,
                  userService: userService,
                ));
      case forgotPassword:
        return MaterialPageRoute(
            builder: (_) => ForgotPasswordScreen(
                  authProvider: authProvider,
                  inputStateService: inputStateService,
                  infoProvider: infoProvider,
                  emailService: emailService,
                ));
      case resetPassword:
        final arguments = settings.arguments;
        if (arguments is! String || (arguments).isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.missingParameter(
              sidebarProvider,
              paramName: '邮箱',
              onAction: () => NavigationUtils.pushNamed(_, forgotPassword),
            ),
          );
        }
        final String email = arguments;
        return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
                  email: email,
                  authProvider: authProvider,
                  inputStateService: inputStateService,
                  userService: userService,
                ));
      case searchGame:
        return MaterialPageRoute(
            builder: (_) => SearchGameScreen(
                  gameService: gameService,
                  userService: userService,
                ));

      case gameDetail:
        final arguments = settings.arguments;
        String? gameId;

        if (arguments is String) {
          gameId = arguments;
        } else if (arguments is Game) {
          gameId = arguments.id;
        }

        // 如果 gameId 为空，返回错误页面
        if (gameId == null || gameId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '游戏',
              onAction: () => NavigationUtils.pushNamed(_, gamesList),
            ),
          );
        }
        // 此时 gameId 一定非空，可以安全地传递给 GameDetailScreen
        return MaterialPageRoute(
          builder: (_) => GameDetailScreen(
            gameId: gameId,
            inputStateService: inputStateService,
            sidebarProvider: sidebarProvider,
            gameListFilterProvider: gameListFilterProvider,
            authProvider: authProvider,
            infoProvider: infoProvider,
            gameService: gameService,
            followService: followService,
            gameCollectionService: gameCollectionService,
          ),
        );
      case gamesList:
        final arguments = settings.arguments;
        String? selectedTag;
        if (arguments is String) {
          selectedTag = arguments;
        } else {}
        return MaterialPageRoute(
            builder: (_) => GamesListScreen(
                  selectedTag: selectedTag,
                  gameService: gameService,
                  gameListFilterProvider: gameListFilterProvider,
                  authProvider: authProvider,
                ));
      case hotGames:
        return MaterialPageRoute(
            builder: (_) => HotGamesScreen(
                  authProvider: authProvider,
                  gameService: gameService,
                ));
      case latestGames:
        return MaterialPageRoute(
            builder: (_) => LatestGamesScreen(
                  authProvider: authProvider,
                  gameService: gameService,
                ));
      case externalLinks:
        return MaterialPageRoute(
            builder: (_) => LinksToolsScreen(
                  authProvider: authProvider,
                  inputStateService: inputStateService,
                  linkToolService: linkToolService,
                ));

      case profile:
        return MaterialPageRoute(
            builder: (_) => ProfileScreen(
                  sidebarProvider: sidebarProvider,
                  inputStateService: inputStateService,
                  userService: userService,
                  authProvider: authProvider,
                  fileUpload: fileUploadService,
                ));
      case openProfile:
        if (settings.arguments is! String ||
            (settings.arguments as String).isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '用户',
              onAction: () => NavigationUtils.pop(_),
            ),
          );
        }
        final String userId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => OpenProfileScreen(
                  userId: userId,
                  userService: userService,
                  authProvider: authProvider,
                  gameService: gameService,
                  postService: postService,
                  followService: followService,
                ));

      case addGame:
        return MaterialPageRoute(
            builder: (_) => AddGameScreen(
                  fileUpload: fileUploadService,
                  sidebarProvider: sidebarProvider,
                  infoProvider: infoProvider,
                  gameCollectionService: gameCollectionService,
                  authProvider: authProvider,
                  gameListFilterProvider: gameListFilterProvider,
                  gameService: gameService,
                  followService: followService,
                ));
      case editGame:
        final arguments = settings.arguments;
        if (arguments is! String) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.missingParameter(
              sidebarProvider,
              paramName: '游戏数据',
              onAction: () => NavigationUtils.pushNamed(_, gamesList),
            ),
          );
        }
        final String gameId = arguments;
        return MaterialPageRoute(
          builder: (_) => EditGameScreen(
            gameId: gameId,
            fileUpload: fileUploadService,
            sidebarProvider: sidebarProvider,
            authProvider: authProvider,
            gameService: gameService,
            followService: followService,
            infoProvider: infoProvider,
            gameCollectionService: gameCollectionService,
            gameListFilterProvider: gameListFilterProvider,
          ),
        );
      case checkin:
        return MaterialPageRoute(
            builder: (_) => CheckInScreen(
                  checkInService: checkInService,
                  infoProvider: infoProvider,
                  followService: followService,
                  authProvider: authProvider,
                ));
      case favorites:
        return MaterialPageRoute(
            builder: (_) => FavoritesScreen(
                  authProvider: authProvider,
                  infoProvider: infoProvider,
                  gameService: gameService,
                  followService: followService,
                  postService: postService,
                ));
      case history:
        return MaterialPageRoute(
            builder: (_) => HistoryScreen(
                  followService: followService,
                  infoProvider: infoProvider,
                  authProvider: authProvider,
                  gameService: gameService,
                  postService: postService,
                ));
      case myPosts:
        return MaterialPageRoute(
            builder: (_) => MyPostsScreen(
                  infoProvider: infoProvider,
                  authProvider: authProvider,
                  postService: postService,
                  followService: followService,
                ));
      case settingPage:
        return MaterialPageRoute(
            builder: (_) => SettingsScreen(
                  gameService: gameService,
                  postService: postService,
                  authProvider: authProvider,
                ));
      case myCollections:
        return MaterialPageRoute(
            builder: (_) => GameCollectionScreen(
                  sidebarProvider: sidebarProvider,
                  gameCollectionService: gameCollectionService,
                  authProvider: authProvider,
                ));
      case activityFeed:
        return MaterialPageRoute(
            builder: (_) => ActivityFeedScreen(
                  inputStateService: inputStateService,
                  infoProvider: infoProvider,
                  activityService: activityService,
                  authProvider: authProvider,
                  followService: followService,
                ));

      case userActivities:
        if (settings.arguments is! String ||
            (settings.arguments as String).isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '用户',
              onAction: () => NavigationUtils.pop(_),
            ),
          );
        }
        final String userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => MyActivityFeedScreen(
            infoProvider: infoProvider,
            inputStateService: inputStateService,
            authProvider: authProvider,
            activityService: activityService,
            followService: followService,
            userId: userId,
            title: '用户动态',
          ),
        );

      case activityDetail:
        final arguments = settings.arguments;
        String? activityId;
        UserActivity? activity;

        if (arguments is String) {
          activityId = arguments;
        } else if (arguments is Map<String, dynamic>) {
          final id = arguments['activityId'];
          if (id is String) {
            activityId = id;
          } else {
            // 如果ID不是String类型，返回错误页面
            return MaterialPageRoute(
              builder: (_) => RouteErrorScreen.invalidId(
                sidebarProvider,
                resourceType: '动态',
                onAction: () => NavigationUtils.pushNamed(_, activityFeed),
              ),
            );
          }
          activity = arguments['activity'] as UserActivity?;
        } else {
          // 如果参数类型不正确，返回错误页面
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.missingParameter(
              sidebarProvider,
              paramName: '动态ID',
              onAction: () => NavigationUtils.pushNamed(_, activityFeed),
            ),
          );
        }

        // 如果 activityId 为空，返回错误页面
        if (activityId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '动态',
              onAction: () => NavigationUtils.pushNamed(_, activityFeed),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(
            authProvider: authProvider,
            activityService: activityService,
            followService: followService,
            inputStateService: inputStateService,
            infoProvider: infoProvider,
            activityId: activityId.toString(),
            activity: activity,
          ),
        );

      case wantToPlayGames:
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            sidebarProvider: sidebarProvider,
            gameCollectionService: gameCollectionService,
            authProvider: authProvider,
            collectionType: 'wantToPlay',
            title: '想玩的游戏',
          ),
        );
      case playingGames:
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            sidebarProvider: sidebarProvider,
            gameCollectionService: gameCollectionService,
            authProvider: authProvider,
            collectionType: 'playing',
            title: '在玩的游戏',
          ),
        );
      case playedGames:
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            sidebarProvider: sidebarProvider,
            gameCollectionService: gameCollectionService,
            authProvider: authProvider,
            collectionType: 'played',
            title: '玩过的游戏',
          ),
        );
      case allCollections:
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            sidebarProvider: sidebarProvider,
            gameCollectionService: gameCollectionService,
            authProvider: authProvider,
            collectionType: 'all',
            title: '全部收藏',
          ),
        );
      case searchPost:
        return MaterialPageRoute(
            builder: (_) => SearchPostScreen(
                  infoProvider: infoProvider,
                  authProvider: authProvider,
                  followService: followService,
                  postService: postService,
                  userService: userService,
                ));
      case forum:
        final String? tag = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) => PostListScreen(
                  tag: tag,
                  postListFilterProvider: postListFilterProvider,
                  infoProvider: infoProvider,
                  postService: postService,
                  authProvider: authProvider,
                  followService: followService,
                ));
      case postDetail:
        if (settings.arguments is! String ||
            (settings.arguments as String).isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '帖子',
              onAction: () => NavigationUtils.pushNamed(_, forum),
            ),
          );
        }
        final String postId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => PostDetailScreen(
                  postId: postId,
                  postListFilterProvider: postListFilterProvider,
                  sidebarProvider: sidebarProvider,
                  inputStateService: inputStateService,
                  infoProvider: infoProvider,
                  authProvider: authProvider,
                  postService: postService,
                  followService: followService,
                ));
      case createPost:
        return MaterialPageRoute(
            builder: (_) => CreatePostScreen(
                  inputStateService: inputStateService,
                  postService: postService,
                  authProvider: authProvider,
                ));
      case editPost:
        if (settings.arguments is! String ||
            (settings.arguments as String).isEmpty) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.invalidId(
              sidebarProvider,
              resourceType: '帖子',
              onAction: () => NavigationUtils.pushNamed(_, forum),
            ),
          );
        }
        final String postId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => EditPostScreen(
                  postId: postId,
                  inputStateService: inputStateService,
                  postService: postService,
                  authProvider: authProvider,
                ));
      case adminDashboard:
        return MaterialPageRoute(
            builder: (_) => AdminDashboard(
                  fileUpload: fileUploadService,
                  maintenanceService: maintenanceService,
                  announcementService: announcementService,
                  userService: userService,
                  gameService: gameService,
                  linkToolService: linkToolService,
                  authProvider: authProvider,
                  inputStateService: inputStateService,
                ));
      case myGames:
        return MaterialPageRoute(
            builder: (_) => MyGamesScreen(
                  gameService: gameService,
                  authProvider: authProvider,
                ));
      case userFollows:
        if (settings.arguments is! Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.missingParameter(
              sidebarProvider,
              paramName: '用户关注',
              onAction: () => NavigationUtils.pop(_),
            ),
          );
        }

        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;

        if (args['userId'] == null || args['username'] == null) {
          return MaterialPageRoute(
            builder: (_) => RouteErrorScreen.missingParameter(
              sidebarProvider,
              paramName: '用户ID或用户名',
              onAction: () => NavigationUtils.pop(_),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => UserFollowsScreen(
            infoProvider: infoProvider,
            authProvider: authProvider,
            followService: followService,
            userId: args['userId'],
            username: args['username'],
            initialShowFollowing: args['initialShowFollowing'] ?? true,
          ),
        );
      case message:
        return MaterialPageRoute(
            builder: (_) => MessageScreen(
                  authProvider: authProvider,
                  messageService: messageService,
                ));
      case webView: // 处理 /webView 路由
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args.containsKey('url')) {
          final String url = args['url'];
          final String? title = args['title']; // title 是可选的
          return MaterialPageRoute(
            builder: (_) => WebViewScreen(url: url, title: title),
          );
        }
        // 如果参数不正确，返回错误页面
        return MaterialPageRoute(
          builder: (_) => RouteErrorScreen.missingParameter(
            sidebarProvider,
            paramName: 'URL参数',
            onAction: () => NavigationUtils.pop(_), // 返回上一页
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(
            sidebarProvider: sidebarProvider,
          ),
        );
    }
  }
}
