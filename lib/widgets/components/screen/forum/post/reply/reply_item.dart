// lib/widgets/components/screen/forum/post/reply/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart'; // 确认路径
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final String postId;
  final int floor;
  final VoidCallback onActionSuccess; // <<< --- 接收回调函数 ---
  final ForumService _forumService = ForumService();

  ReplyItem({
    super.key,
    required this.postId,
    required this.reply,
    required this.floor,
    required this.onActionSuccess, // <<< --- 在构造函数中接收 ---
  });

  /// 处理回复提交的核心逻辑
  Future<void> _performReplySubmission(
      BuildContext context, String text, String parentReplyId) async {
    if (text.trim().isEmpty) {
      AppSnackBar.showWarning(context, "回复内容不能为空");
      throw Exception("回复内容不能为空");
    }

    try {
      await _forumService.addReply(postId, text, parentId: parentReplyId);
      if (context.mounted) {
        NavigationUtils.pop(context); // 关闭底部输入框
        AppSnackBar.showSuccess(context, '回复成功');
      }
      onActionSuccess(); // <<<--- 调用回调 ---
    } catch (e) {
      print("Error submitting reply: $e");
      if (context.mounted) {
        AppSnackBar.showError(context, '回复失败：${e.toString()}');
      }
      rethrow;
    }
  }

  // 处理编辑回复
  Future<void> _handleEditReply(BuildContext context, Reply reply) async {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '输入新的回复内容',
      maxLines: 4,
      onSave: (newContent) async {
        try {
          await _forumService.updateReply(postId, reply.id, newContent);
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '回复编辑成功');
          }
          onActionSuccess(); // <<<--- 调用回调 ---
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, '编辑失败：${e.toString()}');
          }
        }
      },
    );
  }

  // 处理删除回复
  Future<void> _handleDeleteReply(BuildContext context, Reply reply) async {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这个回复吗？删除后不可恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          await _forumService.deleteReply(postId, reply.id);
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '回复删除成功');
          }
          onActionSuccess(); // <<<--- 调用回调 ---
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, '删除失败：${e.toString()}');
          }
        }
      },
    );
  }

  // 显示回复输入框 (BottomSheet) - 内部调用 _performReplySubmission
  void _showReplyBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // 明确背景色
      shape: const RoundedRectangleBorder( // 添加圆角
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateInBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '回复 $floor楼', // 使用 floor 变量
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  CommentInputField( // <<<--- 评论输入框 ---
                    controller: textController,
                    hintText: '写下你的回复...',
                    submitButtonText: '回复',
                    isSubmitting: isSubmitting,
                    maxLines: 3,
                    maxLength: 200, // 适当调整
                    onSubmit: (text) async {
                      setStateInBottomSheet(() { isSubmitting = true; });
                      try {
                        await _performReplySubmission(builderContext, text, reply.id);
                        // 成功时会自动调用 onActionSuccess 并关闭
                      } catch (e) {
                        if (builderContext.mounted) { // 失败时恢复按钮状态
                          setStateInBottomSheet(() { isSubmitting = false; });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isTopLevel = floor > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row( // <<<--- 顶部行：头像、楼层、操作按钮 ---
          children: [
            Expanded( // <<<--- 用户信息 Badge ---
              child: UserInfoBadge(
                userId: reply.authorId,
                showFollowButton: false,
                mini: true,
              ),
            ),
            if (isTopLevel) // <<<--- 楼层号 ---
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
            _buildReplyActions(context, reply), // <<<--- 操作按钮（编辑、删除） ---
          ],
        ),
        const SizedBox(height: 12),
        Padding( // <<<--- 内容和底部操作行 ---
          padding: const EdgeInsets.only(left: 36), // 内容缩进
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 回复内容
              Text(
                reply.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              // 底部操作行（回复按钮 + 时间）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 回复此楼层的按钮 (仅登录用户可见)
                  Consumer<AuthProvider>( // <<<--- 回复按钮 ---
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();
                      return TextButton.icon(
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('回复', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _showReplyBottomSheet(context), // 点击弹出回复框
                      );
                    },
                  ),
                  // 回复时间
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

  // 构建操作按钮（编辑、删除） - 调用修改过的处理函数
  Widget _buildReplyActions(BuildContext context, Reply reply) {
    return Consumer<AuthProvider>( // <<<--- 权限判断 ---
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) return const SizedBox.shrink();
          final theme = Theme.of(context); // 获取 theme

          final currentUserId = auth.currentUser?.id;
          final replyAuthorId = reply.authorId;
          final isAuthor = currentUserId == replyAuthorId;
          final isAdmin = auth.currentUser?.isAdmin ?? false;

          // 只有作者或管理员才能看到操作按钮
          if (!isAuthor && !isAdmin) return const SizedBox.shrink();

          return StylishPopupMenuButton<String>( // <<<--- 弹出菜单按钮 ---
            icon: Icons.more_vert,
            iconSize: 18,
            iconColor: Colors.grey[600],
            triggerPadding: const EdgeInsets.all(0), // 使用 triggerPadding
            tooltip: '回复操作',
            menuColor: theme.canvasColor, // 使用主题颜色
            elevation: 3,
            itemHeight: 40,
            items: [
              // 编辑选项 (只有作者可见)
              if (isAuthor)
                StylishMenuItemData(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    const Text('编辑')
                  ]),
                ),
              // 分割线 (作者和管理员都有操作时显示)
              if (isAuthor && isAdmin)
                const StylishMenuDividerData(),
              // 删除选项 (作者或管理员可见)
              if (isAuthor || isAdmin)
                StylishMenuItemData(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Text('删除', style: TextStyle(color: theme.colorScheme.error))
                  ]),
                ),
            ],
            onSelected: (value) { // <<<--- 处理选择 ---
              switch (value) {
                case 'edit':
                  _handleEditReply(context, reply); // 调用包含回调的方法
                  break;
                case 'delete':
                  _handleDeleteReply(context, reply); // 调用包含回调的方法
                  break;
              }
            },
          );
        }
    );
  }
}