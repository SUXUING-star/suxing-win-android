// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/game/games_list_screen.dart';
import '../screens/linkstools_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/forum/forum_screen.dart'; // 新增论坛屏幕导入
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/search_screen.dart';
import '../services/user_service.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final UserService _userService = UserService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      GamesListScreen(),
      LinksToolsScreen(),
      ForumScreen(), // 替换原来的位置为论坛屏幕
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: _buildSearchBar(),
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: '游戏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: '外部',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum), // 新增论坛图标
            label: '论坛',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search, color: Colors.white70, size: 20),
            ),
            Text(
              '搜索游戏...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return StreamBuilder<String?>( // Changed to Stream<String?>
      stream: _userService.getCurrentUserProfile().map((user) => user?.avatar), // Extract avatar URL
      builder: (context, snapshot) {
        final authProvider = Provider.of<AuthProvider>(context);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            onPressed: () {
              if (authProvider.isLoggedIn) {
                setState(() {
                  _currentIndex = 3; // 切换到个人页面
                });
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: snapshot.hasData && snapshot.data != null
                  ? NetworkImage(snapshot.data!) // Use snapshot.data directly
                  : null,
              child: !snapshot.hasData || snapshot.data == null // Use snapshot.data directly
                  ? Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }
}