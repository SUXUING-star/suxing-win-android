// lib/widgets/components/screen/game/comment/replies/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';
import '../../../../../ui/buttons/popup/custom_popup_menu_button.dart';

// *** 可以是 StatefulWidget 以管理本地 loading ***
class ReplyItem extends StatefulWidget {
  final Comment reply;
  // *** 接收来自 ReplyList 的 *不需要* ID 的回调 ***
  final Future<void> Function(String newContent) onUpdate;
  final Future<void> Function() onDelete;

  const ReplyItem({
    Key? key,
    required this.reply,
    required this.onUpdate, // 接收不需要 ID 的 onUpdate
    required this.onDelete, // 接收不需要 ID 的 onDelete
  }) : super(key: key);

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
  // *** 添加本地 loading 状态 ***
  bool _isDeleting = false;
  bool _isUpdating = false; // 如果编辑操作有耗时反馈的话

  // Action Buttons: 使用本地 loading 状态
  Widget _buildReplyActions(BuildContext context, Comment reply) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context); // 获取 theme
    final bool canEdit = reply.userId == authProvider.currentUser?.id;
    final bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;

    if (!canEdit && !canDelete) return const SizedBox.shrink();

    return StylishPopupMenuButton<String>( // *** 使用新组件 ***
      icon: Icons.more_vert,
      iconSize: 18,
      iconColor: Colors.grey[600],
      triggerPadding: const EdgeInsets.all(0), // 使用 triggerPadding
      tooltip: '回复选项',
      menuColor: theme.canvasColor,
      elevation: 2.0,
      itemHeight: 40,
      // *** 按钮整体是否可用，取决于本地 loading 状态 ***
      isEnabled: !_isDeleting && !_isUpdating,

      // *** 直接提供数据列表 ***
      items: [
        // 编辑选项
        if (canEdit)
          StylishMenuItemData( // **提供数据**
            value: 'edit',
            // **提供内容 (Row)**
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8), const Text('编辑'),
            ],),
          ),

        // 分割线
        if (canEdit && canDelete)
          const StylishMenuDividerData(), // **标记分割线**

        // 删除选项
        if (canDelete)
          StylishMenuItemData( // **提供数据**
            value: 'delete',
            // **提供内容 (根据 _isDeleting 显示不同 Row)**
            child: _isDeleting
                ? Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.disabledColor)),
              const SizedBox(width: 8), Text('删除中...', style: TextStyle(color: theme.disabledColor)),
            ],)
                : Row(children: [
              Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 8), Text('删除', style: TextStyle(color: theme.colorScheme.error)),
            ],),
            // **单独控制删除项的启用状态**
            enabled: !_isDeleting, // 删除过程中禁用此项
          ),
      ],

      // onSelected 逻辑不变
      onSelected: (value) {
        switch (value) {
          case 'edit': _showEditDialog(context, reply); break;
          case 'delete': if (!_isDeleting) _showDeleteDialog(context, reply); break;
        }
      },
    );
  }

  // Dialogs: 调用 widget 的回调，并管理本地 loading
  void _showEditDialog(BuildContext context, Comment reply) {
    EditDialog.show( context: context, title: '编辑回复', initialText: reply.content, hintText: '编辑回复内容...',
      //isSaving: _isUpdating, // 传递本地 loading
      onSave: (text) async {
        if (!mounted) return;
        setState(() => _isUpdating = true); // 开始本地 loading
        try {
          await widget.onUpdate(text); // 调用父级传来的回调 (不需要 ID)
        } catch (e) { if (mounted) AppSnackBar.showError(context, '编辑失败: $e'); } // Fallback
        finally { if (mounted) setState(() => _isUpdating = false); } // 结束本地 loading
      },
    );
  }
  void _showDeleteDialog(BuildContext context, Comment reply) {
    CustomConfirmDialog.show( context: context, title: '删除回复', message: '确定要删除这条回复吗？', confirmButtonText: '删除', confirmButtonColor: Colors.red,
      //isConfirming: _isDeleting, // 传递本地 loading
      onConfirm: () async {
        if (!mounted) return;
        setState(() => _isDeleting = true); // 开始本地 loading
        try {
          await widget.onDelete(); // 调用父级传来的回调 (不需要 ID)
        } catch (e) { if (mounted) AppSnackBar.showError(context, '删除失败: $e'); } // Fallback
        // finally { // 不需要 finally，因为成功后 Widget 会被移除
        //   if (mounted) setState(() => _isDeleting = false);
        // }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration( border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)) ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: UserInfoBadge(userId: widget.reply.userId, showFollowButton: false, mini: true)),
              const SizedBox(width: 8),
              Text(DateTimeFormatter.formatRelative(widget.reply.createTime) + (widget.reply.isEdited ? ' (已编辑)' : ''), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              _buildReplyActions(context, widget.reply), // 调用 actions
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(widget.reply.content, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}