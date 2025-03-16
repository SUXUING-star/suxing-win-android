// lib/widgets/components/screen/forum/post/reply/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../badge/info/user_info_badge.dart'; // 导入UserInfoBadge

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final int floor;
  final ForumService _forumService = ForumService();

  ReplyItem({Key? key, required this.reply, required this.floor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 使用UserInfoBadge替换原有的用户信息显示
            Expanded(
              child: UserInfoBadge(
                userId: reply.authorId,
                showFollowButton: false, // 不显示关注按钮
                mini: true, // 使用迷你版本
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
            const SizedBox(width: 8),
            _buildReplyActions(context, reply),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reply.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add reply button to reply to this specific reply
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();

                      return TextButton.icon(
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('回复', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          // Show a bottom sheet with the reply input
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        '回复 ${floor}楼',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  Text(
                    DateTimeFormatter.formatStandard(reply.createTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
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