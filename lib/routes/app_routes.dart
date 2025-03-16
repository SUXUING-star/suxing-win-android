import 'package:flutter/material.dart';
import 'package:suxingchahui/screens/game/collection/game_collection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/common/notfound_screen.dart';
import '../screens/common/about_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/game/detail/game_detail_screen.dart';
import '../screens/game/list/hot_games_screen.dart';
import '../screens/game/list/latest_games_screen.dart';
import '../screens/game/list/games_list_screen.dart';
import '../screens/game/collection/game_collection_list_screen.dart';
import '../screens/game/edit/add_game_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/open_profile_screen.dart';
import '../models/game/game.dart';
import '../models/activity/user_activity.dart';
import '../models/post/post.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/forum/post/post_detail_screen.dart';
import '../screens/forum/post/create_post_screen.dart';
import '../screens/forum/post/edit_post_screen.dart';
import '../screens/profile/history/history_screen.dart';
import '../screens/profile/myposts/my_posts_screen.dart';
import '../screens/profile/favorite/favorites_screen.dart';
import '../screens/profile/settings/settings_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/ai/gemini_chat_screen.dart';
import '../screens/checkin/checkin_screen.dart';
import '../screens/profile/follow/user_follows_screen.dart';
import '../screens/activity/activity_feed_screen.dart';
import '../screens/activity/activity_detail_screen.dart';
import '../screens/activity/activity_alternating_feed_screen.dart';

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
  static const String openProfile = '/open-profile';
  static const String addGame = '/game/add';
  static const String editGame = '/game/edit';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String myPosts = '/my-posts';
  static const String settings = '/settings';
  static const String wantToPlayGames = '/collections/want-to-play';
  static const String playingGames = '/collections/playing';
  static const String playedGames = '/collections/played';
  static const String allCollections = '/collections/all';
  static const String myGames = '/my-games';
  static const String forum = '/forum';
  static const String postDetail = '/forum/post';
  static const String createPost = '/forum/post/create';
  static const String editPost = '/forum/post/edit';
  static const String adminDashboard = '/admin';
  static const String tags = '/tags';
  static const String aiChat = '/ai-chat';
  static const String checkin = '/checkin';
  static const String userFollows = '/user-follows';
  static const String activityFeed = '/activity-feed';
  static const String userActivities = '/user-activities';
  static const String activityDetail = '/activity/detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String routeName = settings.name ?? '/'; // 默认路由，防止 settings.name 为 null

    switch (routeName) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/about':
        return MaterialPageRoute(builder: (_) => AboutScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case '/reset-password':
        final String email = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email));

      case '/game/detail':
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
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('错误')),
              body: Center(child: Text('无效的游戏ID')),
            ),
          );
        }
        // 此时 gameId 一定非空，可以安全地传递给 GameDetailScreen
        return MaterialPageRoute(
            builder: (_) => GameDetailScreen(gameId: gameId)
        );
      case '/games':
        return MaterialPageRoute(builder: (_) => GamesListScreen());
      case '/hot-games':
        return MaterialPageRoute(builder: (_) => HotGamesScreen());
      case '/latest-games':
        return MaterialPageRoute(builder: (_) => LatestGamesScreen());
      case '/links':
        return MaterialPageRoute(builder: (_) => LinksToolsScreen());

      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/open-profile':
        if (settings.arguments is! String) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('无效的用户ID')),
            ),
          );
        }
        final String userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OpenProfileScreen(userId: userId));

      case '/game/add':
        return MaterialPageRoute(builder: (_) => AddGameScreen());
      case '/checkin':
        return MaterialPageRoute(builder: (_) => CheckInScreen());
      case '/favorites':
        return MaterialPageRoute(builder: (_) => FavoritesScreen());
      case '/history':
        return MaterialPageRoute(builder: (_) => HistoryScreen());
      case '/my-posts':
        return MaterialPageRoute(builder: (_) => MyPostsScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case '/my-games':
        return MaterialPageRoute(builder: (_) => GameCollectionScreen());
      case '/activity-feed':
        return MaterialPageRoute(builder: (_) => const ActivityAlternatingFeedScreen());

      case '/user-activities':
        if (settings.arguments is! String) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('无效的用户ID')),
            ),
          );
        }
        final String userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ActivityAlternatingFeedScreen(
            userId: userId,
            title: '用户动态',
          ),
        );

      case '/activity/detail':
        final arguments = settings.arguments;
        String activityId;
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
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('错误')),
                body: const Center(child: Text('无效的动态ID格式')),
              ),
            );
          }
          activity = arguments['activity'] as UserActivity?;
        } else {
          // 如果参数类型不正确，返回错误页面
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(child: Text('无效的参数类型')),
            ),
          );
        }

        // 如果 activityId 为空，返回错误页面
        if (activityId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(child: Text('无效的动态ID')),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(
            activityId: activityId,
            activity: activity,
          ),
        );

      case '/collections/want-to-play':
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            collectionType: 'wantToPlay',
            title: '想玩的游戏',
          ),
        );
      case '/collections/playing':
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            collectionType: 'playing',
            title: '在玩的游戏',
          ),
        );
      case '/collections/played':
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            collectionType: 'played',
            title: '玩过的游戏',
          ),
        );
      case '/collections/all':
        return MaterialPageRoute(
          builder: (_) => GameCollectionListScreen(
            collectionType: 'all',
            title: '全部收藏',
          ),
        );
      case '/forum':
        final String? tag = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ForumScreen(tag: tag));
      case '/forum/post':
        if (settings.arguments is! String) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('无效的帖子ID')),
            ),
          );
        }
        final String postId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: postId));
      case '/forum/post/create':
        return MaterialPageRoute(builder: (_) => CreatePostScreen());
      case '/forum/post/edit':
        if (settings.arguments is! Post) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('无效的帖子数据')),
            ),
          );
        }
        final Post post = settings.arguments as Post;
        return MaterialPageRoute(builder: (_) => EditPostScreen(post: post));
      case '/admin':
        return MaterialPageRoute(builder: (_) => AdminDashboard());
      case '/user-follows':
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => UserFollowsScreen(
            userId: args['userId'],
            username: args['username'],
            initialShowFollowing: args['initialShowFollowing'] ?? true,
          ),
        );
      case aiChat:
        return MaterialPageRoute(
          builder: (_) => const GeminiChatScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}