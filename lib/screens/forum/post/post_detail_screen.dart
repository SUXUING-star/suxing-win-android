// lib/screens/forum/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/forum/post/layout/post_detail_desktop_layout.dart';
import '../../../widgets/components/screen/forum/post/layout/post_detail_mobile_layout.dart';
import '../../../widgets/ui/common/error_widget.dart';
import '../../../widgets/ui/common/loading_widget.dart';
import '../../../widgets/ui/inputs/post_reply_input.dart'; // 统一回复输入组件
import '../../../widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框组件

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool needHistory;

  const PostDetailScreen(
      {Key? key, required this.postId, this.needHistory = true})
      : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _replyController = TextEditingController();
  Post? _post;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false; // 提交状态

  // 交互标志
  bool _hasInteraction = false;
  bool _isTogglingLock = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    // bool postWasRemoved = false; // 这个标志现在由 'not_found' 异常处理
    setState(() {
      _isLoading = true;
      _error = null; // 重置错误状态
      _post = null; // 重置帖子数据
    });

    try {
      // 1. 获取帖子数据 (现在会抛出更具体的异常)
      final post = await _forumService.getPost(widget.postId);

      // 如果 getPost 成功返回 post (表示有权限查看)
      if (post != null && mounted) {
        // --- 增加浏览量逻辑 (仅在成功获取帖子后执行) ---
        if (widget.needHistory) {
          try {
            // 无需等待，后台执行即可
            _forumService.incrementPostView(widget.postId);
          } catch (viewError) {
            print(
                "Warning: Failed to increment view count for post ${widget.postId}: $viewError");
            // 不阻塞主流程，只记录警告
          }
        }
        // --- 更新 UI ---
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else if (mounted) {
        // 如果 getPost 返回 null 但没抛异常 (理论上不应该发生在此场景，除非 postId 无效)
        setState(() {
          _error = '无法加载帖子，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorString = e.toString();
      print(
          "PostDetailScreen: Error loading post ${widget.postId}: $errorString");

      if (!mounted) return; // 异步操作后检查 mounted

      // --- 根据 ForumService 抛出的特定异常更新 UI ---
      if (errorString.startsWith('access_denied:')) {
        // --- 情况1：访问被拒绝 (帖子锁定或无权) ---
        setState(() {
          // 从异常消息中提取用户友好的部分
          _error = errorString.substring('access_denied:'.length).trim();
          _isLoading = false;
          _post = null; // 确保帖子数据为空
        });
        // *不* 显示“已删除”对话框，错误信息会在 build 方法中显示
      } else if (errorString.contains('not_found')) {
        // --- 情况2：帖子确实不存在或已被删除 (API 404) ---
        // postWasRemoved = true; // 不需要标志了，直接处理
        // 显示“已删除”对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CustomInfoDialog.show(
              context: context,
              title: '帖子找不到了', // 优化标题
              message: '抱歉，您要查看的帖子可能已被删除或转移。\n(返回上一页或首页会自动刷新列表)', // 优化信息
              iconData: Icons.search_off, // 换个图标
              iconColor: Colors.orange,
              closeButtonText: '知道了',
              barrierDismissible: false,
              onClose: () {
                if (mounted) {
                  try {
                    // 标记有交互（即使是错误），以便列表刷新
                    _hasInteraction = true;
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context, _hasInteraction); // 返回交互结果
                    } else {
                      NavigationUtils.navigateToHome(context);
                    }
                  } catch (popError) {
                    print(
                        "Error popping context after 'not found' dialog: $popError");
                    NavigationUtils.navigateToHome(context); // 保底导航
                  }
                }
              },
            );
            // 同时也设置错误状态，以防对话框被意外关闭
            setState(() {
              _error = '帖子不存在或已被删除';
              _isLoading = false;
              _post = null;
            });
          }
        });
      } else {
        // --- 情况3：其他加载错误 (网络、服务器内部错误、格式错误等) ---
        setState(() {
          // 直接使用 ForumService 抛出的通用错误信息
          _error = errorString;
          _isLoading = false;
          _post = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();

    // 在页面关闭时，如果有交互操作，通知前一个页面刷新
    if (_hasInteraction) {
      NavigationUtils.pop(context, true);
    }

    super.dispose();
  }

  // --- 新增：处理锁定/解锁操作 ---
  Future<void> _handleToggleLock(BuildContext context) async {
    if (_post == null || _isTogglingLock) return; // 防止重复点击或在 post 为 null 时操作

    print("PostDetailScreen: Handling toggle lock for post ${widget.postId}");
    setState(() {
      _isTogglingLock = true; // 开始操作，显示加载状态
    });

    try {
      // 调用 ForumService
      await _forumService.togglePostLock(widget.postId);
      if (!mounted) return;

      AppSnackBar.showSuccess(context, '帖子状态已切换');

      // --- 标记有交互 ---
      _hasInteraction = true;

      // --- 刷新帖子数据以获取最新状态 ---
      await _refreshPost(); // _refreshPost 内部会处理 isLoading 状态
    } catch (e) {
      if (!mounted) return;
      print(
          "PostDetailScreen: Failed to toggle lock for post ${widget.postId}: $e");
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      // 确保在操作结束后（无论成功或失败）都重置加载状态
      if (mounted) {
        setState(() {
          _isTogglingLock = false;
        });
      }
    }
  }

  // 处理交互成功回调
  void _handleInteractionSuccess() {
    // 标记有交互操作
    _hasInteraction = true;

    // 刷新当前帖子页面
    _refreshPost();
  }

  Future<void> _refreshPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _loadPost();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReply(BuildContext context) async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _forumService.addReply(widget.postId, content);
      _replyController.clear();

      // 标记有交互操作
      _hasInteraction = true;

      // 刷新当前页面
      await _refreshPost();

      // Show confirmation
      AppSnackBar.showSuccess(context, '回复成功');
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 使用可复用的确认对话框
  Future<void> _handleDeletePost(BuildContext context) async {
    // 使用ConfirmDialog
    CustomConfirmDialog.show(
      context: context,
      title: '删除帖子',
      message: '确定要删除这个帖子吗？删除后无法恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          // 显示加载状态
          setState(() {
            _isLoading = true;
          });

          await _forumService.deletePost(widget.postId);

          // 标记有交互操作
          _hasInteraction = true;

          // 返回，并传递更新标志
          NavigationUtils.pop(context, true);

          // 显示成功消息
          AppSnackBar.showSuccess(context, '帖子已删除');
        } catch (e) {
          // 取消加载状态
          setState(() {
            _isLoading = false;
          });

          AppSnackBar.showError(context, '删除失败：${e.toString()}');
        }
      },
    );
  }

  // 处理编辑帖子
  Future<void> _handleEditPost(BuildContext context) async {
    if (_post == null) return;

    // 跳转到编辑页面
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: widget.postId,
    );

    // 如果编辑成功，刷新页面
    if (result == true) {
      _hasInteraction = true;
      await _refreshPost();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop ||
        DeviceUtils.isWeb ||
        DeviceUtils.isTablet(context);

    // 使用新的加载和错误组件
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载帖子...')),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: FadeInItem(
            child: InlineErrorWidget(
          errorMessage: '加载错误',
          onRetry: _loadPost,
        )),
      );
    }

    if (_post == null) {
      return NotFoundErrorWidget(
        message: '请求的帖子不存在',
        onBack: () => NavigationUtils.pop(context),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: '帖子详情',
        actions: [
          _buildMoreMenu(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPost,
        child: isDesktop
            ? PostDetailDesktopLayout(
                post: _post!,
                postId: widget.postId,
                replyInput: PostReplyInput(
                  post: _post,
                  controller: _replyController,
                  onSubmitReply: _submitReply,
                  isSubmitting: _isSubmitting,
                  isDesktopLayout: true,
                ),
                // 传递交互成功回调
                onInteractionSuccess: _handleInteractionSuccess,
              )
            : PostDetailMobileLayout(
                post: _post!,
                postId: widget.postId,
                // 传递交互成功回调
                onInteractionSuccess: _handleInteractionSuccess,
              ),
      ),
      // --- 添加 FAB 组 ---
      floatingActionButton: _post != null
          ? _buildPostActionButtonsGroup(context, _post!)
          : null, // 如果 post 为 null，不显示按钮
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isDesktop
          ? null
          : PostReplyInput(
              post: _post,
              controller: _replyController,
              onSubmitReply: _submitReply,
              isSubmitting: _isSubmitting,
              isDesktopLayout: false,
            ),
    );
  }

  Widget _buildMoreMenu() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn || _post == null) return const SizedBox.shrink();

        final bool canEdit = auth.currentUser?.id == _post!.authorId;
        final bool canDelete = canEdit || auth.currentUser?.isAdmin == true;
        // --- 检查是否可以切换锁定状态 (仅管理员) ---
        final bool canToggleLock = auth.currentUser?.isAdmin == true;

        if (!canEdit && !canDelete && !canToggleLock) {
          return const SizedBox.shrink();
        }

        return StylishPopupMenuButton<String>(
          // *** 直接用这个！***
          icon: Icons.more_vert,
          tooltip: '更多选项',
          isEnabled: !_isTogglingLock,
          menuColor: Colors.white, // 设置菜单背景
          elevation: 1.0, // 设置阴影
          itemHeight: 40, // 统一设置项高

          // *** 直接提供数据列表！***
          items: [
            // 编辑选项
            if (canEdit)
              StylishMenuItemData(
                // **提供数据**
                value: 'edit',
                child: Text('编辑'), // **提供内容**
              ),

            // 删除选项
            if (canDelete)
              StylishMenuItemData(
                // **提供数据**
                value: 'delete',
                child: AppText('删除',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.error)), // **提供内容**
              ),

            // 分割线标记
            if (canToggleLock && (canEdit || canDelete))
              const StylishMenuDividerData(), // **标记分割线**

            // 锁定/解锁选项
            if (canToggleLock)
              StylishMenuItemData(
                // **提供数据**
                value: 'toggle_lock',
                // **提供 Row 作为内容**
                child: Row(
                  children: [
                    Icon(
                      _post!.status == PostStatus.locked
                          ? Icons.lock_open
                          : Icons.lock,
                      size: 18,
                      color: _post!.status == PostStatus.locked
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(_post!.status == PostStatus.locked ? '解锁帖子' : '锁定帖子'),
                  ],
                ),
                // enabled: someCondition, // 也可以单独控制某一项的启用状态
              ),
          ],
          onSelected: (value) async {
            // --- 在 onSelected 中处理 ---
            switch (value) {
              case 'edit':
                await _handleEditPost(context);
                break;
              case 'delete':
                await _handleDeletePost(context);
                break;
              // --- 处理 toggle_lock ---
              case 'toggle_lock':
                await _handleToggleLock(context); // 调用新的处理函数
                break;
            }
          },
        );
      },
    );
  }

  // 在 _PostDetailScreenState 类内部添加
  Widget _buildPostActionButtonsGroup(BuildContext context, Post post) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 检查是否登录以及帖子数据是否存在
        if (!auth.isLoggedIn || _post == null) {
          return const SizedBox.shrink(); // 未登录或无数据则不显示按钮
        }

        final bool canEdit = auth.currentUser?.id == post.authorId;
        final bool canDelete = canEdit || auth.currentUser?.isAdmin == true;

        // 如果没有任何权限，也不显示按钮组
        if (!canEdit && !canDelete) {
          return const SizedBox.shrink();
        }

        // 为按钮定义 Hero Tags
        final String editHeroTag = 'postEditFab_${post.id}';
        final String deleteHeroTag = 'postDeleteFab_${post.id}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButtonGroup(
            spacing: 16.0,
            alignment: MainAxisAlignment.end,
            children: [
              // --- 编辑按钮 ---
              if (canEdit)
                GenericFloatingActionButton(
                  heroTag: editHeroTag,
                  mini: true, // 使用小尺寸
                  tooltip: '编辑帖子',
                  icon: Icons.edit,
                  onPressed: _isLoading
                      ? null
                      : () => _handleEditPost(context), // 加载中禁用
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),

              // --- 删除按钮 ---
              if (canDelete)
                GenericFloatingActionButton(
                  heroTag: deleteHeroTag,
                  mini: true, // 使用小尺寸
                  tooltip: '删除帖子',
                  icon: Icons.delete_forever,
                  // 使用 isLoading 状态来控制按钮是否显示加载指示器和禁用
                  isLoading: _isLoading, // 在执行删除操作时，此按钮会显示加载状态
                  onPressed: _isLoading
                      ? null
                      : () => _handleDeletePost(context), // 加载中禁用
                  backgroundColor: Colors.red[400], // 删除用红色背景
                  foregroundColor: Colors.white, // 白色图标
                ),

              // --- 注意：锁定/解锁功能未包含在此 FAB 组中 ---
              // 如果需要，可以作为第三个按钮添加，同样需要权限判断和回调
            ],
          ),
        );
      },
    );
  }
}
