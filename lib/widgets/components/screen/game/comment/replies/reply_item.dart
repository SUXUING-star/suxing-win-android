// lib/widgets/components/screen/game/comment/replies/reply_item_updated.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart'; // 导入编辑对话框
import '../../../../../ui/dialogs/confirm_dialog.dart'; // 导入确认对话框
import '../../../../../ui/buttons/custom_popup_menu_button.dart'; // 确保路径正确

class ReplyItem extends StatefulWidget {
  final Comment reply;
  final String gameId;
  final VoidCallback? onReplyChanged;

  const ReplyItem({
    Key? key,
    required this.gameId,
    required this.reply,
    this.onReplyChanged,
  }) : super(key: key);

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
  final GameService _gameService = GameService();
  // _isDeleting 状态现在由 ConfirmDialog 内部处理加载状态，可以考虑移除
  // bool _isDeleting = false; // 可以移除

  // 2. 修改 _buildReplyActions 方法
  Widget _buildReplyActions(
      BuildContext context, String gameId, Comment reply) {
    // return PopupMenuButton<String>(...); // 旧代码

    // 使用 CustomPopupMenuButton
    return CustomPopupMenuButton<String>(
      // --- 自定义外观 ---
      icon: Icons.more_vert, // 使用垂直的点点点
      iconSize: 18, // 尺寸可以小一些
      iconColor: Colors.grey[600], // 图标颜色
      padding: const EdgeInsets.all(0), // 减少内边距，更紧凑
      tooltip: '回复选项',
      elevation: 4,
      splashRadius: 16,

      // --- 核心逻辑 ---
      onSelected: (value) async {
        // onSelected 逻辑保持不变
        switch (value) {
          case 'edit':
            _showEditDialog(context, gameId, reply);
            break;
          case 'delete':
            _showDeleteDialog(context, gameId, reply);
            break;
        }
      },
      // 3. 增强 itemBuilder 中的 PopupMenuItem
      itemBuilder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final List<PopupMenuEntry<String>> items = [];

        if (!authProvider.isLoggedIn) return items; // 未登录则返回空列表

        bool canEdit = reply.userId == authProvider.currentUser?.id;
        bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;

        // 编辑选项
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

        // 如果既能编辑又能删除，添加分隔线
        if (canEdit && canDelete) {
          items.add(const PopupMenuDivider(height: 1));
        }

        // 删除选项
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

  // _showEditDialog 方法保持不变
  void _showEditDialog(BuildContext context, String gameId, Comment reply) {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '编辑回复内容...',
      onSave: (text) async {
        try {
          await _gameService.updateComment(gameId, reply.id, text);
          widget.onReplyChanged?.call(); // 使用 ?.call()
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
    );
  }

  // _showDeleteDialog 方法保持不变 (内部的 setState 可以移除)
  void _showDeleteDialog(BuildContext context, String gameId, Comment reply) {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这条回复吗？',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        // try-catch 块用来捕获 _commentService.deleteComment 的错误
        try {
          // 不再需要 setState 来管理 _isDeleting
          // setState(() { _isDeleting = true; });

          await _gameService.deleteComment(gameId, reply.id);
          widget.onReplyChanged?.call(); // 使用 ?.call()

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('回复已删除')),
            );
          }
        } catch (e) {
          // 错误处理由 ConfirmDialog.show 外层的 try-catch 处理（如果需要统一处理）
          // 或者在这里单独处理删除失败的 SnackBar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除回复失败：$e')),
            );
          }
          // 重新抛出异常，如果需要在 ConfirmDialog.show 的调用处捕获
          rethrow;
        }
        // finally 块也可以移除，因为 ConfirmDialog 关闭后状态不再重要
      },
      // onCancel: () { print('取消删除'); } // 如果需要处理取消事件
    );
  }

  @override
  Widget build(BuildContext context) {
    // build 方法的主体保持不变
    return Container(
      // ... Container 样式 ...
      margin: const EdgeInsets.only(left: 32, bottom: 8), // 加一点底部间距
      padding: const EdgeInsets.only(bottom: 8), // 给内容下方加点内边距
      decoration: BoxDecoration(
          border: Border(
        bottom: BorderSide(color: Colors.grey.shade200, width: 0.8), // 添加底部分隔线
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 16, right: 8), // 调整右边距适应按钮
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 尝试垂直居中对齐
              children: [
                Expanded(
                  child: UserInfoBadge(
                    userId: widget.reply.userId,
                    showFollowButton: false,
                    mini: true,
                    // backgroundColor: Colors.grey[50], // 背景色可能不需要
                  ),
                ),
                const SizedBox(width: 8), // 用户名和日期之间加点间距
                Text(
                  DateTimeFormatter.formatRelative(
                          widget.reply.createTime) + // 使用相对时间
                      (widget.reply.isEdited ? ' (已编辑)' : ''),
                  style: TextStyle(
                    fontSize: 11, // 字体再小一点
                    color: Colors.grey[600],
                  ),
                ),
                // 将修改后的按钮放在这里
                _buildReplyActions(context, widget.gameId, widget.reply),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 4.0, bottom: 4.0), // 调整内容区域边距
            child: Text(widget.reply.content),
          ),
        ],
      ),
    );
  }
}
