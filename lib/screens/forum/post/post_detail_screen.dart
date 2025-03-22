import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../services/main/history/post_history_service.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/forum/post/layout/desktop/desktop_layout.dart';
import '../../../widgets/components/screen/forum/post/layout/mobile/mobile_layout.dart';
import '../../../widgets/components/common/error_widget.dart';
import '../../../widgets/components/common/loading_widget.dart';
import '../../../widgets/components/screen/forum/post/reply/desktop_reply_input.dart';
import '../../../widgets/components/screen/forum/post/reply/mobile_reply_input.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ForumService _forumService = ForumService();
  final PostHistoryService _postHistoryService = PostHistoryService();
  final TextEditingController _replyController = TextEditingController();
  Post? _post;
  String? _error;
  bool _isLoading = true;

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

      await _postHistoryService.addPostHistory(widget.postId);
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
    super.dispose();
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

    try {
      await _forumService.addReply(widget.postId, content);
      _replyController.clear();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回复成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleDeletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个帖子吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 显示加载状态
        setState(() {
          _isLoading = true;
        });

        await _forumService.deletePost(widget.postId);

        // 返回，并传递更新标志
        Navigator.pop(context, true);

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
    }
  }

  Future<void> _handleToggleLock(BuildContext context) async {
    try {
      await _forumService.togglePostLock(widget.postId);
      await _loadPost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
          onBack: () => Navigator.pop(context),
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
          replyInput: DesktopReplyInput(
            post: _post!,
            replyController: _replyController,
            onSubmitReply: _submitReply,
          ),
        )
            : MobileLayout(
          post: _post!,
          postId: widget.postId,
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : MobileReplyInput(
        post: _post,
        replyController: _replyController,
        onSubmitReply: _submitReply,
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
                Navigator.pushNamed(
                  context,
                  AppRoutes.editPost,
                  arguments: _post,
                );
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