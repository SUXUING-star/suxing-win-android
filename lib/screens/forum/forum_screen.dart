// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post/post.dart';
import '../../services/main/forum/forum_service.dart';
import '../../services/main/user/user_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/components/form/postform/config/post_taglists.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/forum/post_card.dart';
import '../../widgets/components/screen/forum/tag_filter.dart';
import '../../widgets/components/screen/forum/panel/forum_right_panel.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final List<String> _tags = PostTagLists.filterTags;
  String _selectedTag = '全部';
  List<Post>? _posts;
  String? _errorMessage;

  // 控制右侧面板显示状态
  bool _showRightPanel = true;

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator
          .of(context)
          .widget
          .observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadPosts().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _forumService
          .getPosts(
        tag: _selectedTag == '全部' ? null : _selectedTag,
      )
          .first;

      setState(() {
        _posts = posts;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _posts = [];
      });
    }
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator
        .of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadPosts();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel;
    });
  }

  void _onTagSelected(String tag) {
    setState(() {
      _selectedTag = tag;
    });
    _loadPosts();
  }

  bool _isDesktop(BuildContext context) {
    return DeviceUtils.isDesktop;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: '论坛',
        actions: [
          // 只在桌面端显示右侧面板切换按钮
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: _showRightPanel ? Colors.yellow : Colors.white,
              ),
              onPressed: _toggleRightPanel,
              tooltip: _showRightPanel ? '隐藏统计面板' : '显示统计面板',
            ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createPost);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TagFilter(
            tags: _tags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),
          Expanded(
            child: isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主内容区域
        Expanded(
          child: _buildPostsList(true),
        ),

        // 右侧统计面板（只在显示时渲染）
        if (_showRightPanel && _posts != null)
          ForumRightPanel(
            currentPosts: _posts!,
            selectedTag: _selectedTag == '全部' ? null : _selectedTag,
            onTagSelected: _onTagSelected,
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildPostsList(false);
  }

  Widget _buildPostsList(bool isDesktop) {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_posts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts!.isEmpty) {
      return const Center(child: Text('暂无帖子'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: isDesktop
          ? _buildDesktopPostsGrid()
          : _buildMobilePostsList(),
    );
  }

  // 移动端帖子列表（垂直排列）
  Widget _buildMobilePostsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostCard(
          post: post,
          userService: _userService,
          isDesktopLayout: false,
        );
      },
    );
  }

  // 桌面端帖子网格 - 使用 StaggeredGridView 允许不同高度
  Widget _buildDesktopPostsGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostCard(
          post: post,
          userService: _userService,
          isDesktopLayout: true,
        );
      },
    );
  }
}