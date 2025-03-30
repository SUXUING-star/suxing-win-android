// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // 确保引入
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../models/post/post.dart';
import '../../services/main/forum/forum_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/components/loading/loading_route_observer.dart';
import '../../widgets/components/form/postform/config/post_taglists.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/forum/card/post_card.dart';
import '../../widgets/components/screen/forum/tag_filter.dart';
import '../../widgets/components/screen/forum/panel/forum_right_panel.dart';
import '../../widgets/components/screen/forum/panel/forum_left_panel.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with WidgetsBindingObserver {
  final ForumService _forumService = ForumService();
  final List<String> _tags = PostTagLists.filterTags;
  String _selectedTag = '全部';
  List<Post>? _posts;
  String? _errorMessage;

  // 使用你提供的简单 RefreshController
  final RefreshController _refreshController = RefreshController();

  // 控制面板显示状态 (用户意图)
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  // 添加路由观察者引用
  LoadingRouteObserver? _routeObserver;
  // 追踪是否需要刷新
  bool _needsRefresh = false;

  // --- 屏幕宽度阈值定义 ---
  // 这些值需要根据你的侧边栏实际宽度和内容区的最小舒适宽度进行调整
  static const double _hideRightPanelThreshold = 950.0; // 低于此宽度隐藏右侧栏
  static const double _hideLeftPanelThreshold = 750.0;  // 低于此宽度隐藏左侧栏

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }
    // 初始加载帖子放在 didChangeDependencies 的 PostFrameCallback 中更安全
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observers = NavigationUtils.of(context).widget.observers;
    _routeObserver = observers.whereType<LoadingRouteObserver>().firstOrNull;

    // 确保只在首次构建或依赖变化后执行一次初始加载
    if (_posts == null && _errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // 检查 mounted 状态
          _loadPosts();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsRefresh) {
      _refreshData();
      _needsRefresh = false;
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true;
    }
  }

  Future<void> _clearCacheAndRefresh() async {
    try {
      final tag = _selectedTag == '全部' ? null : _selectedTag;
      await _forumService.clearForumCache(tag);
      // 清除缓存后由 _refreshData 调用 _loadPosts
    } catch (e) {
      print('清除缓存失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '清除缓存失败: $e';
          // 清除缓存失败时也清空帖子列表，避免显示旧数据
          _posts = [];
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    // 防止并发加载或在处理错误时加载
    if (_routeObserver?.isLoading == true || _errorMessage != null) return;

    setState(() {
      _errorMessage = null; // 开始加载前清除错误信息
      // 可以选择在加载时不清空 _posts，避免闪烁，加载指示器会覆盖
      // _posts = null;
    });

    try {
      _routeObserver?.showLoading();

      final posts = await _forumService
          .getPosts(tag: _selectedTag == '全部' ? null : _selectedTag)
          .first; // 假设 getPosts 返回 Stream<List<Post>>

      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载帖子失败: $e';
          _posts = []; // 加载失败设置为空列表
        });
      }
    } finally {
      if (mounted) {
        _routeObserver?.hideLoading();
        // 完成刷新（如果使用了下拉刷新）
        _refreshController.refreshCompleted();
      }
    }
  }

  Future<void> _refreshData() async {
    // 显示加载状态
    _routeObserver?.showLoading();
    // 清空当前错误信息和帖子，准备刷新
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _posts = null; // 清空帖子以显示 LoadingWidget
      });
    }

    try {
      // 先清除缓存
      await _clearCacheAndRefresh();
      // 如果清除缓存没有出错，则加载新帖子
      if (_errorMessage == null && mounted) {
        await _loadPosts();
      }
    } catch (e) {
      // 捕获 _clearCacheAndRefresh 或 _loadPosts 中的异常
      if (mounted) {
        setState(() {
          _errorMessage = '刷新失败: $e';
          _posts = []; // 刷新失败也清空
        });
      }
    } finally {
      // 确保加载状态被隐藏，即使发生错误
      if (mounted) {
        _routeObserver?.hideLoading();
        _refreshController.refreshCompleted();
      }
    }
  }

  // 切换用户意图
  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel;
    });
  }

  void _toggleLeftPanel() {
    setState(() {
      _showLeftPanel = !_showLeftPanel;
    });
  }

  void _onTagSelected(String tag) {
    if (_selectedTag == tag) return; // 避免重复加载
    setState(() {
      _selectedTag = tag;
      _posts = null; // 清空帖子以显示加载状态
      _errorMessage = null;
    });
    _loadPosts(); // 切换标签后加载帖子
  }

  // 判断是否为桌面环境 (可以根据需要调整逻辑)
  bool _isDesktop(BuildContext context) {
    // 使用 DeviceUtils 或 MediaQuery 判断
    // return DeviceUtils.isDesktop;
    // 或者基于宽度判断
    return MediaQuery.of(context).size.width > 600; // 示例：宽度大于600认为是桌面布局
  }

  void _navigateToCreatePost() async {
    final result = await NavigationUtils.pushNamed(context, AppRoutes.createPost);
    if (result == true && mounted) {
      _refreshData(); // 创建成功后刷新数据
    }
  }

  // 注意：这个方法现在没在 PostCard 调用处使用，点击跳转逻辑应在 PostCard 内部或通过回调实现
  void _navigateToPostDetail(Post post) async {
    final result = await NavigationUtils.pushNamed(
        context,
        AppRoutes.postDetail,
        arguments: post.id
    );
    if (result == true && mounted) {
      _refreshData(); // 详情页有更新后刷新数据
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(context);

    // --- 动态计算侧边栏实际显示状态 ---
    final bool canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth = screenWidth >= _hideRightPanelThreshold;

    final bool actuallyShowLeftPanel = isDesktop && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel = isDesktop && _showRightPanel && canShowRightPanelBasedOnWidth;

    // 获取主题颜色用于按钮高亮
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54; // 宽度不足时按钮颜色
    final Color enabledColor = Colors.white; // 未选中时按钮颜色

    return Scaffold(
      appBar: CustomAppBar(
        title: '论坛',
        actions: [
          // --- 更新 AppBar 按钮逻辑 ---
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.menu,
                // 根据是否实际显示来决定颜色
                color: actuallyShowLeftPanel ? secondaryColor : (_showLeftPanel ? disabledColor : enabledColor),
              ),
              // 只有在宽度足够时才允许点击切换
              onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
              tooltip: _showLeftPanel
                  ? (canShowLeftPanelBasedOnWidth ? '隐藏分类面板' : '屏幕宽度不足')
                  : (canShowLeftPanelBasedOnWidth ? '显示分类面板' : '屏幕宽度不足'),
            ),
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: actuallyShowRightPanel ? secondaryColor : (_showRightPanel ? disabledColor : enabledColor),
              ),
              onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
              tooltip: _showRightPanel
                  ? (canShowRightPanelBasedOnWidth ? '隐藏统计面板' : '屏幕宽度不足')
                  : (canShowRightPanelBasedOnWidth ? '显示统计面板' : '屏幕宽度不足'),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData, // 使用包含清缓存的刷新
            tooltip: '刷新帖子',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: _navigateToCreatePost,
                  tooltip: '发布新帖子',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 仅移动端显示水平标签栏
          if (!isDesktop)
            TagFilter(
              tags: _tags,
              selectedTag: _selectedTag,
              onTagSelected: _onTagSelected,
            ),
          Expanded(
            child: isDesktop
            // 传递实际显示状态
                ? _buildDesktopLayout(actuallyShowLeftPanel, actuallyShowRightPanel)
                : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  // 桌面布局，接收实际显示状态
  Widget _buildDesktopLayout(bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 条件渲染左侧面板
        if (actuallyShowLeftPanel)
          ForumLeftPanel(
            tags: _tags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),

        // 主内容区域
        Expanded(
          // 传递实际显示状态给帖子列表
          child: _buildPostsList(true, actuallyShowLeftPanel, actuallyShowRightPanel),
        ),

        // 条件渲染右侧面板
        if (actuallyShowRightPanel && _posts != null && _posts!.isNotEmpty) // 确保有帖子数据再显示
          ForumRightPanel(
            currentPosts: _posts!,
            selectedTag: _selectedTag == '全部' ? null : _selectedTag,
            onTagSelected: _onTagSelected, // 如果右侧面板需要切换标签
          ),
      ],
    );
  }

  // 移动布局
  Widget _buildMobileLayout() {
    // 移动布局使用 RefreshIndicator 包裹
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _buildPostsList(false), // 不传递侧边栏状态
    );
  }

  // 构建帖子列表（可能是网格或列表）
  Widget _buildPostsList(bool isDesktop, [bool actuallyShowLeftPanel = false, bool actuallyShowRightPanel = false]) {
    // 1. 处理错误状态
    if (_errorMessage != null) {
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadPosts, // 重试只加载当前标签，不清缓存
        title: '加载错误',
      );
    }

    // 2. 处理加载状态
    if (_posts == null) {
      // 使用居中 LoadingWidget，避免全屏覆盖 AppBar
      return LoadingWidget(message: '正在加载帖子...');
    }

    // 3. 处理空列表状态
    if (_posts!.isEmpty) {
      return CustomErrorWidget(
        errorMessage: '该分类下暂无帖子',
        onRetry: _refreshData, // 空列表时允许用户刷新（可能清缓存）
        icon: Icons.message_outlined,
        title: '没有帖子',
        retryText: '刷新',
      );
    }

    // 4. 根据平台构建列表或网格 (注意：移除了这里的 RefreshIndicator)
    return isDesktop
        ? _buildDesktopPostsGrid(actuallyShowLeftPanel, actuallyShowRightPanel)
        : _buildMobilePostsList();
  }

  // 构建移动端帖子列表（垂直）
  Widget _buildMobilePostsList() {
    return ListView.builder(
      // 为了配合 RefreshIndicator，即使内容不足一屏也要能滚动
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8), // 调整移动端边距
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        // 使用 GestureDetector 或 InkWell 处理点击跳转，并传递删除回调
        return GestureDetector(
          onTap: () => _navigateToPostDetail(post), // 使用之前定义的导航方法
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 卡片间距
            child: PostCard(
              post: post,
              isDesktopLayout: false,
              onDeleted: () {
                // 删除成功后刷新数据
                _refreshData();
              },
            ),
          ),
        );
      },
    );
  }

  // 构建桌面端帖子网格
  Widget _buildDesktopPostsGrid(bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // --- 根据实际显示的侧边栏数量，动态计算列数 ---
    int crossAxisCount;
    if (actuallyShowLeftPanel && actuallyShowRightPanel) {
      crossAxisCount = 2; // 左右都显示 -> 2列
    } else if (!actuallyShowLeftPanel && !actuallyShowRightPanel) {
      crossAxisCount = 4; // 左右都不显示 -> 4列 (可以调整)
    } else {
      crossAxisCount = 3; // 只显示一个侧边栏 -> 3列
    }

    // print("Desktop Grid Cross Axis Count: $crossAxisCount (Left: $actuallyShowLeftPanel, Right: $actuallyShowRightPanel)");

    return MasonryGridView.count(
      crossAxisCount: crossAxisCount, // 使用计算出的列数
      mainAxisSpacing: 8,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16), // 桌面边距可以大一些
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        // 桌面卡片也需要能点击跳转和删除
        // 注意：PostCard 内部应该处理自己的 onTap 事件来导航
        return PostCard(
          post: post,
          isDesktopLayout: true,
          onDeleted: () {
            _refreshData();
          },
        );
      },
    );
  }
}

// 保持这个简单的 RefreshController 类定义
class RefreshController {
  VoidCallback? _onRefreshCompletedCallback;

  // 注册回调
  void addListener(VoidCallback listener) {
    _onRefreshCompletedCallback = listener;
  }

  // 触发回调
  void refreshCompleted() {
    _onRefreshCompletedCallback?.call();
  }

  // 清理回调
  void dispose() {
    _onRefreshCompletedCallback = null;
  }
}