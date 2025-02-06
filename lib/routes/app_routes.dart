import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/common/notfound_screen.dart';
import '../screens/common/about_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/game/game_detail_screen.dart';
import '../screens/home/hot_games_screen.dart';
import '../screens/home/latest_games_screen.dart';
import '../screens/game/games_list_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/game/add_game_screen.dart';
import '../models/game.dart';
import '../models/post.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/forum/post_detail_screen.dart';
import '../screens/forum/create_post_screen.dart';
import '../screens/forum/edit_post_screen.dart';
import '../screens/profile/history_screen.dart';
import '../screens/profile/my_posts_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/profile/settings_screen.dart';

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
  static const String addGame = '/game/add';
  static const String editGame = '/game/edit';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String myPosts = '/my-posts';
  static const String settings = '/settings';
  static const String forum = '/forum';
  static const String postDetail = '/forum/post';
  static const String createPost = '/forum/post/create';
  static const String editPost = '/forum/post/edit';

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
        if (settings.arguments is! Game) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('无效的游戏数据')),
            ),
          );
        }
        final Game game = settings.arguments as Game;
        return MaterialPageRoute(builder: (_) => GameDetailScreen(game: game));
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
      case '/game/add':
        return MaterialPageRoute(builder: (_) => AddGameScreen());
      case '/favorites':
        return MaterialPageRoute(builder: (_) => FavoritesScreen());
      case '/history':
        return MaterialPageRoute(builder: (_) => HistoryScreen());
      case '/my-posts':
        return MaterialPageRoute(builder: (_) => MyPostsScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
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
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}
