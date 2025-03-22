// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post/post.dart';
import '../../services/main/forum/forum_service.dart';
import '../../services/main/user/user_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/components/loading/loading_route_observer.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/components/form/postform/config/post_taglists.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/forum/card/post_card.dart';
import '../../widgets/components/screen/forum/tag_filter.dart';
import '../../widgets/components/screen/forum/panel/forum_right_panel.dart';
import '../../widgets/components/common/error_widget.dart';
import '../../widgets/components/common/loading_widget.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with WidgetsBindingObserver {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final List<String> _tags = PostTagLists.filterTags;
  String _selectedTag = '全部';
  List<Post>? _posts;
  String? _errorMessage;

  // 添加刷新控制器
  final RefreshController _refreshController = RefreshController();

  // 控制右侧面板显示状态
  bool _showRightPanel = true;

  // 添加路由观察者引用
  LoadingRouteObserver? _routeObserver;
  // 追踪是否需要刷新
  bool _needsRefresh = false;

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }

    // 添加应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 获取路由观察者引用
    final observers = Navigator.of(context).widget.observers;
    _routeObserver = observers.whereType<LoadingRouteObserver>().firstOrNull;

    // 初始加载帖子
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  void dispose() {
    // 移除应用生命周期观察者
    WidgetsBinding.instance.removeObserver(this);

    // 释放刷新控制器
    _refreshController.dispose();
    super.dispose();
  }

  // 实现应用生命周期状态监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用恢复前台时，如果需要刷新，则刷新数据
    if (state == AppLifecycleState.resumed && _needsRefresh) {
      _refreshData();
      _needsRefresh = false;
    } else if (state == AppLifecycleState.paused) {
      // 标记应用进入后台时可能需要刷新
      _needsRefresh = true;
    }
  }

  // 添加一个清除缓存并刷新的方法
  Future<void> _clearCacheAndRefresh() async {
    try {
      // 清除指定标签的帖子缓存
      final tag = _selectedTag == '全部' ? null : _selectedTag;
      await _forumService.clearForumCache(tag);
      await _loadPosts();
    } catch (e) {
      print('清除缓存失败: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      if (_routeObserver != null) {
        _routeObserver!.showLoading();
      }

      final posts = await _forumService
          .getPosts(
        tag: _selectedTag == '全部' ? null : _selectedTag,
      )
          .first;

      if (mounted) {
        setState(() {
          _posts = posts;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
          _posts = [];
        });
      }
    } finally {
      if (_routeObserver != null) {
        _routeObserver!.hideLoading();
      }

      // 完成刷新
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _refreshData() async {
    try {
      if (_routeObserver != null) {
        _routeObserver!.showLoading();
      }

      // 清除论坛缓存
      await _clearCacheAndRefresh();
    } finally {
      if (_routeObserver != null) {
        _routeObserver!.hideLoading();
      }
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

  void _navigateToCreatePost() async {
    // 使用 await 等待导航结果
    final result = await Navigator.pushNamed(context, AppRoutes.createPost);

    // 如果返回的结果是 true，表示创建了新帖子，刷新数据
    if (result == true) {
      _refreshData();
    }
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
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: '刷新帖子',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: _navigateToCreatePost,
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
    // 使用新的错误组件处理错误状态
    if (_errorMessage != null) {
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _refreshData,
        title: '加载错误',
      );
    }

    // 使用新的加载组件处理加载状态
    if (_posts == null) {
      return LoadingWidget.fullScreen(message: '正在加载帖子...');
    }

    // 处理空列表状态
    if (_posts!.isEmpty) {
      return CustomErrorWidget(
        errorMessage: '暂无帖子',
        onRetry: _refreshData,
        icon: Icons.message_outlined,
        title: '没有帖子',
        retryText: '刷新',
      );
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
          isDesktopLayout: false,
          onDeleted: () {
            // 添加删除回调
            _refreshData();
          },
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

          isDesktopLayout: true,
          onDeleted: () {
            // 添加删除回调
            _refreshData();
          },
        );
      },
    );
  }
}

// 保留原有的刷新控制器类
class RefreshController {
  VoidCallback? _onRefreshCompleted;

  void refreshCompleted() {
    if (_onRefreshCompleted != null) {
      _onRefreshCompleted!();
    }
  }

  void dispose() {
    _onRefreshCompleted = null;
  }
}