import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // Keep for dialogs
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';
import '../../../../../ui/buttons/custom_popup_menu_button.dart';

class ReplyItem extends StatelessWidget { // Can be StatelessWidget if no internal state needed besides dialogs
  final Comment reply;
  // --- Callbacks received from Parent (ReplyList) ---
  final Future<void> Function(String newContent) onUpdate;
  final Future<void> Function() onDelete;

  const ReplyItem({
    Key? key,
    required this.reply,
    required this.onUpdate,
    required this.onDelete,
    // REMOVED: gameId
    // REMOVED: onReplyChanged
  }) : super(key: key);

  // REMOVED: final GameService _gameService = GameService();

  // --- Action Buttons (No change needed in structure, only in onSelected) ---
  Widget _buildReplyActions(BuildContext context, Comment reply) {
    return CustomPopupMenuButton<String>(
      // ... (外观代码不变)
      icon: Icons.more_vert,
      iconSize: 18,
      iconColor: Colors.grey[600],
      padding: const EdgeInsets.all(0),
      tooltip: '回复选项',
      elevation: 4,
      splashRadius: 16,

      onSelected: (value) async { // Make async
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
        // ... (itemBuilder logic不变)
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final List<PopupMenuEntry<String>> items = [];
        if (!authProvider.isLoggedIn) return items;
        bool canEdit = reply.userId == authProvider.currentUser?.id;
        bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;
        // ... (add items based on canEdit/canDelete)
        if (canEdit) { items.add(PopupMenuItem<String>(value: 'edit', height: 40, child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]), const SizedBox(width: 10), const Text('编辑'),],),),); }
        if (canEdit && canDelete) { items.add(const PopupMenuDivider(height: 1)); }
        if (canDelete) { items.add(PopupMenuItem<String>(value: 'delete', height: 40, child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red[700]), const SizedBox(width: 10), Text('删除', style: TextStyle(color: Colors.red[700])),],),),); }
        return items;
      },
    );
  }

  // --- Dialogs (Call Parent's Callbacks) ---
  void _showEditDialog(BuildContext context, Comment reply) {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '编辑回复内容...',
      onSave: (text) async {
        // --- Call parent's update callback ---
        try {
          await onUpdate(text); // Use the passed callback directly
          // Success is handled higher up
        } catch (e) {
          // Error is handled higher up
          if (context.mounted) AppSnackBar.showError(context, '编辑失败: $e'); // Fallback
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Comment reply) {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这条回复吗？',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        // --- Call parent's delete callback ---
        try {
          await onDelete(); // Use the passed callback directly
          // Success is handled higher up
        } catch (e) {
          // Error is handled higher up
          if (context.mounted) AppSnackBar.showError(context, '删除失败: $e'); // Fallback
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Build method structure remains largely the same ---
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 8),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: UserInfoBadge(userId: reply.userId, showFollowButton: false, mini: true,),),
                const SizedBox(width: 8),
                Text(DateTimeFormatter.formatRelative(reply.createTime) + (reply.isEdited ? ' (已编辑)' : ''), style: TextStyle(fontSize: 11, color: Colors.grey[600],),),
                // --- Build actions using the instance method ---
                _buildReplyActions(context, reply),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
            child: Text(reply.content),
          ),
        ],
      ),
    );
  }
}