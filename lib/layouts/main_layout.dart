// lib/layouts/main_layout.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/home/home_screen.dart';
import '../screens/game/games_list_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/forum/forum_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/search_screen.dart';
import '../services/user_service.dart';
import '../widgets/logo/app_logo.dart';

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
      ForumScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: AppLogo(size: 48),
          ),
        ),
        title: _buildSearchBar(),
        actions: [_buildProfileAvatar()],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                elevation: 0,
                backgroundColor: Colors.grey[50],
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Color(0xFF2979FF),
                unselectedItemColor: Colors.grey[400],
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12,
                ),
                items: [
                  _buildNavItem(Icons.home_rounded, '首页'),
                  _buildNavItem(Icons.games_rounded, '游戏'),
                  _buildNavItem(Icons.link_rounded, '外部'),
                  _buildNavItem(Icons.forum_rounded, '论坛'),
                  _buildNavItem(Icons.person_rounded, '我的'),
                ],
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF2979FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12),

          ),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '搜索游戏...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return StreamBuilder<String?>(
      stream: _userService.getCurrentUserProfile().map((user) => user?.avatar),
      builder: (context, snapshot) {
        final authProvider = Provider.of<AuthProvider>(context);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () {
              if (authProvider.isLoggedIn) {
                setState(() => _currentIndex = 4);
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF2979FF),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[100],
                backgroundImage: snapshot.hasData && snapshot.data != null
                    ? NetworkImage(snapshot.data!)
                    : null,
                child: !snapshot.hasData || snapshot.data == null
                    ? Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Colors.grey[400],
                )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}