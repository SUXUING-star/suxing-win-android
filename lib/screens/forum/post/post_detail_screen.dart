// lib/screens/forum/post/post_detail_screen.dart

/// 该文件定义了 PostDetailScreen 界面，用于显示帖子的详细信息。
/// 该界面管理帖子的加载、刷新、交互操作和权限控制。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart'; // 帖子列表筛选 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 侧边栏 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 窗口状态 Provider
import 'package:suxingchahui/services/error/api_error_definitions.dart'; // API 错误定义
import 'package:suxingchahui/services/error/api_exception.dart'; // API 异常
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具
import 'package:suxingchahui/widgets/components/screen/forum/post/layout/post_detail_layout.dart'; // 帖子详情布局
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart'; // 浮动操作按钮组
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart'; // 通用浮动操作按钮
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // 懒加载布局构建器
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart'; // 信息对话框
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart'; // 应用 SnackBar

import 'package:suxingchahui/models/post/post.dart'; // 帖子模型
import 'package:suxingchahui/models/post/user_post_actions.dart'; // 用户帖子交互状态模型
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 帖子服务
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 自定义应用栏
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框

/// `PostDetailScreen` 类：帖子详情界面。
///
/// 该界面显示特定帖子的详细内容，并提供点赞、收藏、编辑、删除、锁定和置顶功能。
class PostDetailScreen extends StatefulWidget {
  final String postId; // 帖子 ID
  final bool needHistory; // 是否需要记录浏览历史
  final AuthProvider authProvider; // 认证 Provider 实例
  final PostService postService; // 帖子服务实例
  final UserFollowService followService; // 用户关注服务实例
  final UserInfoService infoService; // 用户信息服务实例
  final InputStateService inputStateService; // 输入状态服务实例
  final SidebarProvider sidebarProvider; // 侧边栏 Provider 实例
  final PostListFilterProvider postListFilterProvider; // 帖子列表筛选 Provider 实例
  final WindowStateProvider windowStateProvider; // 窗口状态 Provider 实例

  /// 构造函数。
  ///
  /// [postId]：要显示的帖子 ID。
  /// [needHistory]：是否记录浏览历史，默认为 true。
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoService,
    required this.inputStateService,
    required this.sidebarProvider,
    required this.postListFilterProvider,
    required this.windowStateProvider,
    this.needHistory = true,
  });
  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

/// `_PostDetailScreenState` 类：`PostDetailScreen` 的状态管理。
///
/// 该类管理帖子数据、用户交互状态、加载和错误状态。
class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post; // 当前帖子数据
  String? _currentUserId; // 当前登录用户 ID
  UserPostActions? _userActions; // 当前用户对帖子的交互状态
  String? _error; // 错误消息
  bool _isLoading = true; // 页面加载状态
  bool _hasInteraction = false; // 标记页面是否有过交互
  bool _isTogglingLock = false; // 帖子锁定状态切换中标记
  bool _isTogglingPin = false; // 帖子置顶状态切换中标记
  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记

  bool _isToggleLiking = false; // 点赞操作加载状态
  bool _isToggleAgreeing = false; // 赞同操作加载状态
  bool _isToggleFavoriting = false; // 收藏操作加载状态

  late bool _isDesktop; // 桌面布局标记

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户 ID
      _hasInitializedDependencies = true; // 标记依赖已初始化
    }
    if (_hasInitializedDependencies) {
      _loadPostDetails(); // 加载帖子详情
      final screenWidth = DeviceUtils.getScreenWidth(context); // 获取屏幕宽度
      final isDesktop =
          DeviceUtils.isDesktopInThisWidth(screenWidth); // 判断是否为桌面布局
      _isDesktop = isDesktop; // 设置桌面布局标记
    }
  }

  @override
  void didUpdateWidget(covariant PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasInitializedDependencies &&
        _currentUserId != widget.authProvider.currentUserId) {
      // 用户 ID 发生变化时
      setState(() {
        _isLoading = true; // 设置加载状态
        _post = null; // 清空帖子数据
        _currentUserId = widget.authProvider.currentUserId; // 更新当前用户 ID
      });
      _loadPostDetails(); // 重新加载帖子详情
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 加载帖子详情和用户交互状态。
  ///
  /// 该方法在组件首次构建或需要刷新时调用。
  Future<void> _loadPostDetails() async {
    if (_isLoading && _post != null) {
      // 正在加载且已有旧数据时，不强制重置UI，直接进行API调用。
    } else if (!mounted) {
      return; // 组件未挂载时直接返回。
    } else {
      // 首次加载或需要显式重置时，设置加载状态。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = true; // 设置加载中
            _error = null; // 清空错误信息
            if (_post == null) {
              _userActions = null; // 首次加载时清空用户操作状态
            }
          });
        }
      });
    }

    try {
      final details = await widget.postService
          .getPostDetailsWithActions(widget.postId); // 获取帖子详情和用户操作

      if (!mounted) return; // 再次检查组件是否挂载

      if (details != null) {
        // 成功获取数据
        if (widget.needHistory && _post?.status != PostStatus.locked) {
          // 记录浏览历史
          try {
            widget.postService.incrementPostView(widget.postId); // 增加帖子浏览量
          } catch (viewError) {
            // 捕获增加浏览量错误
          }
        }

        setState(() {
          _post = details.post; // 更新帖子数据
          _userActions = details.userActions; // 更新用户操作状态
          _isLoading = false; // 取消加载状态
          _error = null; // 清空错误信息
        });
      } else {
        // 服务返回 null
        setState(() {
          _error = '无法加载帖子，请稍后重试'; // 设置错误消息
          _isLoading = false; // 取消加载状态
          _post = null; // 清空帖子数据
          _userActions = null; // 清空用户操作状态
        });
      }
    } catch (e) {
      if (!mounted) return; // 检查组件是否挂载

      String errorCodeForState; // 错误码变量

      if (e is ApiException) {
        errorCodeForState = e.apiErrorCode; // 获取后端标准错误码

        if (e.apiErrorCode == BackendApiErrorCodes.notFound) {
          // 帖子未找到错误
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              CustomInfoDialog.show(
                context: context,
                title: '帖子找不到了',
                message: '抱歉，您要查看的帖子可能已被删除或转移。',
                iconData: Icons.search_off,
                iconColor: Colors.orange,
                closeButtonText: '知道了',
                barrierDismissible: false,
                onClose: () {
                  _handleNotFoundClose(); // 处理帖子未找到关闭逻辑
                },
              );
            }
          });
        }
      } else {
        errorCodeForState = 'UNKNOWN_ERROR'; // 非 API 异常的通用错误码
      }

      setState(() {
        _error = errorCodeForState; // 存储错误码
        _isLoading = false; // 取消加载状态
        _post = null; // 清空帖子数据
        _userActions = null; // 清空用户操作状态
      });
    }
  }

  /// 处理帖子未找到弹窗关闭逻辑。
  ///
  /// 导航回主页。
  void _handleNotFoundClose() {
    if (mounted) {
      try {
        _hasInteraction = true; // 标记页面有过交互
        NavigationUtils.navigateToHome(
            widget.sidebarProvider, context); // 导航回主页
      } catch (e) {
        // 捕获导航错误
      }
    }
  }

  /// 下拉刷新帖子数据。
  Future<void> _refreshPost() async {
    await _loadPostDetails(); // 重新加载帖子详情
  }

  /// 统一处理用户交互操作。
  ///
  /// [apiCall]：执行 API 调用的函数。
  /// [setLoading]：设置加载状态的函数。
  Future<void> _handleInteraction({
    required Future<(UserPostActions?, Post?)> Function() apiCall,
    required Function(bool isLoading) setLoading,
  }) async {
    if (widget.authProvider.currentUserId == null) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return;
    }
    if (_isToggleLiking || _isToggleAgreeing || _isToggleFavoriting)
      return; // 阻止重复操作

    setState(() => setLoading(true)); // 设置加载状态

    try {
      final (newActions, newPost) = await apiCall(); // 调用 API

      if (mounted && newPost != null && newActions != null) {
        // 成功后更新状态
        setState(() {
          _post = newPost; // 更新帖子数据
          _userActions = newActions; // 更新用户操作状态
          _hasInteraction = true; // 标记页面有过交互
        });
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError("操作失败: ${e.toString()}"); // 显示错误提示
    } finally {
      if (mounted) setState(() => setLoading(false)); // 结束加载状态
    }
  }

  /// 切换帖子点赞状态。
  Future<void> _toggleLike() async {
    if (_post == null || _userActions == null) return; // 检查数据是否存在
    await _handleInteraction(
      apiCall: () => widget.postService.togglePostLike(
        // 调用点赞 API
        post: _post!,
        oldActions: _userActions!,
      ),
      setLoading: (v) => _isToggleLiking = v, // 设置点赞加载状态
    );
  }

  /// 切换帖子赞同状态。
  Future<void> _toggleAgree() async {
    if (_post == null || _userActions == null) return; // 检查数据是否存在
    await _handleInteraction(
      apiCall: () => widget.postService.togglePostAgree(
        // 调用赞同 API
        post: _post!,
        oldActions: _userActions!,
      ),
      setLoading: (v) => _isToggleAgreeing = v, // 设置赞同加载状态
    );
  }

  /// 切换帖子收藏状态。
  Future<void> _toggleFavorite() async {
    if (_post == null || _userActions == null) return; // 检查数据是否存在
    await _handleInteraction(
      apiCall: () => widget.postService.togglePostFavorite(
        // 调用收藏 API
        post: _post!,
        oldActions: _userActions!,
      ),
      setLoading: (v) => _isToggleFavoriting = v, // 设置收藏加载状态
    );
  }

  /// 处理删除帖子操作。
  ///
  /// [context]：Build 上下文。
  /// 检查登录和权限，显示确认对话框，确认后执行删除并导航。
  Future<void> _handleDeletePost(BuildContext context) async {
    if (_post == null) return; // 帖子数据为空时返回
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return;
    }
    if (!_checkCanEditOrDeletePost(_post!)) {
      // 检查权限
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限拒绝提示
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
        if (!mounted) return; // 检查组件是否挂载
        setState(() {
          _isLoading = true; // 设置加载状态
        });
        try {
          if (_post != null) {
            await widget.postService.deletePost(_post!); // 调用服务删除帖子
          }

          if (!mounted) return; // 再次检查组件是否挂载
          _hasInteraction = true; // 标记页面有过交互
          AppSnackBar.showSuccess('帖子已删除'); // 显示成功提示
          if (Navigator.canPop(this.context)) {
            Navigator.pop(this.context, _hasInteraction); // 返回上一页
          } else {
            NavigationUtils.navigateToHome(
                widget.sidebarProvider, this.context); // 导航回主页
          }
        } catch (e) {
          AppSnackBar.showError(" 删除失败,${e.toString()}"); // 显示错误提示
          setState(() {
            _isLoading = false; // 取消加载状态
          });
        }
      },
    );
  }

  /// 处理编辑帖子操作。
  ///
  /// [context]：Build 上下文。
  /// 检查登录和权限，导航到编辑界面，编辑成功后刷新页面。
  Future<void> _handleEditPost(BuildContext context) async {
    if (_post == null) return; // 帖子数据为空时返回
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return;
    }
    if (!_checkCanEditOrDeletePost(_post!)) {
      // 检查权限
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限拒绝提示
      return;
    }
    final result = await NavigationUtils.pushNamed(
      // 导航到编辑帖子界面
      context,
      AppRoutes.editPost,
      arguments: widget.postId,
    );
    if (result == true) {
      // 编辑成功
      _hasInteraction = true; // 标记页面有过交互
      await _refreshPost(); // 刷新页面
    }
  }

  /// 处理切换帖子锁定状态。
  ///
  /// [context]：Build 上下文。
  /// 检查登录和权限，执行锁定/解锁操作并刷新页面。
  Future<void> _handleToggleLock(BuildContext context) async {
    if (_post == null || _isTogglingLock) return; // 帖子数据为空或正在切换锁定状态时返回
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return;
    }
    if (!_checkCanLockPost()) {
      // 检查权限
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限拒绝提示
      return;
    }
    setState(() {
      _isTogglingLock = true; // 设置为正在切换锁定状态
    });
    try {
      await widget.postService.togglePostLock(_post!); // 调用服务切换锁定状态
      if (!mounted) return; // 检查组件是否挂载
      AppSnackBar.showSuccess('帖子状态已切换'); // 显示成功提示
      _hasInteraction = true; // 标记页面有过交互
      await _refreshPost(); // 刷新获取最新状态
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLock = false; // 取消正在切换锁定状态
        });
      }
    }
  }

  /// 处理切换帖子置顶状态。
  ///
  /// [context]：Build 上下文。
  /// 检查登录和权限，执行置顶/取消置顶操作并更新状态。
  Future<void> _handleTogglePin(BuildContext context) async {
    if (_post == null || _isTogglingPin) return; // 帖子数据为空或正在切换置顶状态时返回
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return;
    }
    if (!widget.authProvider.isAdmin) {
      // 检查是否为管理员
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限拒绝提示
      return;
    }

    setState(() {
      _isTogglingPin = true; // 设置为正在切换置顶状态
    });

    try {
      await widget.postService.togglePostPin(_post!); // 调用服务切换置顶状态

      if (!mounted) return; // 检查组件是否挂载
      setState(() {
        _post = _post!.copyWith(isPinned: !_post!.isPinned); // 更新帖子置顶状态
      });

      AppSnackBar.showSuccess('帖子置顶状态已切换'); // 显示成功提示
      _hasInteraction = true; // 标记页面有过交互
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingPin = false; // 取消正在切换置顶状态
        });
      }
    }
  }

  /// 检查用户是否拥有锁定帖子的权限。
  ///
  /// 返回 true 表示拥有权限，false 表示没有权限。
  bool _checkCanLockPost() {
    return widget.authProvider.isAdmin; // 只有管理员拥有权限
  }

  /// 检查用户是否拥有编辑或删除帖子的权限。
  ///
  /// [post]：要检查的帖子。
  /// 返回 true 表示拥有权限，false 表示没有权限。
  bool _checkCanEditOrDeletePost(Post post) {
    return widget.authProvider.isAdmin // 管理员拥有权限
        ? true
        : widget.authProvider.currentUserId == post.authorId; // 或者用户是帖子作者
  }

  /// 处理筛选标签选择。
  ///
  /// [context]：Build 上下文。
  /// [newTagString]：新的标签字符串。
  /// 设置标签并导航到主页的指定 Tab。
  void _handleFilterTagSelect(BuildContext context, String newTagString) {
    widget.postListFilterProvider.setTag(newTagString); // 设置帖子列表筛选标签
    NavigationUtils.navigateToHome(
      widget.sidebarProvider,
      context,
      tabIndex: 2, // 导航到主页的第三个 Tab
    );
  }

  // === 构建界面 ===
  @override
  Widget build(BuildContext context) {
    // --- 加载状态 ---
    if (_isLoading && _post == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: '帖子详情'), // 应用栏
        body: FadeInItem(
          child: LoadingWidget(
            isOverlay: true,
            message: "少女正在祈祷中...",
            overlayOpacity: 0.4,
            size: 36,
          ),
        ),
      );
    }

    // --- 错误状态 ---
    if (_error != null && _post == null) {
      Widget errorContent; // 错误内容组件
      switch (_error) {
        case BackendApiErrorCodes.notFound: // 帖子未找到错误码
          return Scaffold(
            appBar: const CustomAppBar(title: '帖子详情'),
            body: Container(), // 空白页面，等待弹窗关闭
          );

        case BackendApiErrorCodes.networkNoConnection: // 无网络连接错误码
        case BackendApiErrorCodes.networkTimeout: // 网络超时错误码
        case BackendApiErrorCodes.networkHostLookupFailed: // 主机查找失败错误码
          errorContent =
              NetworkErrorWidget(onRetry: _loadPostDetails); // 显示网络错误组件
          break;

        case BackendApiErrorCodes.permissionDenied: // 权限拒绝错误码
        case BackendApiErrorCodes.postLock: // 帖子锁定错误码
          errorContent = CustomErrorWidget(
            title: "无权访问",
            errorMessage: ApiErrorRegistry.getDescriptor(_error!)
                .defaultUserMessage, // 从注册表获取用户消息
            onRetry: _loadPostDetails, // 重试回调
            icon: Icons.lock_person_outlined, // 图标
          );
          break;

        default:
          errorContent = CustomErrorWidget(
              errorMessage: ApiErrorRegistry.getDescriptor(_error!)
                  .defaultUserMessage, // 从注册表获取用户消息
              onRetry: _loadPostDetails); // 重试回调
      }

      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: FadeInItem(child: errorContent), // 显示错误内容
      );
    }

    // --- 帖子数据为空 ---
    if (_post == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '帖子详情'),
        body: NotFoundErrorWidget(
          message: '无法显示帖子内容 (错误)',
          onBack: () => NavigationUtils.pop(context, _hasInteraction), // 返回回调
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: '帖子详情',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPost, // 下拉刷新回调
        child: _buildPostDetailLayout(), // 构建帖子详情布局
      ),
      floatingActionButton:
          _buildPostActionButtonsGroup(context, _post!), // 构建浮动操作按钮组
      floatingActionButtonLocation:
          FloatingActionButtonLocation.startFloat, // 浮动按钮位置
    );
  }

  /// 构建帖子详情布局。
  Widget _buildPostDetailLayout() {
    final currentUserActions = _userActions ??
        UserPostActions.defaultActions(
            widget.postId, widget.authProvider.currentUserId ?? ""); // 获取当前用户操作
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth; // 获取屏幕宽度
        final isDesktop =
            DeviceUtils.isDesktopInThisWidth(screenWidth); // 判断是否为桌面布局
        _isDesktop = isDesktop; // 设置桌面布局标记
        return PostDetailLayout(
          isDesktop: isDesktop,
          authProvider: widget.authProvider,
          inputStateService: widget.inputStateService,
          post: _post!, // 帖子数据
          userActions: currentUserActions, // 用户操作
          postId: widget.postId, // 帖子 ID
          postService: widget.postService, // 帖子服务
          infoService: widget.infoService, // 用户信息服务
          followService: widget.followService, // 关注服务
          onTagTap: (context, newTagString) =>
              _handleFilterTagSelect(context, newTagString), // 标签点击回调
          isLiking: _isToggleLiking, // 点赞加载状态
          isAgreeing: _isToggleAgreeing, // 赞同加载状态
          isFavoriting: _isToggleFavoriting, // 收藏加载状态
          onToggleLike: _toggleLike, // 点赞回调
          onToggleAgree: _toggleAgree, // 赞同回调
          onToggleFavorite: _toggleFavorite, // 收藏回调
        );
      },
    );
  }

  /// 构建浮动操作按钮组。
  ///
  /// [context]：Build 上下文。
  /// [post]：当前帖子。
  Widget _buildPostActionButtonsGroup(BuildContext context, Post post) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream, // 监听当前用户 Stream
      initialData: widget.authProvider.currentUser, // 初始当前用户数据
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data; // 获取当前用户数据
        if (currentUser == null) return const SizedBox.shrink(); // 未登录时不显示按钮组

        final bool canEdit = currentUser.isAdmin
            ? true
            : currentUser.id == post.authorId; // 检查编辑权限
        final bool canLock = currentUser.isAdmin; // 检查锁定权限
        final bool canPin = currentUser.isAdmin; // 检查置顶权限

        if (!canEdit && !canLock && !canPin) {
          return const SizedBox.shrink(); // 无任何权限时不显示按钮组
        }
        final String editHeroTag = 'postEditFab_${post.id}'; // 编辑按钮 Hero Tag
        final String deleteHeroTag =
            'postDeleteFab_${post.id}'; // 删除按钮 Hero Tag
        final String lockHeroTag = 'postLockFab_${post.id}'; // 锁定按钮 Hero Tag
        final String pinHeroTag = 'postPinFab_${post.id}'; // 置顶按钮 Hero Tag
        final double bottomPadding = _isDesktop ? 16.0 : 80.0; // 底部内边距

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding, right: 16.0), // 内边距
          child: FloatingActionButtonGroup(
            toggleButtonHeroTag: "post_detail_heroTags", // 切换按钮 Hero Tag
            spacing: 12.0, // 按钮间距
            alignment: MainAxisAlignment.start, // 对齐方式
            children: [
              if (canEdit) // 编辑按钮
                GenericFloatingActionButton(
                  heroTag: editHeroTag,
                  mini: true,
                  tooltip: '编辑帖子',
                  icon: Icons.edit_outlined,
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleEditPost(context), // 加载或锁定时禁用
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              if (canEdit) // 删除按钮
                GenericFloatingActionButton(
                  heroTag: deleteHeroTag,
                  mini: true,
                  tooltip: '删除帖子',
                  icon: Icons.delete_forever_outlined,
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleDeletePost(context), // 加载或锁定时禁用
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              if (canLock) // 锁定/解锁按钮
                GenericFloatingActionButton(
                  heroTag: lockHeroTag,
                  mini: true,
                  tooltip: post.status == PostStatus.locked
                      ? '解锁帖子'
                      : '锁定帖子', // 工具提示文本
                  icon: post.status == PostStatus.locked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline, // 图标
                  isLoading: _isTogglingLock, // 关联切换锁定状态
                  onPressed: (_isLoading || _isTogglingLock)
                      ? null
                      : () => _handleToggleLock(context), // 加载或锁定时禁用
                  backgroundColor: post.status == PostStatus.locked
                      ? Colors.grey[600]
                      : Colors.orange[600], // 背景颜色
                  foregroundColor: Colors.white,
                ),
              if (canPin) // 置顶/取消置顶按钮
                GenericFloatingActionButton(
                  heroTag: pinHeroTag,
                  mini: true,
                  tooltip: post.isPinned ? '取消置顶' : '置顶帖子', // 工具提示文本
                  icon: post.isPinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined, // 图标
                  isLoading: _isTogglingPin, // 关联置顶操作加载状态
                  onPressed: (_isLoading || _isTogglingLock || _isTogglingPin)
                      ? null
                      : () => _handleTogglePin(context), // 加载或锁定时禁用
                  backgroundColor: post.isPinned
                      ? Colors.blue[600]
                      : Colors.grey[600], // 背景颜色
                  foregroundColor: Colors.white,
                ),
            ],
          ),
        );
      },
    );
  }
}
