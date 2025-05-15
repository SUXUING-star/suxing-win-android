// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/tabs/custom_segmented_control_tab_bar.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import 'tabs/game_favorites_tab.dart';
import 'tabs/post_favorites_tab.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  // Tab控制
  late TabController _tabController;
  final List<String> _tabTitles = ['游戏', '帖子'];

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

  Widget _buildFab(BuildContext context) {
    return GenericFloatingActionButton(
      icon: Icons.refresh,
      heroTag: "刷新收藏",
      onPressed: () {
        // 通知当前激活的Tab刷新
        if (_tabController.index == 0) {
          GameFavoritesTab.refreshGameData();
        } else {
          PostFavoritesTab.refreshPostData();
        }
      },
      tooltip: '刷新收藏',
    );
  }

  Widget _buildBottomTabBar(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(

      appBar: CustomAppBar(
        title: '我的喜欢',
      ),
      body: Column( // 使用 Column 垂直排列 Tab 控件和 TabBarView
        children: [
          CustomSegmentedControlTabBar(
            controller: _tabController,
            tabTitles: _tabTitles,
            backgroundColor: theme.colorScheme.surface.withOpacity(0.1), // 非常浅的背景，或者Colors.grey[200]
            selectedTabColor: theme.primaryColor, // 选中项的背景色
            unselectedTabColor: Colors.transparent, // 未选中项透明
            selectedTextStyle: TextStyle(
              color: theme.colorScheme.onPrimary, // 选中文字颜色，确保与 selectedTabColor 对比清晰
              fontWeight: FontWeight.w600,
            ),
            unselectedTextStyle: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? Colors.grey[700], // 未选中文字颜色
              fontWeight: FontWeight.normal,
            ),
            borderRadius: BorderRadius.circular(25.0), // 更圆润的圆角
            tabPadding: const EdgeInsets.symmetric(vertical: 12.0),
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          ),
          Expanded( // TabBarView 需要 Expanded 来填充剩余空间
            child: TabBarView(
              controller: _tabController,
              children: [
                GameFavoritesTab(),
                PostFavoritesTab(),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: _buildFab(context),
    );
  }
}
