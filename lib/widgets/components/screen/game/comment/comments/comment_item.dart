// lib/widgets/components/screen/game/comment/comment_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../replies/reply_list.dart';
import '../replies/reply_input.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart'; // 导入编辑对话框
import '../../../../../ui/dialogs/confirm_dialog.dart'; // 导入确认对话框
import '../../../../../ui/buttons/custom_popup_menu_button.dart'; // 确保路径正确

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
  final GameService _commentService = GameService();
  // bool _isDeleting = false; // 4. 移除状态变量
  bool _showReplyInput = false; // 控制回复输入框显示

  // 2. 修改 _buildCommentActions 方法
  Widget _buildCommentActions(
      BuildContext context, String gameId, Comment comment) {
    // return PopupMenuButton<String>(...); // 旧代码

    // 使用 CustomPopupMenuButton
    return CustomPopupMenuButton<String>(
      // --- 自定义外观 ---
      icon: Icons.more_vert,
      iconSize: 20,
      iconColor: Colors.grey[600],
      padding: const EdgeInsets.all(0), // 紧凑一点
      tooltip: '评论选项',
      elevation: 4,
      splashRadius: 18,

      // --- 核心逻辑 ---
      onSelected: (value) async {
        // onSelected 逻辑保持不变
        switch (value) {
          case 'edit':
            _showEditDialog(context, gameId, comment);
            break;
          case 'delete':
            _showDeleteDialog(context, gameId, comment);
            break;
        }
      },
      // 3. 美化 itemBuilder 中的 PopupMenuItem
      itemBuilder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final List<PopupMenuEntry<String>> items = [];

        if (!authProvider.isLoggedIn) return items;

        bool canEdit = comment.userId == authProvider.currentUser?.id;
        bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;

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

  // _showEditDialog 方法保持不变
  void _showEditDialog(BuildContext context, String gameId, Comment comment) {
    EditDialog.show(
      context: context,
      title: '编辑评论',
      initialText: comment.content,
      hintText: '编辑评论内容...',
      onSave: (text) async {
        try {
          await _commentService.updateComment(gameId, comment.id, text);
          widget.onCommentChanged?.call();
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '评论已更新');

          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, '编辑评论失败：$e');
          }
        }
      },
    );
  }

  // _showDeleteDialog 方法保持不变 (移除 setState)
  void _showDeleteDialog(BuildContext context, String gameId, Comment comment) {
    CustomConfirmDialog.show(
      context: context,
      title: '删除评论',
      message: '确定要删除这条评论吗？\n(评论下的所有回复也会被删除)', // 提示更清晰
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          // 不再需要管理 _isDeleting 状态
          // setState(() { _isDeleting = true; });

          await _commentService.deleteComment(gameId, comment.id);
          widget.onCommentChanged?.call();

          if (context.mounted) {
            AppSnackBar.showSuccess(context,'评论已删除');
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context,'删除评论失败：$e');
          }
          rethrow; // 重新抛出以便外部捕获（如果需要）
        }
        // finally 块也可以移除
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5, // 轻微调整阴影
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)), // 卡片圆角
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 评论头部 ---
          Padding(
            padding:
                const EdgeInsets.only(top: 12, left: 16, right: 8), // 调整右边距
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 尝试垂直居中
              children: [
                Expanded(
                  child: UserInfoBadge(
                    userId: widget.comment.userId,
                    showFollowButton: false, // 通常评论区不显示关注
                  ),
                ),
                // 条件渲染操作按钮
                if (authProvider.isLoggedIn &&
                    (widget.comment.userId == authProvider.currentUser?.id ||
                        authProvider.currentUser?.isAdmin == true))
                  _buildCommentActions(
                      context, widget.gameId, widget.comment), // 使用修改后的方法
              ],
            ),
          ),
          // --- 评论内容和时间 ---
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 8.0), // 调整内边距
            child: Text(
              widget.comment.content,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.4), // 使用主题样式并调整行高
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateTimeFormatter.formatRelative(
                        widget.comment.createTime) + // 使用相对时间
                    (widget.comment.isEdited ? ' (已编辑)' : ''),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),

          // --- 回复区域和操作 ---
          const Divider(height: 1, thickness: 0.5), // 分隔线
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // 操作按钮靠右
              children: [
                // 可以添加点赞、不喜欢等按钮在这里
                // TextButton.icon(onPressed: (){}, icon: Icon(Icons.thumb_up_alt_outlined, size: 16), label: Text('赞')),
                TextButton(
                  onPressed: () {
                    // 需要检查是否登录才能回复
                    if (!authProvider.isLoggedIn) {
                      // 可以跳转登录或提示
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先登录后才能回复')));
                      return;
                    }
                    setState(() {
                      _showReplyInput = !_showReplyInput;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor, // 使用主题色
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    // 使用 Row 添加图标
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

          // --- 回复列表 ---
          // 如果有回复，显示回复列表
          if (widget.comment.replies.isNotEmpty)
            ReplyList(
              replies: widget.comment.replies,
              gameId: widget.gameId,
              onReplyChanged: widget.onCommentChanged,
            ),

          // --- 回复输入框 ---
          // 根据状态显示或隐藏回复输入框
          AnimatedSize(
            // 添加动画效果
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _showReplyInput,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 给输入框一些边距
                child: ReplyInput(
                  gameId: widget.gameId,
                  parentId: widget.comment.id,
                  onReplyAdded: () {
                    // 回复成功后可以自动收起输入框
                    setState(() {
                      _showReplyInput = false;
                    });
                    // 并触发外部的回调刷新
                    widget.onCommentChanged?.call();
                  },
                  onCancel: () {
                    // 添加取消回调
                    setState(() {
                      _showReplyInput = false;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
