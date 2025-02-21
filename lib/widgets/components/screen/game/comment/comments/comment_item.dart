// lib/widgets/game/comment/comment_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../../../services/main/user/user_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../screens/profile/open_profile_screen.dart';
import '../replies/reply_list.dart';
import '../replies/reply_input.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final String gameId;

  const CommentItem({Key? key, required this.comment, required this.gameId}) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final UserService _userService = UserService();
  final CommentService _commentService = CommentService();
  final Map<String, Future<Map<String, dynamic>>> _userInfoCache = {};

  Future<Map<String, dynamic>> _getUserInfo(String userId) {
    _userInfoCache[userId] ??= _userService.getUserInfoById(userId);
    return _userInfoCache[userId]!;
  }

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, String userId, String fallbackUsername) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final username = snapshot.data?['username'] ?? fallbackUsername;
        final avatarUrl = snapshot.data?['avatar'];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _navigateToProfile(context, userId),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null && username.isNotEmpty
                  ? Text(
                username[0].toUpperCase(),
                style: const TextStyle(fontSize: 16),
              )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentActions(BuildContext context, Comment comment) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _showEditDialog(context, comment);
            break;
          case 'delete':
            _showDeleteDialog(context, comment);
            break;
        }
      },
      itemBuilder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) return [];

        return [
          if (comment.userId == authProvider.currentUser?.id) ...[
            const PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
          ],
          if (comment.userId == authProvider.currentUser?.id ||
              authProvider.currentUser?.isAdmin == true) ...[
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除'),
            ),
          ],
        ];
      },
    );
  }

  void _showEditDialog(BuildContext context, Comment comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑评论'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '编辑评论内容...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await _commentService.updateComment(
                  comment.id,
                  controller.text.trim(),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('编辑评论失败：$e')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _commentService.deleteComment(comment.id);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除评论失败：$e')),
                );
              }
            },
            child: const Text('删除'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: _buildUserAvatar(context, widget.comment.userId, widget.comment.username),
            ),
            title: FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(widget.comment.userId),
              builder: (context, snapshot) {
                final username = snapshot.data?['username'] ?? widget.comment.username;
                return Text(username.isNotEmpty ? username : '未知用户');
              },
            ),
            subtitle: Text(
              _formatDate(widget.comment.createTime) +
                  (widget.comment.isEdited ? ' (已编辑)' : ''),
            ),
            trailing: _buildCommentActions(context, widget.comment),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.comment.content),
          ),
          if (widget.comment.replies.isNotEmpty) ...[
            const Divider(),
            ReplyList(replies: widget.comment.replies),
          ],
          ReplyInput(gameId: widget.gameId, parentId: widget.comment.id),
        ],
      ),
    );
  }
}