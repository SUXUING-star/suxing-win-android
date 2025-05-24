// lib/screens/forum/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/forum/post_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';

import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart'; // 引入 UserPostActions
import 'package:suxingchahui/services/main/forum/forum_service.dart'; // 引入 ForumService 和 PostDetailsWithActions
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
// 导入布局文件
import 'package:suxingchahui/widgets/components/screen/forum/post/layout/post_detail_desktop_layout.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/layout/post_detail_mobile_layout.dart';
// 导入 UI 组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool needHistory;
  final AuthProvider authProvider;
  final ForumService forumService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final SidebarProvider sidebarProvider;
  final PostListFilterProvider postListFilterProvider;
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.authProvider,
    required this.forumService,
    required this.followService,
    required this.infoProvider,
    required this.inputStateService,
    required this.sidebarProvider,
    required this.postListFilterProvider,
    this.needHistory = true,
  });
  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with SnackBarNotifierMixin {
  Post? _post;
  String? _currentUserId;
  UserPostActions? _userActions;
  String? _error;
  bool _isLoading = true;
  bool _hasInteraction = false; // 标记页面是否有过交互
  bool _isTogglingLock = false; // 标记是否正在切换锁定状态
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadPostDetails();
    }
  }

  @override
  void didUpdateWidget(covariant PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasInitializedDependencies &&
        _currentUserId != widget.authProvider.currentUserId) {
      setState(() {
        _isLoading = true;
        _post = null;
        _currentUserId = widget.authProvider.currentUserId;
      });
      _loadPostDetails();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 加载帖子详情和用户状态
  Future<void> _loadPostDetails() async {
    if (_isLoading && _post != null) {
      // 如果已经在加载中，并且已经有旧数据了（说明是刷新），可以先不强制 setState((){_isLoading=true})
      // 避免 UI 闪烁成加载状态，等 API 返回后再更新
      // 但仍然需要执行后续的 API 调用逻辑
    } else if (!mounted) {
      // 如果 initState 调用后，在 Future 执行前 widget 被移除了
      return;
    } else {
      // 只有在首次加载或需要显式重置时才设置 isLoading
      // 并且确保在安全的时候调用 setState
      // 使用 addPostFrameCallback 确保在 build 之后执行 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _error = null;
            // 首次加载时清空状态
            if (_post == null) {
              _userActions = null;
            }
          });
        }
      });
    }

    try {
      // 调用 Service 获取聚合数据
      final details =
          await widget.forumService.getPostDetailsWithActions(widget.postId);

      if (!mounted) return;

      if (details != null) {
        // 成功获取数据
        if (widget.needHistory && _post?.status != PostStatus.locked) {
          try {
            widget.forumService.incrementPostView(widget.postId);
          } catch (viewError) {
            //
          }
        }

        // 更新状态
        setState(() {
          _post = details.post;
          _userActions = details.userActions;
          _isLoading = false;
          _error = null;
        });
      } else {
        // Service 返回 null
        setState(() {
          _error = '无法加载帖子，请稍后重试';
          _isLoading = false;
          _post = null;
          _userActions = null;
        });
      }
    } catch (e) {
      // 捕获异常
      if (!mounted) return; // *** 异步操作后，必须检查 mounted 状态！ ***

      final errorString = e.toString();

      // 根据错误类型更新 UI
      String errorMessage;
      if (errorString.startsWith('access_denied:')) {
        errorMessage = errorString.substring('access_denied:'.length).trim();
        // 权限错误不需要弹窗
      } else if (errorString.contains('not_found')) {
        errorMessage = '帖子不存在或已被删除';
        // 帖子不存在，显示对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CustomInfoDialog.show(
              context: context,
              title: '帖子找不到了',
              message: '抱歉，您要查看的帖子可能已被删除或转移。\n(返回上一页或首页会自动刷新列表)',
              iconData: Icons.search_off,
              iconColor: Colors.orange,
              closeButtonText: '知道了',
              barrierDismissible: false,
              onClose: () {
                _handleNotFoundClose();
              },
            );
          }
        });
      } else {
        errorMessage =
            '加载帖子失败: ${e.toString().replaceFirst("Exception: ", "")}';
      }
      // 统一设置错误状态和结束加载
      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _post = null;
        _userActions = null;
      });
    }
  }

  // _handleNotFoundClose 修改后
  void _handleNotFoundClose() {
    if (mounted) {
      try {
        _hasInteraction = true;
        NavigationUtils.navigateToHome(widget.sidebarProvider, context);
      } catch (e) {
        // catch 仍然需要，万一 navigateToHome 内部炸了（虽然不太可能）
      }
    }
  }

  // 下拉刷新
  Future<void> _refreshPost() async {
    await _loadPostDetails();
  }

  // 这个回调现在由 PostInteractionButtons 触发，传递的是只更新了计数的 Post 对象
  // 父组件只负责更新自己的 _post 状态
  void _handlePostUpdateFromInteraction(
      Post updatedPostCore, UserPostActions updatedUserActions) {
    if (mounted && _post?.id == updatedPostCore.id) {
      setState(() {
        _post = updatedPostCore;
        _userActions = updatedUserActions;
      });
      _hasInteraction = true; // 标记页面发生过交互
    } else {}
  }

  // 处理删除帖子
  Future<void> _handleDeletePost(BuildContext context) async {
    if (_post == null) return;
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(_post!)) {
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    CustomConfirmDialog.show(
      context: context,
      title: '删除帖子',
      message: '确定要删除这个帖子吗？删除后无法恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_outline,
      iconColor: Colors.red,
      onConfirm: () async {
        if (!mounted) return;
        setState(() {
          _isLoading = true;
        });
        try {
          if (_post != null) {
            await widget.forumService.deletePost(_post!);
          }
          if (!mounted) return;
          _hasInteraction = true;
          showSnackbar(message: '帖子已删除', type: SnackbarType.success);
          if (Navigator.canPop(this.context)) {
            // 使用 this.context
            Navigator.pop(this.context, _hasInteraction); // 使用 this.context
          } else {
            // NavigationUtils.navigateToHome 内部也应该使用一个安全的 context
            // 如果 NavigationUtils.navigateToHome 接受 context 参数，也传递 this.context
            NavigationUtils.navigateToHome(
                widget.sidebarProvider, this.context); // 使用 this.context
          }
        } catch (e) {
          if (!mounted) return;
          showSnackbar(
              message: '删除失败：${e.toString().replaceFirst("Exception: ", "")}',
              type: SnackbarType.error);
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // 处理编辑帖子
  Future<void> _handleEditPost(BuildContext context) async {
    if (_post == null) return;
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(_post!)) {
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: widget.postId,
    );
    if (result == true) {
      // 编辑成功
      _hasInteraction = true;
      await _refreshPost(); // 刷新页面
    }
  }

  // 处理切换帖子锁定状态
  Future<void> _handleToggleLock(BuildContext context) async {
    if (_post == null || _isTogglingLock) return;
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanLockPost()) {
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    setState(() {
      _isTogglingLock = true;
    });
    try {
      await widget.forumService.togglePostLock(widget.postId);
      if (!mounted) return;
      showSnackbar(message: '帖子状态已切换', type: SnackbarType.success);
      _hasInteraction = true;
      await _refreshPost(); // 刷新获取最新状态
    } catch (e) {
      if (!mounted) return;
      showSnackbar(
          message: '操作失败: ${e.toString().replaceFirst("Exception: ", "")}',
          type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLock = false;
        });
      }
    }
  }

  bool _checkCanLockPost() {
    return widget.authProvider.isAdmin;
  }

  bool _checkCanEditOrDeletePost(Post post) {
    return widget.authProvider.isAdmin
        ? true
        : widget.authProvider.currentUserId == post.authorId;
  }

  void _handleFilterTagSelect(BuildContext context, String newTagString) {
    widget.postListFilterProvider.setTag(newTagString);
    NavigationUtils.navigateToHome(widget.sidebarProvider, context,
        tabIndex: 2);
  }

  // *** 构建界面 ***
  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    final bool isDesktop = DeviceUtils.isDesktop;

    // --- 加载状态 ---
    if (_isLoading && _post == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载帖子...')),
      );
    }

    // --- 错误状态 ---
    if (_error != null && _post == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: FadeInItem(
            child: CustomErrorWidget(
                errorMessage: _error!, onRetry: _loadPostDetails)),
      );
    }

    // --- 帖子数据为空 ---
    if (_post == null) {
      // 理论上这种情况已经被前面的逻辑覆盖，但作为最后防线
      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: NotFoundErrorWidget(
          message: '无法显示帖子内容 (错误)',
          onBack: () => NavigationUtils.pop(context, _hasInteraction),
        ),
      );
    }

    // --- 正常显示 ---
    // **此时 _post 保证非 null, _userActions 也应该由 _loadPostDetails 保证非 null (即使是默认值)**
    final currentUserActions = _userActions ??
        UserPostActions.defaultActions(
            widget.postId, widget.authProvider.currentUserId ?? "guest");

    return Scaffold(
      appBar: const CustomAppBar(
        title: '帖子详情',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPost,
        child: isDesktop
            ? PostDetailDesktopLayout(
                authProvider: widget.authProvider,
                inputStateService: widget.inputStateService,
                post: _post!, // 传递 Post
                userActions: currentUserActions,
                postId: widget.postId,
                onPostUpdated: _handlePostUpdateFromInteraction, // 传递回调
                forumService: widget.forumService,
                infoProvider: widget.infoProvider,
                followService: widget.followService,
                onTagTap: (context, newTagString) =>
                    _handleFilterTagSelect(context, newTagString),
              )
            : PostDetailMobileLayout(
                authProvider: widget.authProvider,
                inputStateService: widget.inputStateService,
                post: _post!, // 传递 Post
                userActions: currentUserActions,
                postId: widget.postId,
                followService: widget.followService,
                forumService: widget.forumService,
                infoProvider: widget.infoProvider,
                onTagTap: (context, newTagString) =>
                    _handleFilterTagSelect(context, newTagString),
                onPostUpdated: _handlePostUpdateFromInteraction, // 传递回调
              ),
      ),
      floatingActionButton:
          _buildPostActionButtonsGroup(context, _post!), // FAB 依赖 _post 状态
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // 构建浮动操作按钮组 (完整)
  Widget _buildPostActionButtonsGroup(BuildContext context, Post post) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) return const SizedBox.shrink();

        final bool canEdit =
            currentUser.isAdmin ? true : currentUser.id == post.authorId;
        final bool canLock = currentUser.isAdmin;
        if (!canEdit && !canLock) return const SizedBox.shrink();
        final String editHeroTag = 'postEditFab_${post.id}';
        final String deleteHeroTag = 'postDeleteFab_${post.id}';
        final String lockHeroTag = 'postLockFab_${post.id}';
        final double bottomPadding =
            DeviceUtils.isDesktop ? 16.0 : 80.0; // 调整移动端底部间距
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding, right: 16.0),
          child: FloatingActionButtonGroup(
            spacing: 12.0,
            alignment: MainAxisAlignment.start,
            children: [
              if (canEdit)
                GenericFloatingActionButton(
                  heroTag: editHeroTag,
                  mini: true,
                  tooltip: '编辑帖子',
                  icon: Icons.edit_outlined,
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleEditPost(context),
                  // 加载或锁定时禁用
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              if (canEdit)
                GenericFloatingActionButton(
                  heroTag: deleteHeroTag,
                  mini: true,
                  tooltip: '删除帖子',
                  icon: Icons.delete_forever_outlined,
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleDeletePost(context),
                  // 加载或锁定时禁用
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              if (canLock)
                GenericFloatingActionButton(
                  heroTag: lockHeroTag,
                  mini: true,
                  tooltip: post.status == PostStatus.locked ? '解锁帖子' : '锁定帖子',
                  icon: post.status == PostStatus.locked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  isLoading: _isTogglingLock,
                  // 使用切换锁定状态
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleToggleLock(context),
                  // 加载或锁定时禁用
                  backgroundColor: post.status == PostStatus.locked
                      ? Colors.grey[600]
                      : Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
            ],
          ),
        );
      },
    );
  }
} // End of _PostDetailScreenState
