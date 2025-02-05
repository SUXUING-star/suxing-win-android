// lib/screens/forum/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/forum/post_content.dart';
import '../../widgets/forum/reply_list.dart';

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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final post = await _forumService.getPost(widget.postId);
      if (post == null) throw Exception('帖子不存在');

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子详情'),
        actions: [
          if (_post != null) _buildMoreMenu(),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildReplyInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_post == null) {
      return const Center(child: Text('帖子不存在'));
    }

    return Column(
      children: [
        PostContent(post: _post!),
        const Divider(height: 1),
        Expanded(
          child: ReplyList(postId: widget.postId),
        ),
      ],
    );
  }

  Widget _buildReplyInput() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('登录后回复'),
            ),
          );
        }

        if (_post?.status == PostStatus.locked) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: const Text('该帖子已被锁定，无法回复'),
          );
        }

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: '写下你的回复...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _submitReply(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReply(BuildContext context) async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    try {
      await _forumService.addReply(widget.postId, content);
      _replyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
        await _forumService.deletePost(widget.postId);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
}