// lib/widgets/game/comment/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../services/main/user/user_service.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../screens/profile/open_profile_screen.dart';

class ReplyItem extends StatefulWidget {
  final Comment reply;

  const ReplyItem({Key? key, required this.reply}) : super(key: key);

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
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

  Widget _buildReplyActions(BuildContext context, Comment reply) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _showEditDialog(context, reply);
            break;
          case 'delete':
            _showDeleteDialog(context, reply);
            break;
        }
      },
      itemBuilder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) return [];

        return [
          if (reply.userId == authProvider.currentUser?.id) ...[
            const PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
          ],
          if (reply.userId == authProvider.currentUser?.id ||
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

  void _showEditDialog(BuildContext context, Comment reply) {
    final controller = TextEditingController(text: reply.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑回复'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '编辑回复内容...',
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
                  reply.id,
                  controller.text.trim(),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('编辑回复失败：$e')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Comment reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除回复'),
        content: const Text('确定要删除这条回复吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _commentService.deleteComment(reply.id);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除回复失败：$e')),
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
    return Container(
      margin: const EdgeInsets.only(left: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: _buildUserAvatar(context, widget.reply.userId, widget.reply.username),
            ),
            title: FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(widget.reply.userId),
              builder: (context, snapshot) {
                final username = snapshot.data?['username'] ?? widget.reply.username;
                return Text(username.isNotEmpty ? username : '未知用户');
              },
            ),
            subtitle: Text(
              _formatDate(widget.reply.createTime) +
                  (widget.reply.isEdited ? ' (已编辑)' : ''),
            ),
            trailing: _buildReplyActions(context, widget.reply),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.reply.content),
          ),
        ],
      ),
    );
  }
}