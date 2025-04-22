// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import 'tabs/game_favorites_tab.dart';
import 'tabs/post_favorites_tab.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  // Tab控制
  late TabController _tabController;
  final List<String> _tabTitles = ['游戏收藏', '帖子收藏'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '我的收藏',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // 通知当前激活的Tab刷新
              if (_tabController.index == 0) {
                GameFavoritesTab.refreshGameData();
              } else {
                PostFavoritesTab.refreshPostData();
              }
            },
            tooltip: '刷新收藏',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 游戏收藏标签页 - 使用原有布局
          GameFavoritesTab(),
          // 帖子收藏标签页 - 新布局
          PostFavoritesTab(),
        ],
      ),
    );
  }
}