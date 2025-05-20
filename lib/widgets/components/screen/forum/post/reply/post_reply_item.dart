// lib/widgets/components/screen/forum/post/reply/post_reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart'; // 使用已修改的 CommentInputField
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class PostReplyItem extends StatelessWidget {
  final User? currentUser;
  final Reply reply;
  final UserDataStatus userDataStatus;
  final String postId;
  final int floor;
  final VoidCallback onActionSuccess;
  final ForumService forumService;

  const PostReplyItem({
    super.key,
    required this.currentUser,
    required this.userDataStatus,
    required this.forumService,
    required this.postId,
    required this.reply,
    required this.floor,
    required this.onActionSuccess,
  });

  // --- 提交、编辑、删除逻辑不变 ---
  Future<void> _performReplySubmission(
    BuildContext context,
    String text,
    String parentReplyId,
    String slotName,
  ) async {
    if (text.trim().isEmpty) {
      AppSnackBar.showWarning(context, "回复内容不能为空");
      throw Exception("回复内容不能为空");
    }

    try {
      await forumService.addReply(postId, text, parentId: parentReplyId);

      if (context.mounted) {
        // 保持用途明确
        InputStateService? inputStateService =
            Provider.of<InputStateService>(context, listen: false);
        inputStateService.clearText(slotName);
        inputStateService = null;
      }

      if (context.mounted) {
        NavigationUtils.pop(context); // 关闭底部输入框
        AppSnackBar.showSuccess(context, '回复成功');
      }
      onActionSuccess();
    } catch (e) {
      // 错误处理已在下方完成，这里只需 rethrow
      rethrow;
    }
  }

  Future<void> _handleEditReply(
    BuildContext context,
    Reply reply,
    ForumService forumService,
  ) async {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '输入新的回复内容',
      maxLines: 4,
      onSave: (newContent) async {
        try {
          await forumService.updateReply(postId, reply, newContent);
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '回复编辑成功');
          }
          onActionSuccess();
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, '编辑失败：${e.toString()}');
          }
        }
      },
    );
  }


  Future<void> _handleDeleteReply(
    BuildContext context,
    Reply reply,
    ForumService forumService,
  ) async {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这个回复吗？删除后不可恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          await forumService.deleteReply(postId, reply);
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '回复删除成功');
          }
          onActionSuccess();
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, '删除失败：${e.toString()}');
          }
        }
      },
    );
  }

  // --- 修改: 显示回复输入框，并传递 slotName ---
  void _showReplyBottomSheet(
    BuildContext context,
    ForumService forumService,
  ) {
    // +++ 生成唯一的 slotName +++
    final slotName = 'post_reply_${postId}_${reply.id}';
    bool isSubmitting = false; // 状态用于控制 CommentInputField 的 loading

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // 需要 StatefulBuilder 来管理 isSubmitting 状态
        return StatefulBuilder(
          builder: (builderContext, setStateInBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      floor > 0
                          ? '回复 $floor楼'
                          : '回复 @${reply.authorId}', // 简化显示
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  CommentInputField(
                    slotName: slotName,
                    hintText: '写下你的回复...',
                    submitButtonText: '回复',
                    isSubmitting: isSubmitting, // 传递 loading 状态
                    maxLines: 3,
                    maxLength: 200,
                    onSubmit: (text) async {
                      setStateInBottomSheet(() {
                        isSubmitting = true;
                      });
                      try {
                        await _performReplySubmission(
                          builderContext,
                          text,
                          reply.id,
                          slotName,
                        );
                        // 成功时会自动清除状态、关闭并调用 onActionSuccess
                      } catch (e) {
                        // 错误已在 _performReplySubmission 的 rethrow 前处理（显示 Snackbar）
                        // 只需恢复按钮状态
                        if (builderContext.mounted) {
                          setStateInBottomSheet(() {
                            isSubmitting = false;
                          });
                        }
                      }
                      // finally 块不再需要，因为 isSubmitting 在成功或失败时都会被设置
                    },
                  ),
                  const SizedBox(height: 8), // 底部间距
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- build 方法和 _buildReplyActions 不变 ---
  @override
  Widget build(BuildContext context) {
    final bool isTopLevel = floor > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: UserInfoBadge(
                currentUser: currentUser,
                userDataStatus: userDataStatus,
                targetUserId: reply.authorId,
                showFollowButton: false,
                mini: true,
              ),
            ),
            if (isTopLevel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$floor楼',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            const SizedBox(width: 8),
            _buildReplyActions(context, reply, forumService),
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
                    fontSize: 15, height: 1.6, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();
                      return TextButton.icon(
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('回复', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showReplyBottomSheet(
                            context, forumService),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        DateTimeFormatter.formatStandard(reply.createTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (reply.hasBeenEdited)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Text(
                            '(已编辑)',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyActions(
    BuildContext context,
    Reply reply,
    ForumService forumService,
  ) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (!auth.isLoggedIn) return const SizedBox.shrink();
      final theme = Theme.of(context);
      final currentUserId = auth.currentUser?.id;
      final replyAuthorId = reply.authorId;
      final isAuthor = currentUserId == replyAuthorId;
      final isAdmin = auth.currentUser?.isAdmin ?? false;

      if (!isAuthor && !isAdmin) return const SizedBox.shrink();

      return StylishPopupMenuButton<String>(
        icon: Icons.more_vert,
        iconSize: 18,
        iconColor: Colors.grey[600],
        triggerPadding: const EdgeInsets.all(0),
        tooltip: '回复操作',
        menuColor: theme.canvasColor,
        elevation: 3,
        itemHeight: 40,
        items: [
          if (isAuthor)
            StylishMenuItemData(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined,
                    size: 18, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 10),
                const Text('编辑')
              ]),
            ),
          if (isAuthor && isAdmin) const StylishMenuDividerData(),
          if (isAuthor || isAdmin)
            StylishMenuItemData(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline,
                    size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Text('删除', style: TextStyle(color: theme.colorScheme.error))
              ]),
            ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _handleEditReply(
                context,
                reply,
                forumService,
              );
              break;
            case 'delete':
              _handleDeleteReply(
                context,
                reply,
                forumService,
              );
              break;
          }
        },
      );
    });
  }
}
