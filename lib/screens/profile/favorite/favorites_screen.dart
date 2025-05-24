// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/tabs/custom_segmented_control_tab_bar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'tabs/game_favorites_tab.dart';
import 'tabs/post_favorites_tab.dart';

class FavoritesScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final ForumService forumService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  const FavoritesScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.forumService,
    required this.followService,
    required this.infoProvider,
  });

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  // Tab控制
  late TabController _tabController;
  final List<String> _tabTitles = ['游戏', '帖子'];
  bool _hasInitializedProviders = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<bool>(
        stream: widget.authProvider.isLoggedInStream,
        initialData: widget.authProvider.isLoggedIn,
        builder: (context, authSnapshot) {
          final bool isLoggedIn =
              authSnapshot.data ?? widget.authProvider.isLoggedIn;
          if (!isLoggedIn) {
            return const LoginPromptWidget();
          }
          return Scaffold(
            appBar: const CustomAppBar(
              title: '我的喜欢',
            ),
            body: Column(
              // 使用 Column 垂直排列 Tab 控件和 TabBarView
              children: [
                CustomSegmentedControlTabBar(
                  controller: _tabController,
                  tabTitles: _tabTitles,
                  backgroundColor:
                      theme.colorScheme.surface.withSafeOpacity(0.1),
                  // 非常浅的背景，或者Colors.grey[200]
                  selectedTabColor: theme.primaryColor,
                  // 选中项的背景色
                  unselectedTabColor: Colors.transparent,
                  // 未选中项透明
                  selectedTextStyle: TextStyle(
                    color: theme.colorScheme
                        .onPrimary, // 选中文字颜色，确保与 selectedTabColor 对比清晰
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedTextStyle: TextStyle(
                    color: theme.textTheme.bodyLarge?.color
                            ?.withSafeOpacity(0.7) ??
                        Colors.grey[700], // 未选中文字颜色
                    fontWeight: FontWeight.normal,
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                  // 更圆润的圆角
                  tabPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                ),
                Expanded(
                  // TabBarView 需要 Expanded 来填充剩余空间
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      GameFavoritesTab(
                        widget.authProvider.currentUser,
                        widget.gameService,
                      ),
                      PostFavoritesTab(
                        widget.authProvider.currentUser,
                        widget.forumService,
                        widget.followService,
                        widget.infoProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFab(context),
          );
        });
  }
}
