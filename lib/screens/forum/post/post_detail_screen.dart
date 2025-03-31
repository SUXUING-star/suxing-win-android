// lib/screens/forum/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/forum/post/layout/desktop/desktop_layout.dart';
import '../../../widgets/components/screen/forum/post/layout/mobile/mobile_layout.dart';
import '../../../widgets/ui/common/error_widget.dart';
import '../../../widgets/ui/common/loading_widget.dart';
import '../../../widgets/ui/inputs/post_reply_input.dart'; // 统一回复输入组件
import '../../../widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框组件

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final post = await _forumService.getPost(widget.postId);
      if (post == null) {
        throw Exception('帖子不存在');
      }

      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回复成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('帖子已删除')),
          );
        } catch (e) {
          // 取消加载状态
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${e.toString()}')),
          );
        }
      },
    );
  }

  // 使用可复用的确认对话框
  Future<void> _handleToggleLock(BuildContext context) async {
    final statusText = _post?.status == PostStatus.locked ? '解锁' : '锁定';

    // 使用ConfirmDialog
    CustomConfirmDialog.show(
      context: context,
      title: '$statusText帖子',
      message: '确定要$statusText这个帖子吗？',
      confirmButtonText: '确定',
      confirmButtonColor: Colors.blue,
      onConfirm: () async {
        try {
          await _forumService.togglePostLock(widget.postId);

          // 标记有交互操作
          _hasInteraction = true;

          await _loadPost();

          // 显示成功消息
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('帖子已$statusText')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$statusText失败: ${e.toString()}')),
            );
          }
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
      arguments: _post,
    );

    // 如果编辑成功，刷新页面
    if (result == true) {
      _hasInteraction = true;
      await _refreshPost();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop || DeviceUtils.isWeb || DeviceUtils.isTablet(context);

    // 使用新的加载和错误组件
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: LoadingWidget.fullScreen(message: '正在加载帖子...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: CustomErrorWidget(
          errorMessage: _error!,
          onRetry: _loadPost,
          title: '加载错误',
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: CustomAppBar(title: '帖子详情'),
        body: NotFoundErrorWidget(
          message: '请求的帖子不存在',
          onBack: () => NavigationUtils.pop(context),
        ),
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
            ? DesktopLayout(
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
            : MobileLayout(
          post: _post!,
          postId: widget.postId,
          // 传递交互成功回调
          onInteractionSuccess: _handleInteractionSuccess,
        ),
      ),
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
        if (!auth.isLoggedIn) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          itemBuilder: (context) => [
            if (auth.currentUser?.id == _post?.authorId)
              const PopupMenuItem(
                value: 'edit',
                child: Text('编辑'),
              ),
            if (auth.currentUser?.id == _post?.authorId ||
                auth.currentUser?.isAdmin == true)
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除'),
              ),
            if (auth.currentUser?.isAdmin == true)
              PopupMenuItem(
                value: 'toggle_lock',
                child: Text(
                  _post?.status == PostStatus.locked ? '解锁帖子' : '锁定帖子',
                ),
              ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _handleEditPost(context);
                break;
              case 'delete':
                await _handleDeletePost(context);
                break;
              case 'toggle_lock':
                await _handleToggleLock(context);
                break;
            }
          },
        );
      },
    );
  }
}