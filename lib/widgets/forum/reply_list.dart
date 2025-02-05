// lib/widgets/forum/reply_list.dart
import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';

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
            FutureBuilder<String?>(
              future: _userService.getAvatarFromId(reply.authorId),
              builder: (context, snapshot) {
                return CircleAvatar(
                  radius: 14,
                  backgroundImage: snapshot.data != null
                      ? NetworkImage(snapshot.data!)
                      : null,
                  child: snapshot.data == null
                      ? Text(reply.authorName[0].toUpperCase())
                      : null,
                );
              },
            ),
            const SizedBox(width: 8),
            Text(reply.authorName),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            const Spacer(),
            Text(reply.createTime.toString().substring(0, 16)),
            _buildReplyActions(context, reply),
          ],
        ),
        const SizedBox(height: 8),
        Text(reply.content),
      ],
    );
  }

  Widget _buildReplyActions(BuildContext context, Reply reply) {
    // 从原 PostDetailScreen 复制过来的回复操作菜单代码
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