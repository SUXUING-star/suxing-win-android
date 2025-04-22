// lib/widgets/components/screen/forum/post/reply/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 确保导入了 AppSnackBar 和 NavigationUtils
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';
import '../../../../../ui/inputs/text_input_field.dart';

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final String postId;
  final int floor;
  final ForumService _forumService = ForumService();
  final VoidCallback? onReplyChanged;

  ReplyItem({
    super.key,
    required this.postId,
    required this.reply,
    required this.floor,
    this.onReplyChanged,
  });

  // --- 提取出来的回复提交逻辑 ---
  /// 处理回复提交的核心逻辑
  ///
  /// [context] : 用于显示 SnackBar 和可能的导航操作 (通常是 BottomSheet 的 context)
  /// [text] : 用户输入的回复内容
  /// [parentReplyId] : 被回复的评论 ID
  Future<void> _performReplySubmission(BuildContext context, String text, String parentReplyId) async {
    if (text.trim().isEmpty) {
      // 使用 AppSnackBar 显示警告
      AppSnackBar.showWarning(context, "回复内容不能为空");
      // 抛出异常或返回 false，让调用者知道验证失败
      throw Exception("回复内容不能为空"); // 或者 return;
    }

    try {
      // 调用 API 添加回复
      await _forumService.addReply(postId, text, parentId: parentReplyId);

      // 操作成功
      if (context.mounted) {
        NavigationUtils.pop(context); // 关闭底部输入框
        AppSnackBar.showSuccess(context, '回复成功'); // 显示成功提示
      }
      onReplyChanged?.call(); // 通知父组件刷新

    } catch (e) {
      // 操作失败
      print("Error submitting reply: $e"); // 打印错误日志
      if (context.mounted) {
        // 使用 AppSnackBar 显示错误
        AppSnackBar.showError(context, '回复失败：${e.toString()}');
      }
      // 将异常重新抛出，以便调用者可以处理 UI 状态（例如停止加载指示器）
      rethrow;
    }
  }


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
                userId: reply.authorId,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            _buildReplyActions(context, reply), // 操作按钮构建逻辑不变
          ],
        ),
        const SizedBox(height: 12),
        Padding(
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
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();
                      return TextButton.icon(
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('回复', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // 构建操作按钮（编辑、删除） - 内部逻辑不变
  Widget _buildReplyActions(BuildContext context, Reply reply) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return const SizedBox.shrink();
        final theme = Theme.of(context); // 获取 theme

        final currentUserId = auth.currentUser?.id;
        final replyAuthorId = reply.authorId;
        final isAuthor = currentUserId == replyAuthorId;
        final isAdmin = auth.currentUser?.isAdmin ?? false;

        if (!isAuthor && !isAdmin) return const SizedBox.shrink();

        return StylishPopupMenuButton<String>( // *** 使用新组件 ***
          icon: Icons.more_vert,
          iconSize: 18,
          iconColor: Colors.grey[600],
          triggerPadding: const EdgeInsets.all(0), // 使用 triggerPadding
          tooltip: '回复操作',
          menuColor: theme.canvasColor,
          elevation: 3, // 这个例子里是 3
          itemHeight: 40,

          // *** 直接提供数据列表 ***
          items: [
            // 编辑选项
            if (isAuthor)
              StylishMenuItemData( // **提供数据**
                value: 'edit',
                // **提供内容 (Row)**
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10), const Text('编辑')
                ]),
              ),

            // 分割线
            if (isAuthor && isAdmin)
              const StylishMenuDividerData(), // **标记分割线**

            // 删除选项
            if (isAuthor || isAdmin)
              StylishMenuItemData( // **提供数据**
                value: 'delete',
                // **提供内容 (Row)**
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 10), Text('删除', style: TextStyle(color: theme.colorScheme.error))
                ]),
              ),
          ],

          // onSelected 逻辑不变
          onSelected: (value) {
            switch (value) {
              case 'edit': _handleEditReply(context, reply); break;
              case 'delete': _handleDeleteReply(context, reply); break;
            }
          },
        );
      },
    );
  }


  // 处理编辑回复 - 使用 AppSnackBar
  Future<void> _handleEditReply(BuildContext context, Reply reply) async {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '输入新的回复内容',
      maxLines: 4,
      onSave: (newContent) async {
        try {
          // 使用类成员 postId
          await _forumService.updateReply(postId, reply.id, newContent);
          onReplyChanged?.call();
          if (context.mounted) {
            // *** 使用 AppSnackBar ***
            AppSnackBar.showSuccess(context, '回复编辑成功');
          }
        } catch (e) {
          if (context.mounted) {
            // *** 使用 AppSnackBar ***
            AppSnackBar.showError(context, '编辑失败：${e.toString()}');
          }
        }
      },
    );
  }

  // 处理删除回复 - 使用 AppSnackBar
  Future<void> _handleDeleteReply(BuildContext context, Reply reply) async {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这个回复吗？删除后不可恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          // 使用类成员 postId
          await _forumService.deleteReply(postId, reply.id);
          onReplyChanged?.call();
          if (context.mounted) {
            // *** 使用 AppSnackBar ***
            AppSnackBar.showSuccess(context, '回复删除成功');
          }
        } catch (e) {
          if (context.mounted) {
            // *** 使用 AppSnackBar ***
            AppSnackBar.showError(context, '删除失败：${e.toString()}');
          }
        }
      },
    );
  }

  // 显示回复输入框 - 调用提取出的提交逻辑
  void _showReplyBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isSubmitting = false; // 状态变量在 BottomSheet 内部管理

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许 BottomSheet 随键盘调整大小
      backgroundColor: Colors.white, // 明确背景色
      shape: const RoundedRectangleBorder( // 添加圆角
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) { // 使用独立的 context 名称
        return StatefulBuilder( // 使用 StatefulBuilder 管理局部状态 (isSubmitting)
          builder: (builderContext, setStateInBottomSheet) {
            return Padding(
              // 适配键盘遮挡
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
                left: 16, // 左右内边距
                right: 16,
                top: 16, // 顶部内边距
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 高度自适应内容
                crossAxisAlignment: CrossAxisAlignment.start, // 左对齐标题
                children: [
                  // 标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), // 标题和输入框间距
                    child: Text(
                      '回复 $floor楼', // 使用 floor 变量
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // 输入框和提交按钮 (使用 TextInputField)
                  TextInputField(
                    controller: textController,
                    hintText: '写下你的回复...', // 提示文字
                    submitButtonText: '回复', // 按钮文字
                    isSubmitting: isSubmitting, // 传递提交状态
                    maxLines: 3, // 限制最大行数
                    // *** 调用提取出的方法处理提交 ***
                    onSubmitted: (text) async {
                      // 1. 设置提交中状态
                      setStateInBottomSheet(() {
                        isSubmitting = true;
                      });
                      try {
                        // 2. 执行核心提交逻辑
                        // 传入 builderContext 用于 SnackBar 和导航
                        // 传入 reply.id 作为被回复的评论 ID
                        await _performReplySubmission(builderContext, text, reply.id);
                        // 3. 如果成功，BottomSheet 会被 pop，此状态不再重要
                      } catch (e) {
                        // 4. 如果失败 (异常被抛出)，恢复提交按钮状态
                        // 检查 context 是否仍然有效
                        if (builderContext.mounted) {
                          setStateInBottomSheet(() {
                            isSubmitting = false;
                          });
                        }
                        // 错误提示已经在 _performReplySubmission 中显示
                      }
                      // 注意：这里不需要 finally 来设置 isSubmitting = false
                      // 因为成功时 sheet 关闭，失败时在 catch 中处理
                    },
                  ),
                  const SizedBox(height: 8), // 底部增加一点空间
                ],
              ),
            );
          },
        );
      },
    );
  }

}