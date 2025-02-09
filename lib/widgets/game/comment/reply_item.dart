// lib/widgets/game/comment/reply_item.dart
import 'package:flutter/material.dart';
import '../../../models/comment.dart';
import '../../../services/user_service.dart';
import '../../../screens/profile/open_profile_screen.dart';

class ReplyItem extends StatefulWidget {
  final Comment reply;

  const ReplyItem({Key? key, required this.reply}) : super(key: key);

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
  final UserService _userService = UserService();
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
            // trailing: _buildCommentActions(context, widget.reply), // 将回复的操作按钮也放入这里
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