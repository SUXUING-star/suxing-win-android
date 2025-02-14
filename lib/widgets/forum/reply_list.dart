// lib/widgets/forum/reply_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';
import '../../screens/profile/open_profile_screen.dart';
import '../../providers/auth_provider.dart';

class ReplyList extends StatefulWidget {
  final String postId;

  const ReplyList({Key? key, required this.postId}) : super(key: key);

  @override
  _ReplyListState createState() => _ReplyListState();
}

class _ReplyListState extends State<ReplyList> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reply>>(
      stream: _forumService.getReplies(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final replies = snapshot.data!;
        if (replies.isEmpty) {
          return const Center(child: Text('暂无回复'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: replies.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) => _buildReplyItem(context, replies[index], index + 1),
        );
      },
    );
  }

  Widget _buildReplyItem(BuildContext context, Reply reply, int floor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 左侧用户信息
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _userService.getUserInfoById(reply.authorId),
                  builder: (context, snapshot) {
                    final username = snapshot.data?['username'] ?? '';
                    final avatarUrl = snapshot.data?['avatar'];

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OpenProfileScreen(userId: reply.authorId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 14,
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null && username.isNotEmpty
                              ? Text(username[0].toUpperCase())
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: _userService.getUserInfoById(reply.authorId),
                  builder: (context, snapshot) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120),
                      child: Text(
                        snapshot.data?['username'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$floor楼',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reply.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align items to the right
                children: [
                  Text(
                    reply.createTime.toString().substring(0, 16),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  _buildReplyActions(context, reply),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyActions(BuildContext context, Reply reply) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Debug logs
        print('Auth check - Current user ID: ${auth.currentUser?.id}');
        print('Auth check - Reply author ID: ${reply.authorId}');
        print('Auth check - Is logged in: ${auth.isLoggedIn}');
        print('Auth check - Is admin: ${auth.currentUser?.isAdmin}');

        // 如果用户未登录，不显示按钮
        if (!auth.isLoggedIn) {
          return const SizedBox.shrink();
        }

        // 将 ObjectId 转换为字符串进行比较
        final currentUserId = auth.currentUser?.id;
        final replyAuthorId = reply.authorId.replaceAll('ObjectId("', '').replaceAll('")', '');

        // 如果是本人的评论或者是管理员，显示按钮
        final isAuthor = currentUserId == replyAuthorId;
        final isAdmin = auth.currentUser?.isAdmin ?? false;

        if (!isAuthor && !isAdmin) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('编辑'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _handleEditReply(context, reply);
                    break;
                  case 'delete':
                    _handleDeleteReply(context, reply);
                    break;
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleEditReply(BuildContext context, Reply reply) async {
    try {
      final newContent = await showDialog<String>(
        context: context,
        builder: (context) {
          final textController = TextEditingController(text: reply.content);
          return AlertDialog(
            title: const Text('编辑回复'),
            content: TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '输入新的回复内容',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(textController.text),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );

      if (newContent != null && newContent.trim().isNotEmpty) {
        await _forumService.updateReply(reply.id, newContent);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回复编辑成功')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('编辑失败：$e')),
      );
    }
  }

  Future<void> _handleDeleteReply(BuildContext context, Reply reply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个回复吗？删除后不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _forumService.deleteReply(reply.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回复删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }
}