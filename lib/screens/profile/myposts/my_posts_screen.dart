// lib/screens/profile/my_posts_screen.dart
import 'dart:async'; // 需要 Future 和 async
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart'; // 引入 ForumService
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/forum/card/post_grid_view.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/ui/buttons/functional_text_button.dart'; // 确保导入 FunctionalTextButton

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SnackBarNotifierMixin {
  // --- 依赖的服务 ---

  // --- 状态变量 ---
  List<Post> _posts = [];
  bool _isLoading = false; // 初始设为 true
  String? _error;
  String? _userId;
  bool _isMounted = false; // 跟踪 widget 是否挂载

  final ScrollController _scrollController = ScrollController();

  late final ForumService _forumService;

  @override
  void initState() {
    super.initState();

    _isMounted = true;
    _fetchPosts(); // 初始化时加载数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _forumService = context.read<ForumService>();
  }

  @override
  void dispose() {
    _isMounted = false; // 标记为已卸载
    _scrollController.dispose();
    super.dispose();
  }

  // --- 数据加载/刷新逻辑 ---
  Future<void> _fetchPosts() async {
    if (!_isMounted) {
      return; // 如果 Widget 已经被移除了，就不继续了
    }

    // 增加这个检查来防止并发请求
    if (_isLoading) {
      return; // 如果当前已经在加载中了，就不要开始新的加载
    }

    // 在异步操作开始前，设置状态为加载中
    setState(() {
      _isLoading = true;
      _error = null; // 清除之前的错误信息
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUserId;

      if (currentUserId == null || currentUserId.isEmpty) {
        if (_isMounted) {
          setState(() {
            _isLoading = false; // 加载结束（虽然是未登录状态）
            _posts = [];
            _userId = null;
            _error = null; // 未登录不是错误
          });
        }
        return; // 未登录，直接返回
      }

      // 调用修改后的 Future 方法

      final fetchedPosts = await _forumService.getUserPosts(currentUserId);

      if (_isMounted) {
        setState(() {
          _isLoading = false; // 加载完成
          _posts = fetchedPosts;
          _userId = currentUserId; // 保存用户ID
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false; // 加载失败，也要结束加载状态
          _error = '加载我的帖子失败: $e';
          // 考虑是否要清空 _posts 列表，取决于你的需求
          // _posts = [];
        });
      }
    }
  }

  // --- 下拉刷新 ---
  Future<void> _refreshPosts() async {
    // 重新调用加载逻辑
    await _fetchPosts();
  }

  // --- 处理删除帖子 ---
  Future<void> _handleDeletePost(Post post) async {
    final postId = post.id;
    // 乐观更新 UI
    final List<Post> originalPosts = List.from(_posts);
    setState(() {
      _posts.removeWhere((post) => post.id == postId);
      _error = null; // 清除可能存在的旧错误
    });

    try {
      // 显示确认对话框
      await CustomConfirmDialog.show(
          context: context,
          title: '确认删除',
          message: '确定要删除这篇帖子吗？此操作无法撤销。',
          confirmButtonText: '删除',
          confirmButtonColor: Colors.red,
          onConfirm: () async {
            if (!_isMounted) return;
            try {
              // 调用 Service 执行实际删除
              final forumService = context.read<ForumService>();
              await forumService.deletePost(post);
              showSnackbar(message: '帖子已删除', type: SnackbarType.success);
            } catch (e) {
              if (_isMounted) {
                // 删除失败，恢复之前的帖子列表，并显示错误
                setState(() {
                  _posts = originalPosts; // 恢复列表
                  _error = '删除帖子失败: $e';
                });
                showSnackbar(message: '删除帖子失败: $e', type: SnackbarType.error);
              }
            }
          },
          // 添加 onCancel 回调来恢复 UI (如果用户取消)
          onCancel: () {
            if (_isMounted) {
              setState(() {
                _posts = originalPosts; // 恢复列表
              });
            }
          });
    } catch (e) {
      // 处理 CustomConfirmDialog.show 本身可能抛出的异常（虽然不太可能）
      if (_isMounted) {
        setState(() {
          _posts = originalPosts; // 恢复列表
          _error = '操作失败';
        });
      }
    }
  }

  // --- 处理编辑帖子 ---
  void _handleEditPost(Post post) async {
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id,
    );
    // 如果编辑成功返回，触发刷新
    if (result == true && _isMounted) {
      _fetchPosts(); // 刷新列表
    }
  }

  // --- 处理切换锁定状态 ---
  Future<void> _handleToggleLockAction(String postId) async {
    if (!_isMounted) return;

    // 找到帖子并乐观更新 UI
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      return; // 或者触发刷新
    }

    final Post postToUpdate = _posts[postIndex];
    final PostStatus originalStatus = postToUpdate.status;
    final PostStatus newStatus = originalStatus == PostStatus.locked
        ? PostStatus.active
        : PostStatus.locked;
    final Post updatedPostOptimistic = postToUpdate.copyWith(status: newStatus);

    setState(() {
      _posts[postIndex] = updatedPostOptimistic;
      _error = null; // 清除错误
    });

    try {
      // 调用 Service 执行实际操作
      final forumService = context.read<ForumService>();
      await forumService.togglePostLock(postId);
      showSnackbar(message: '状态切换成功', type: SnackbarType.success);
    } catch (e) {
      if (_isMounted) {
        // 操作失败，回滚状态并显示错误
        setState(() {
          // 找到可能因为其他操作更新过的 post
          final currentPostIndex = _posts.indexWhere((p) => p.id == postId);
          if (currentPostIndex != -1) {
            _posts[currentPostIndex] = postToUpdate; // 恢复原始状态
          } else {
            // 如果帖子已经不在列表里了（比如并发删除了），就不用恢复了
          }
          _error = '切换帖子状态失败: $e';
        });
        showSnackbar(message: '切换帖子状态失败: $e', type: SnackbarType.error);
      }
    }
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButtonGroup(children: [
      GenericFloatingActionButton(
        icon: Icons.refresh,
        onPressed: _isLoading ? null : _refreshPosts, // 加载中禁用刷新
        tooltip: '刷新',
        heroTag: "刷新我的帖子",
      ),
      GenericFloatingActionButton(
        onPressed: () async {
          final result =
              await NavigationUtils.pushNamed(context, AppRoutes.createPost);
          if (result == true && _isMounted) {
            _fetchPosts(); // 发帖成功后刷新
          }
        },
        icon: Icons.add,
        tooltip: '发布新帖',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: '我的帖子',
        ),
        body: RefreshIndicator(
          onRefresh: _isLoading ? () async {} : _refreshPosts, // 加载中禁用下拉刷新
          child: _buildContent(context), // 调用构建内容的方法
        ),
        floatingActionButton: _buildFab(context));
  }

  Widget _buildContent(BuildContext context) {
    buildSnackBar(context);
    final bool isDesktop = DeviceUtils.isDesktop;

    // --- 优先处理加载状态 (仅在首次加载且无数据时显示全屏 Loading) ---
    if (_isLoading && _posts.isEmpty && _error == null) {
      return ListView(
        // 使用 ListView 包装
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          LoadingWidget.inline(),
        ],
      );
    }

    // --- 处理未登录状态 ---
    if (_userId == null && !_isLoading) {
      return ListView(// 使用 ListView 包装
          children: const [LoginPromptWidget()]);
    }

    // --- 处理错误状态 ---
    if (_error != null && !_isLoading) {
      return ListView(
        // 使用 ListView 包装，允许下拉刷新错误页面
        physics: const AlwaysScrollableScrollPhysics(), // 必须可以滚动才能触发刷新
        children: [
          Container(
            // 让内容占满屏幕以便刷新
            height: MediaQuery.of(context).size.height -
                (Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight) -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            alignment: Alignment.center,
            child: Text('加载失败: $_error'), // 显示错误信息
          )
        ],
      );
    }

    // --- 处理空状态 (加载完成，无错误，但帖子列表为空) ---
    if (_posts.isEmpty && !_isLoading && _error == null) {
      return LayoutBuilder(// 使用 LayoutBuilder 确保内容足够高以触发刷新
          builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 即使内容不足也要能滚动
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateWidget(
              message: '你还没有发布过帖子哦',
              iconData: Icons.dynamic_feed_outlined,
              action: FunctionalTextButton(
                onPressed: () async {
                  final result = await NavigationUtils.pushNamed(
                      context, AppRoutes.createPost);
                  if (result == true && mounted) {
                    _fetchPosts();
                  }
                },
                label: '去发第一篇帖子',
              ),
            ),
          ),
        );
      });
    }

    // --- 显示帖子列表 ---
    return PostGridView(
      posts: _posts,
      scrollController: _scrollController,
      isLoading: false, // 不再需要内部 loading
      hasMoreData: false, // 不分页
      isDesktopLayout: isDesktop,
      onDeleteAction: _handleDeletePost,
      onEditAction: _handleEditPost,
      onToggleLockAction: _handleToggleLockAction,
    );
  }
}
