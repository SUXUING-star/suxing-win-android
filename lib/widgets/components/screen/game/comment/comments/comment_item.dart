import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // Keep for dialogs
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../replies/reply_list.dart';
import '../replies/reply_input.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';
import '../../../../../ui/buttons/custom_popup_menu_button.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final Future<void> Function(String id, String newContent) onUpdate;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String content, String parentId) onAddReply;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddReply,
  }) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  // REMOVED: final GameService _commentService = GameService();
  bool _showReplyInput = false;
  bool _isSubmittingReply = false; // Local state for reply input

  // --- Action Buttons (No change needed in structure, only in onSelected) ---
  Widget _buildCommentActions(BuildContext context, Comment comment) {
    return CustomPopupMenuButton<String>(
      // ... (外观代码不变)
      icon: Icons.more_vert,
      iconSize: 20,
      iconColor: Colors.grey[600],
      padding: const EdgeInsets.all(0),
      tooltip: '评论选项',
      elevation: 4,
      splashRadius: 18,

      onSelected: (value) async {
        // Make async
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
        // ... (itemBuilder logic不变)
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final List<PopupMenuEntry<String>> items = [];
        if (!authProvider.isLoggedIn) return items;
        bool canEdit = comment.userId == authProvider.currentUser?.id;
        bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;
        // ... (add items based on canEdit/canDelete)
        if (canEdit) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  const Text('编辑'),
                ],
              ),
            ),
          );
        }
        if (canEdit && canDelete) {
          items.add(const PopupMenuDivider(height: 1));
        }
        if (canDelete) {
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 10),
                  Text('删除', style: TextStyle(color: Colors.red[700])),
                ],
              ),
            ),
          );
        }
        return items;
      },
    );
  }

  // --- Dialogs (Call Parent's Callbacks) ---
  void _showEditDialog(BuildContext context, Comment comment) {
    EditDialog.show(
      context: context,
      title: '编辑评论',
      initialText: comment.content,
      hintText: '编辑评论内容...',
      onSave: (text) async {
        // --- Call parent's update callback ---
        try {
          await widget.onUpdate(widget.comment.id, text);
          // Success message is now handled by CommentsSection
        } catch (e) {
          // Error message is now handled by CommentsSection or rethrown
          if (context.mounted)
            AppSnackBar.showError(context, '编辑失败: $e'); // Fallback
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment) {
    CustomConfirmDialog.show(
      context: context,
      title: '删除评论',
      message: '确定要删除这条评论吗？\n(评论下的所有回复也会被删除)',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        // --- Call parent's delete callback ---
        try {
          await widget.onDelete(widget.comment.id);
          // Success message is now handled by CommentsSection
        } catch (e) {
          // Error message is now handled by CommentsSection or rethrown
          if (context.mounted)
            AppSnackBar.showError(context, '删除失败: $e'); // Fallback
        }
      },
    );
  }

  // --- Handle Reply Submission ---
  Future<void> _submitReply(String replyContent) async {
    if (replyContent.isEmpty) return;
    setState(() => _isSubmittingReply = true);
    try {
      // --- Call parent's add reply callback ---
      await widget.onAddReply(replyContent, widget.comment.id);
      // Reply added, StreamBuilder in CommentsSection updates the list
      if (mounted) {
        setState(() {
          _showReplyInput = false; // Hide input on success
        });
      }
      // Success snackbar is handled by CommentsSection
    } catch (e) {
      // Error is handled by CommentsSection
      if (mounted) AppSnackBar.showError(context, '回复失败: $e'); // Fallback
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      // ... (Card styling 不变)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header (Pass comment to actions) ---
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: UserInfoBadge(
                    userId: widget.comment.userId,
                    showFollowButton: false,
                  ),
                ),
                if (authProvider.isLoggedIn &&
                    (widget.comment.userId == authProvider.currentUser?.id ||
                        authProvider.currentUser?.isAdmin == true))
                  _buildCommentActions(context, widget.comment), // Pass comment
              ],
            ),
          ),
          // --- Content & Time (不变) ---
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              widget.comment.content,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateTimeFormatter.formatRelative(widget.comment.createTime) +
                    (widget.comment.isEdited ? ' (已编辑)' : ''),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5),
          // --- Reply Button (不变) ---
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (!authProvider.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先登录后才能回复')));
                      return;
                    }
                    setState(() {
                      _showReplyInput = !_showReplyInput;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showReplyInput ? Icons.close : Icons.reply,
                          size: 16),
                      const SizedBox(width: 4),
                      Text(_showReplyInput ? '收起' : '回复'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Reply List (Pass callbacks down) ---
          if (widget.comment.replies.isNotEmpty)
            ReplyList(
              replies: widget.comment.replies,
              // Pass the *specific* update/delete callbacks for replies
              onUpdateReply: widget
                  .onUpdate, // Assuming update logic is the same for comment/reply
              onDeleteReply:
                  widget.onDelete, // Assuming delete logic is the same
              // REMOVED: gameId
              // REMOVED: onReplyChanged
            ),

          // --- Reply Input (Pass submit callback) ---
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _showReplyInput,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ReplyInput(
                  // REMOVED: gameId
                  // REMOVED: parentId (handled in _submitReply)
                  onSubmitReply: _submitReply, // Pass the local submit handler
                  isSubmitting: _isSubmittingReply, // Pass local loading state
                  onCancel: () {
                    setState(() {
                      _showReplyInput = false;
                    });
                  },
                  // REMOVED: onReplyAdded
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
