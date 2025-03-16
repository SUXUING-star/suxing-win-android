// lib/widgets/components/screen/game/comment/replies/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../badge/info/user_info_badge.dart'; // 导入UserInfoBadge

class ReplyItem extends StatefulWidget {
  final Comment reply;
  final VoidCallback? onReplyChanged;

  const ReplyItem({
    Key? key,
    required this.reply,
    this.onReplyChanged,
  }) : super(key: key);

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
  final CommentService _commentService = CommentService();
  bool _isDeleting = false;

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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                Navigator.pop(dialogContext);
                await _commentService.updateComment(
                  reply.id,
                  controller.text.trim(),
                );

                if (widget.onReplyChanged != null) {
                  widget.onReplyChanged!();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('回复已更新')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('编辑回复失败：$e')),
                  );
                }
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除回复'),
        content: const Text('确定要删除这条回复吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          _isDeleting
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : ElevatedButton(
            onPressed: () async {
              try {
                setState(() {
                  _isDeleting = true;
                });

                Navigator.pop(dialogContext);
                await _commentService.deleteComment(reply.id);

                if (widget.onReplyChanged != null) {
                  widget.onReplyChanged!();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('回复已删除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除回复失败：$e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 使用UserInfoBadge替换原有的用户信息显示
                Expanded(
                  child: UserInfoBadge(
                    userId: widget.reply.userId,
                    showFollowButton: false, // 不显示关注按钮
                    mini: true, // 使用迷你版本
                    backgroundColor: Colors.grey[50], // 轻微的背景色以区分回复
                  ),
                ),
                // 时间标签
                Text(
                  DateTimeFormatter.formatStandard(widget.reply.createTime) +
                      (widget.reply.isEdited ? ' (已编辑)' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                // 回复操作菜单
                _buildReplyActions(context, widget.reply),
              ],
            ),
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