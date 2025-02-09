// lib/widgets/forum/reply_list.dart
import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';
import '../../screens/profile/open_profile_screen.dart';

class ReplyList extends StatelessWidget {
  final String postId;
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();

  ReplyList({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reply>>(
      stream: _forumService.getReplies(postId),
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

                    return MouseRegion( // 添加 MouseRegion
                      cursor: SystemMouseCursors.click, // 设置鼠标指针
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
            // 右侧时间和操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.createTime.toString().substring(0, 16),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                _buildReplyActions(context, reply),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            reply.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildReplyActions(BuildContext context, Reply reply) {
    return PopupMenuButton<String>(
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
        // 处理编辑和删除操作
      },
    );
  }
}