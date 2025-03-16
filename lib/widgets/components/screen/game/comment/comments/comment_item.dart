// lib/widgets/components/screen/game/comment/comment_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../replies/reply_list.dart';
import '../replies/reply_input.dart';
import '../../../../badge/info/user_info_badge.dart'; // 导入UserInfoBadge

class CommentItem extends StatefulWidget {
  final Comment comment;
  final String gameId;
  final VoidCallback? onCommentChanged;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.gameId,
    this.onCommentChanged,
  }) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final CommentService _commentService = CommentService();
  bool _isDeleting = false;

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
                Navigator.pop(context);
                await _commentService.updateComment(
                  comment.id,
                  controller.text.trim(),
                );

                if (widget.onCommentChanged != null) {
                  widget.onCommentChanged!();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论已更新')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('编辑评论失败：$e')),
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

  void _showDeleteDialog(BuildContext context, Comment comment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
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
                await _commentService.deleteComment(comment.id);

                if (widget.onCommentChanged != null) {
                  widget.onCommentChanged!();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论已删除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除评论失败：$e')),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 使用UserInfoBadge替换原有的用户信息显示
                Expanded(
                  child: UserInfoBadge(
                    userId: widget.comment.userId,
                    showFollowButton: false, // 不显示关注按钮
                  ),
                ),
                // 时间标签
                Text(
                  DateTimeFormatter.formatStandard(widget.comment.createTime) +
                      (widget.comment.isEdited ? ' (已编辑)' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                // 评论操作菜单
                _buildCommentActions(context, widget.comment),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.comment.content),
          ),
          if (widget.comment.replies.isNotEmpty) ...[
            const Divider(),
            ReplyList(
              replies: widget.comment.replies,
              onReplyChanged: widget.onCommentChanged,
            ),
          ],
          ReplyInput(
            gameId: widget.gameId,
            parentId: widget.comment.id,
            onReplyAdded: widget.onCommentChanged,
          ),
        ],
      ),
    );
  }
}