import 'package:flutter/material.dart';
// 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/db_connection_service.dart'; // 引入 DBConnectionService
import 'services/user_service.dart';
import 'services/game_service.dart';
import 'services/history_service.dart';
import 'services/forum_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'layouts/main_layout.dart';
import 'layouts/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 根据编译环境加载对应的环境变量文件
  //const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  //await dotenv.load(fileName: '.env.$env');

  // 初始化数据库连接
  await DBConnectionService().initialize();


  final authProvider = AuthProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 现有的 providers...
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => GameService()),
        Provider(create: (_) => HistoryService()),
        Provider(create: (_) => ForumService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '宿星茶会',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              // 在这里包裹 AppBackground
              return AppBackground(child: child ?? Container());
            },
            home: MainLayout(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}