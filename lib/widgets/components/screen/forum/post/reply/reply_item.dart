// lib/widgets/components/screen/forum/post/reply/reply_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../ui/badges/user_info_badge.dart'; // 用户信息徽章组件
import '../../../../../ui/dialogs/edit_dialog.dart'; // 编辑对话框组件
import '../../../../../ui/dialogs/confirm_dialog.dart'; // 确认对话框组件
import '../../../../../ui/inputs/text_input_field.dart'; // 文本输入组件
import '../../../../../ui/buttons/custom_popup_menu_button.dart'; // 确保路径正确

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final int floor;
  final ForumService _forumService = ForumService();
  final VoidCallback? onReplyChanged;

  ReplyItem({
    Key? key,
    required this.reply,
    required this.floor,
    this.onReplyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isTopLevel = floor > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 使用UserInfoBadge替换原有的用户信息显示
            Expanded(
              child: UserInfoBadge(
                userId: reply.authorId,
                showFollowButton: false, // 不显示关注按钮
                mini: true, // 使用迷你版本
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
            _buildReplyActions(context, reply),
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
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add reply button to reply to this specific reply
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
                        onPressed: () {
                          _showReplyBottomSheet(context);
                        },
                      );
                    },
                  ),
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

  Widget _buildReplyActions(BuildContext context, Reply reply) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 如果用户未登录，不显示按钮
        if (!auth.isLoggedIn) {
          return const SizedBox.shrink();
        }

        // 将 ObjectId 转换为字符串进行比较
        final currentUserId = auth.currentUser?.id;
        final replyAuthorId = reply.authorId.replaceAll('ObjectId("', '').replaceAll('")', '');

        // 如果是本人的评论或者是管理员，显示按钮
        final isAuthor = currentUserId == replyAuthorId;
        final isAdmin = auth.currentUser?.isAdmin ?? false;

        if (!isAuthor && !isAdmin) {
          return const SizedBox.shrink();
        }

        // 使用 CustomPopupMenuButton
        return CustomPopupMenuButton<String>(
          // --- 自定义外观 ---
          icon: Icons.more_vert, // 保持垂直点点点
          iconSize: 18,
          iconColor: Colors.grey[600],
          padding: const EdgeInsets.all(0), // 紧凑
          tooltip: '回复操作',
          elevation: 3,
          splashRadius: 16,

          // --- 核心逻辑 ---
          onSelected: (value) {
            // onSelected 逻辑不变
            switch (value) {
              case 'edit':
                _handleEditReply(context, reply);
                break;
              case 'delete':
                _handleDeleteReply(context, reply);
                break;
            }
          },
          // 4. 美化 itemBuilder 中的 PopupMenuItem
          itemBuilder: (context) {
            final List<PopupMenuEntry<String>> items = [];

            // 只有作者才能编辑
            if (isAuthor) {
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

            // 作者或管理员都能删除
            if (isAuthor && isAdmin) { // 如果既是作者又是管理员，加个分隔线
              items.add(const PopupMenuDivider(height: 1));
            }

            // 删除选项 (作者或管理员)
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

            return items;
          },
        );
      },
    );
  }

  // 使用可复用的EditDialog
  Future<void> _handleEditReply(BuildContext context, Reply reply) async {
    EditDialog.show(
      context: context,
      title: '编辑回复',
      initialText: reply.content,
      hintText: '输入新的回复内容',
      maxLines: 4,
      onSave: (newContent) async {
        try {
          await _forumService.updateReply(reply.id, newContent);

          // 通知父组件刷新
          if (onReplyChanged != null) {
            onReplyChanged!();
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('回复编辑成功')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('编辑失败：$e')),
            );
          }
        }
      },
    );
  }

  // 使用可复用的ConfirmDialog
  Future<void> _handleDeleteReply(BuildContext context, Reply reply) async {
    CustomConfirmDialog.show(
      context: context,
      title: '删除回复',
      message: '确定要删除这个回复吗？删除后不可恢复。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          await _forumService.deleteReply(reply.id);

          // 通知父组件刷新
          if (onReplyChanged != null) {
            onReplyChanged!();
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('回复删除成功')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败：$e')),
            );
          }
        }
      },
    );
  }

  // 使用可复用的TextInputField组件显示回复底部表单
  void _showReplyBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '回复 ${floor}楼',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextInputField(
                    controller: textController,
                    hintText: '写下你的回复...',
                    submitButtonText: '回复',
                    isSubmitting: isSubmitting,
                    maxLines: 3,
                    onSubmitted: (text) async {
                      if (text.trim().isEmpty) return;

                      // 设置提交状态
                      setState(() {
                        isSubmitting = true;
                      });

                      try {
                        // 这里根据实际API调整，假设有一个回复特定楼层的接口
                        await _forumService.addReply(reply.postId, text,parentId: reply.id);

                        // 关闭底部表单
                        NavigationUtils.pop(context);

                        // 通知父组件刷新
                        if (onReplyChanged != null) {
                          onReplyChanged!();
                        }

                        // 显示成功消息
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('回复成功')),
                          );
                        }
                      } catch (e) {
                        // 恢复提交状态
                        setState(() {
                          isSubmitting = false;
                        });

                        // 显示错误消息
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('回复失败：$e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}