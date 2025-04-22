// lib/widgets/components/screen/game/comment/comments/comment_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../replies/reply_list.dart'; // 导入 ReplyList
import '../replies/reply_input.dart'; // 导入 ReplyInput
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  // *** 接收来自 CommentList (最终来自 CommentsSection) 的操作函数 ***
  // *** 这些函数的签名是需要 ID 的版本 ***
  final Future<void> Function(String commentId, String newContent)
      onUpdateComment;
  final Future<void> Function(String commentId) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;
  // 接收 loading 状态
  final bool isDeleting;
  final bool isUpdating;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onUpdateComment, // 接收需要 ID 的 onUpdate
    required this.onDeleteComment, // 接收需要 ID 的 onDelete
    required this.onAddReply, // 接收 onAddReply
    this.isDeleting = false,
    this.isUpdating = false,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplyInput = false;
  bool _isSubmittingReply = false; // 本地回复 loading

  // Action Buttons: 调用时传入 widget.comment.id
  Widget _buildCommentActions(BuildContext context, Comment comment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    final bool canEdit = comment.userId == authProvider.currentUser?.id;
    final bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;

    if (!canEdit && !canDelete) return const SizedBox.shrink();

    return StylishPopupMenuButton<String>( // *** 使用新组件 ***
      icon: Icons.more_vert,
      iconSize: 20,
      iconColor: Colors.grey[600],
      triggerPadding: const EdgeInsets.all(0),
      tooltip: '评论选项',
      menuColor: theme.canvasColor,
      elevation: 2.0,
      itemHeight: 40,
      // *** 按钮整体是否可用，取决于 widget 的 loading 状态 ***
      isEnabled: !widget.isDeleting && !widget.isUpdating,

      // *** 直接提供数据列表 ***
      items: [
        // 编辑选项
        if (canEdit)
          StylishMenuItemData( // **提供数据**
            value: 'edit',
            // **提供内容 (Row)**
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10), const Text('编辑'),
            ],),
          ),

        // 分割线
        if (canEdit && canDelete)
          const StylishMenuDividerData(), // **标记分割线**

        // 删除选项
        if (canDelete)
          StylishMenuItemData( // **提供数据**
            value: 'delete',
            // **提供内容 (根据 widget.isDeleting 显示不同 Row)**
            child: widget.isDeleting
                ? Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.disabledColor)),
              const SizedBox(width: 10), Text('删除中...', style: TextStyle(color: theme.disabledColor)),
            ],)
                : Row(children: [
              Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 10), Text('删除', style: TextStyle(color: theme.colorScheme.error)),
            ],),
            // **单独控制删除项的启用状态**
            enabled: !widget.isDeleting,
          ),
      ],

      // onSelected 逻辑不变
      onSelected: (value) {
        switch (value) {
          case 'edit': _showEditDialog(context, comment); break;
          case 'delete': if (!widget.isDeleting) _showDeleteDialog(context, comment); break;
        }
      },
    );
  }

  // Dialogs: 调用 widget 的回调，传入 widget.comment.id
  void _showEditDialog(BuildContext context, Comment comment) {
    EditDialog.show(
      context: context, title: '编辑评论', initialText: comment.content,
      hintText: '编辑评论内容...',
      // isSaving: widget.isUpdating, // 如果 Dialog 支持 loading
      onSave: (text) async {
        // *** 调用 widget.onUpdateComment，传入 comment.id ***
        await widget.onUpdateComment(widget.comment.id, text);
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment) {
    CustomConfirmDialog.show(
      context: context, title: '删除评论', message: '确定要删除这条评论吗？\n(评论下的所有回复也会被删除)',
      confirmButtonText: '删除', confirmButtonColor: Colors.red,
      // isConfirming: widget.isDeleting, // 如果 Dialog 支持 loading
      onConfirm: () async {
        // *** 调用 widget.onDeleteComment，传入 comment.id ***
        await widget.onDeleteComment(widget.comment.id);
      },
    );
  }

  // Submit Reply: 调用 widget.onAddReply，传入 widget.comment.id 作为 parentId
  Future<void> _submitReply(String replyContent) async {
    if (replyContent.isEmpty || !mounted) return;
    setState(() => _isSubmittingReply = true);
    try {
      // *** 调用 widget.onAddReply，传入自己的 comment.id 作为 parentId ***
      await widget.onAddReply(replyContent, widget.comment.id);
      if (mounted) {
        setState(() {
          _showReplyInput = false;
        });
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '回复失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // Header
            padding: const EdgeInsets.only(top: 12, left: 16, right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: UserInfoBadge(
                  userId: widget.comment.userId,
                  showFollowButton: false,
                )),
                if (authProvider.isLoggedIn &&
                    (widget.comment.userId == authProvider.currentUser?.id ||
                        authProvider.currentUser?.isAdmin == true))
                  _buildCommentActions(context, widget.comment), // 调用 actions
              ],
            ),
          ),
          Padding(
            // Content
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              widget.comment.content,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
          Padding(
            // Time
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
          Padding(
            // Reply Button
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

          // *** 修改: 调用 ReplyList 并传递 *需要 ID* 的回调 ***
          if (widget.comment.replies.isNotEmpty)
            ReplyList(
              key: ValueKey('reply_list_${widget.comment.id}'),
              replies: widget.comment.replies,
              // *** 直接把 CommentItem 收到的需要 ID 的回调传下去 ***
              onUpdateReply: widget.onUpdateComment,
              onDeleteReply: widget.onDeleteComment,
              // *** 不传递 loading 状态 Set 给 ReplyList ***
            ),

          // Reply Input 不变
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _showReplyInput,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ReplyInput(
                  onSubmitReply: _submitReply, // 传递本地提交函数
                  isSubmitting: _isSubmittingReply, // 传递本地 loading 状态
                  onCancel: () => setState(() {
                    _showReplyInput = false;
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
