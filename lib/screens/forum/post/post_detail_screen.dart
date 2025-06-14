// lib/screens/forum/post/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/error/api_error_definitions.dart';
import 'package:suxingchahui/services/error/api_exception.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/layout/post_detail_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
// 导入 UI 组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool needHistory;
  final AuthProvider authProvider;
  final PostService postService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final SidebarProvider sidebarProvider;
  final PostListFilterProvider postListFilterProvider;
  final WindowStateProvider windowStateProvider;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoProvider,
    required this.inputStateService,
    required this.sidebarProvider,
    required this.postListFilterProvider,
    required this.windowStateProvider,
    this.needHistory = true,
  });
  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  String? _currentUserId;
  UserPostActions? _userActions;
  String? _error;
  bool _isLoading = true;
  bool _hasInteraction = false; // 标记页面是否有过交互
  bool _isTogglingLock = false; // 标记是否正在切换锁定状态
  bool _isTogglingPin = false; // 标记是否正在切换置顶状态
  bool _hasInitializedDependencies = false;

  late bool _isDesktop;

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
      final screenWidth = DeviceUtils.getScreenWidth(context);
      final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
      _isDesktop = isDesktop;
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
          await widget.postService.getPostDetailsWithActions(widget.postId);

      if (!mounted) return;

      if (details != null) {
        // 成功获取数据
        if (widget.needHistory && _post?.status != PostStatus.locked) {
          try {
            widget.postService.incrementPostView(widget.postId);
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
      if (!mounted) return;

      String errorCodeForState; // 用来存错误码给 build 方法判断

      if (e is ApiException) {
        errorCodeForState = e.apiErrorCode; // 直接获取后端标准错误码

        // 如果是"未找到"，触发特殊弹窗逻辑
        if (e.apiErrorCode == BackendApiErrorCodes.notFound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              CustomInfoDialog.show(
                context: context,
                title: '帖子找不到了',
                message: '抱歉，您要查看的帖子可能已被删除或转移。',
                // message可以直接用 e.toString()
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
        }
      } else {
        // 处理非 API 异常，给个通用码
        errorCodeForState = 'UNKNOWN_ERROR';
      }

      // 统一设置错误状态
      setState(() {
        _error = errorCodeForState; // _error 状态现在存储的是错误码
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
      AppSnackBar.showPermissionDenySnackBar();
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
            await widget.postService.deletePost(_post!);
          }

          if (!mounted) return;
          _hasInteraction = true;
          AppSnackBar.showSuccess('帖子已删除');
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
          AppSnackBar.showError(" 删除失败,${e.toString()}");
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
      AppSnackBar.showPermissionDenySnackBar();
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
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    setState(() {
      _isTogglingLock = true;
    });
    try {
      await widget.postService.togglePostLock(widget.postId);
      if (!mounted) return;
      AppSnackBar.showSuccess('帖子状态已切换');
      _hasInteraction = true;
      await _refreshPost(); // 刷新获取最新状态
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLock = false;
        });
      }
    }
  }

  // 处理切换帖子置顶状态
  Future<void> _handleTogglePin(BuildContext context) async {
    if (_post == null || _isTogglingPin) return;
    // 用户未登录
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    // 检查是否有置顶权限
    if (!widget.authProvider.isAdmin) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }

    // 更新加载状态
    setState(() {
      _isTogglingPin = true;
    });

    try {
      // 调用 Service 方法
      await widget.postService.togglePostPin(widget.postId);

      if (!mounted) return;
      // 更新本地状态
      setState(() {
        _post = _post!.copyWith(isPinned: !_post!.isPinned);
      });

      // 显示成功消息
      AppSnackBar.showSuccess('帖子置顶状态已切换');
      // 标记页面有改动
      _hasInteraction = true;
    } catch (e) {
      // 捕获 Service 层抛出的错误并显示
      AppSnackBar.showError("操作失败,${e.toString()}");
    } finally {
      if (mounted) {
        // 结束加载状态
        setState(() {
          _isTogglingPin = false;
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
    NavigationUtils.navigateToHome(
      widget.sidebarProvider,
      context,
      tabIndex: 2,
    );
  }

  // *** 构建界面 ***
  @override
  Widget build(BuildContext context) {
    // --- 加载状态 ---
    if (_isLoading && _post == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: FadeInItem(
          // 全屏加载组件
          child: LoadingWidget(
            isOverlay: true,
            message: "少女正在祈祷中...",
            overlayOpacity: 0.4,
            size: 36,
          ),
        ), //
      );
    }

    // --- 错误状态 ---
    if (_error != null && _post == null) {
      Widget errorContent;
      // 根据错误码显示不同的UI
      switch (_error) {
        case BackendApiErrorCodes.notFound:
          // notFound 的情况因为有弹窗，这里可以显示一个基础的错误界面
          // 或者直接返回一个空的 Scaffold，因为弹窗会覆盖整个屏幕
          return Scaffold(
            appBar: const CustomAppBar(title: '帖子详情'),
            body: Container(),
          ); // 空白页，等待用户关闭弹窗

        // 你可以为其他特定错误码添加 case，比如网络错误
        case BackendApiErrorCodes.networkNoConnection:
        case BackendApiErrorCodes.networkTimeout:
        case BackendApiErrorCodes.networkHostLookupFailed:
          errorContent = NetworkErrorWidget(onRetry: _loadPostDetails);
          break;

        case BackendApiErrorCodes.permissionDenied:
        case BackendApiErrorCodes.postLock:
          // 对于权限问题，可以显示一个特定的“无权限”组件
          errorContent = CustomErrorWidget(
            title: "无权访问",
            // 从注册表获取友好的提示信息
            errorMessage:
                ApiErrorRegistry.getDescriptor(_error!).defaultUserMessage,
            onRetry: _loadPostDetails,
            icon: Icons.lock_person_outlined,
          );
          break;

        default:
          // 其他所有未特殊处理的错误，都走通用错误组件
          errorContent = CustomErrorWidget(
              // 同样，从注册表里拿标准提示
              errorMessage:
                  ApiErrorRegistry.getDescriptor(_error!).defaultUserMessage,
              onRetry: _loadPostDetails);
      }

      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: FadeInItem(child: errorContent),
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

    return Scaffold(
      appBar: const CustomAppBar(
        title: '帖子详情',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPost,
        child: _buildPostDetailLayout(),
      ),
      floatingActionButton:
          _buildPostActionButtonsGroup(context, _post!), // FAB 依赖 _post 状态
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildPostDetailLayout() {
    final currentUserActions = _userActions ??
        UserPostActions.defaultActions(
            widget.postId, widget.authProvider.currentUserId ?? "");
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
        _isDesktop = isDesktop;
        return PostDetailLayout(
          isDesktop: isDesktop,
          authProvider: widget.authProvider,
          inputStateService: widget.inputStateService,
          post: _post!, // 传递 Post
          userActions: currentUserActions,
          postId: widget.postId,
          onPostUpdated: _handlePostUpdateFromInteraction, // 传递回调
          postService: widget.postService,
          infoProvider: widget.infoProvider,
          followService: widget.followService,
          onTagTap: (context, newTagString) =>
              _handleFilterTagSelect(context, newTagString),
        );
      },
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
        final bool canPin = currentUser.isAdmin;

        if (!canEdit && !canLock && !canPin) return const SizedBox.shrink();
        final String editHeroTag = 'postEditFab_${post.id}';
        final String deleteHeroTag = 'postDeleteFab_${post.id}';
        final String lockHeroTag = 'postLockFab_${post.id}';
        final String pinHeroTag = 'postPinFab_${post.id}';
        final double bottomPadding = _isDesktop ? 16.0 : 80.0; // 调整移动端底部间距
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding, right: 16.0),
          child: FloatingActionButtonGroup(
            toggleButtonHeroTag: "post_detail_heroTags",
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
              if (canPin)
                GenericFloatingActionButton(
                  heroTag: pinHeroTag, // 使用新增的 Hero Tag
                  mini: true,
                  tooltip: post.isPinned ? '取消置顶' : '置顶帖子', // 根据当前状态显示不同文本
                  icon: post.isPinned // 根据当前状态显示不同图标
                      ? Icons.push_pin // 置顶图标
                      : Icons.push_pin_outlined, // 未置顶图标
                  isLoading: _isTogglingPin, // 关联置顶操作的加载状态
                  // 任何操作进行中时都禁用
                  onPressed: (_isLoading ||
                          _isTogglingLock ||
                          _isTogglingPin) // <-- 增加 _isTogglingPin
                      ? null
                      : () => _handleTogglePin(context), // 调用新的处理方法
                  backgroundColor: post.isPinned // 根据状态显示不同颜色
                      ? Colors.blue[600] // 置顶时的颜色
                      : Colors.grey[600], // 未置顶时的颜色
                  foregroundColor: Colors.white,
                ),
            ],
          ),
        );
      },
    );
  }
}
