// lib/screens/forum/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../routes/app_routes.dart';

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
      return const LoadingIndicator();
    }

    if (_error != null) {
      return ErrorMessage(message: _error!);
    }

    if (_post == null) {
      return const Center(child: Text('帖子不存在'));
    }

    return Column(
      children: [
        _buildPostContent(),
        const Divider(height: 1),
        Expanded(child: _buildReplies()),
      ],
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _post!.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(_post!.authorName[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              Text(_post!.authorName),
              const Spacer(),
              Text(_post!.createTime.toString().substring(0, 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_post!.content),
          if (_post!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post!.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplies() {
    return StreamBuilder<List<Reply>>(
      stream: _forumService.getReplies(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorMessage(message: snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }

        final replies = snapshot.data!;
        if (replies.isEmpty) {
          return const Center(child: Text('暂无回复'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: replies.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) => _buildReplyItem(replies[index]),
        );
      },
    );
  }

  Widget _buildReplyItem(Reply reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              child: Text(reply.authorName[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
            Text(reply.authorName),
            const Spacer(),
            Text(reply.createTime.toString().substring(0, 16)),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.currentUser?.id == reply.authorId ||
                    auth.currentUser?.isAdmin == true) {
                  return PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      if (auth.currentUser?.id == reply.authorId)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('编辑'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('删除'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // 显示编辑对话框
                        final content = await showDialog<String>(
                          context: context,
                          builder: (context) => _EditReplyDialog(
                            initialContent: reply.content,
                          ),
                        );
                        if (content != null) {
                          await _forumService.updateReply(reply.id, content);
                        }
                      } else if (value == 'delete') {
                        // 显示确认对话框
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('确定要删除这条回复吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _forumService.deleteReply(reply.id);
                        }
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(reply.content),
      ],
    );
  }

  Widget _buildReplyInput() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return const SizedBox.shrink();
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
                    onPressed: () async {
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
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              break;
            case 'toggle_lock':
              try {
                await _forumService.togglePostLock(widget.postId);
                await _loadPost(); // Reload post to update status
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
              break;
          }
        },
      );
        });
  }
}

class _EditReplyDialog extends StatefulWidget {
  final String initialContent;

  const _EditReplyDialog({required this.initialContent});

  @override
  _EditReplyDialogState createState() => _EditReplyDialogState();
}

class _EditReplyDialogState extends State<_EditReplyDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑回复'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: '请输入回复内容',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final content = _controller.text.trim();
            if (content.isNotEmpty) {
              Navigator.pop(context, content);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}