// lib/widgets/components/screen/game/comment/comments/game_comment_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../replies/game_reply_input.dart'; // ReplyInput 仍然需要
import '../../../../../ui/badges/user_info_badge.dart';
import '../../../../../ui/dialogs/edit_dialog.dart';
import '../../../../../ui/dialogs/confirm_dialog.dart';

class GameCommentItem extends StatefulWidget {
  final Comment comment;
  final Future<void> Function(String commentId, String newContent)
      onUpdateComment;
  final Future<void> Function(String commentId) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;
  // 父组件传入的全局状态，用于判断 *是否已有* 针对此 ID 的操作在进行中
  final bool isDeleting;
  final bool isUpdating;

  const GameCommentItem({
    super.key,
    required this.comment,
    required this.onUpdateComment,
    required this.onDeleteComment,
    required this.onAddReply,
    this.isDeleting = false, // 来自 CommentsSection 的全局删除状态
    this.isUpdating = false, // 来自 CommentsSection 的全局更新状态
  });

  @override
  State<GameCommentItem> createState() => _GameCommentItemState();
}

class _GameCommentItemState extends State<GameCommentItem>
    with SnackBarNotifierMixin {
  bool _showReplyInput = false;
  bool _isSubmittingReply = false; // 添加新回复的 loading

  // --- 本地 Loading 状态 ---
  // 用于主评论的即时 UI 反馈
  bool _isMainCommentDeleting = false;
  bool _isMainCommentUpdating = false;
  // 用于回复项的即时 UI 反馈
  final Map<String, bool> _replyDeletingStates = {};
  final Map<String, bool> _replyUpdatingStates = {};
  // --------------------------

  // --- 通用的 Action Button 构建方法 ---
  Widget _buildActionsMenu(BuildContext context, Comment item) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    final bool isReply = item.parentId != null;

    final bool canEdit = item.userId == authProvider.currentUser?.id;
    final bool canDelete = canEdit || authProvider.currentUser?.isAdmin == true;

    if (!canEdit && !canDelete) return const SizedBox.shrink();

    // --- 获取对应的 *本地* Loading 状态，用于 UI 显示 ---
    bool isLocallyDeleting = false;
    bool isLocallyUpdating = false; // 主要用于未来编辑弹窗即时反馈
    if (isReply) {
      isLocallyDeleting = _replyDeletingStates[item.id] ?? false;
      isLocallyUpdating = _replyUpdatingStates[item.id] ?? false;
    } else {
      isLocallyDeleting = _isMainCommentDeleting;
      isLocallyUpdating = _isMainCommentUpdating;
    }
    // --- 组合本地和全局状态，决定是否禁用 ---
    // 如果本地正在操作，或者父级标记了正在操作，则禁用
    final bool isDisabled = isLocallyDeleting ||
        isLocallyUpdating ||
        (isReply ? false : (widget.isDeleting || widget.isUpdating));

    return StylishPopupMenuButton<String>(
      icon: Icons.more_vert,
      iconSize: isReply ? 18 : 20,
      iconColor: Colors.grey[600],
      triggerPadding: const EdgeInsets.all(0),
      tooltip: isReply ? '回复选项' : '评论选项',
      menuColor: theme.canvasColor,
      elevation: 2.0,
      itemHeight: 40,
      // 按钮整体是否可用
      isEnabled: !isDisabled, // 如果正在进行任何相关操作，则禁用
      items: [
        if (canEdit)
          StylishMenuItemData(
            value: 'edit',
            // 编辑按钮本身不显示 loading，依赖 isEnabled
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: isReply ? 16 : 18, color: theme.colorScheme.primary),
                SizedBox(width: isReply ? 8 : 10),
                const Text('编辑'),
              ],
            ),
            // 编辑项是否可用 (如果正在删除中，则不可编辑)
            enabled:
                !isLocallyDeleting && !(isReply ? false : widget.isDeleting),
          ),
        if (canEdit && canDelete) const StylishMenuDividerData(),
        if (canDelete)
          StylishMenuItemData(
            value: 'delete',
            // 根据 *本地* isLocallyDeleting 状态显示菊花或文字
            child: isLocallyDeleting
                ? Row(children: [
                    SizedBox(
                        width: isReply ? 16 : 18,
                        height: isReply ? 16 : 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: theme.disabledColor)),
                    SizedBox(width: isReply ? 8 : 10),
                    Text('删除中...',
                        style: TextStyle(color: theme.disabledColor)),
                  ])
                : Row(children: [
                    Icon(Icons.delete_outline,
                        size: isReply ? 16 : 18,
                        color: theme.colorScheme.error),
                    SizedBox(width: isReply ? 8 : 10),
                    Text('删除',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ]),
            // 删除项是否可用 (如果正在删除中，则不可用)
            enabled:
                !isLocallyDeleting && !(isReply ? false : widget.isDeleting),
          ),
      ],
      onSelected: (value) {
        // 防止在 loading 状态下触发
        if (isDisabled) return;

        switch (value) {
          case 'edit':
            // 再次检查是否可编辑（虽然按钮已禁用，双重保险）
            if (!isLocallyDeleting && !(isReply ? false : widget.isDeleting)) {
              _showEditDialog(context, item);
            }
            break;
          case 'delete':
            // 再次检查是否可删除
            if (!isLocallyDeleting && !(isReply ? false : widget.isDeleting)) {
              _showDeleteDialog(context, item);
            }
            break;
        }
      },
    );
  }

  // --- 通用的 Dialog 方法 ---
  void _showEditDialog(BuildContext context, Comment item) {
    EditDialog.show(
      context: context,
      title: item.parentId == null ? '编辑评论' : '编辑回复',
      initialText: item.content,
      hintText: item.parentId == null ? '编辑评论内容...' : '编辑回复内容...',
      onSave: (text) async {
        if (!mounted) return;
        bool isReply = item.parentId != null;

        // --- 开始本地 Loading ---
        setState(() {
          if (isReply) {
            _replyUpdatingStates[item.id] = true;
          } else {
            _isMainCommentUpdating = true;
          }
        });
        // ------------------------

        try {
          await widget.onUpdateComment(item.id, text); // 调用父级回调
          // 成功后父级会刷新，Dialog 会关闭
        } catch (e) {
          showSnackbar(message: '编辑失败: $e', type: SnackbarType.error);
          // --- 出错时，结束本地 Loading ---
          if (mounted) {
            setState(() {
              if (isReply) {
                _replyUpdatingStates.remove(item.id);
              } else {
                _isMainCommentUpdating = false;
              }
            });
          }
          // ------------------------------
        } finally {
          // --- 无论成功失败（如果成功后widget还在），结束本地 Loading ---
          // 这个 finally 对于更新操作尤其重要，因为更新后 item 不会消失
          // 如果成功了，父级刷新会重建，状态自然消失；如果失败了，需要在这里清除
          if (mounted &&
              (item.parentId != null
                  ? _replyUpdatingStates.containsKey(item.id)
                  : _isMainCommentUpdating)) {
            setState(() {
              if (isReply) {
                _replyUpdatingStates.remove(item.id);
              } else {
                _isMainCommentUpdating = false;
              }
            });
          }
          // ------------------------------
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Comment item) {
    CustomConfirmDialog.show(
      context: context,
      title: item.parentId == null ? '删除评论' : '删除回复',
      message: item.parentId == null
          ? '确定要删除这条评论吗？\n(评论下的所有回复也会被删除)'
          : '确定要删除这条回复吗？',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        if (!mounted) return;
        bool isReply = item.parentId != null;

        // --- 开始本地 Loading ---
        setState(() {
          if (isReply) {
            _replyDeletingStates[item.id] = true;
          } else {
            _isMainCommentDeleting = true;
          }
        });
        // ------------------------

        try {
          await widget.onDeleteComment(item.id); // 调用父级回调
          // 成功后父级会刷新列表，此 Item (或其 Reply 部分) 会消失
          // 所以成功时不需要在 finally 里清除本地 loading 状态
        } catch (e) {
          showSnackbar(message: '删除失败: $e', type: SnackbarType.error);
          // --- 出错时，结束本地 Loading ---
          // 如果删除失败，Item 还在，必须清除 loading 状态
          if (mounted) {
            setState(() {
              if (isReply) {
                _replyDeletingStates.remove(item.id);
              } else {
                _isMainCommentDeleting = false;
              }
            });
          }
          // ------------------------------
        }
        // 不需要 finally 清除成功状态，因为成功后 Widget 理论上会被移除
      },
    );
  }

  // 提交新回复的方法不变
  Future<void> _submitReply(String replyContent) async {
    if (replyContent.isEmpty || !mounted || _isSubmittingReply) {
      return; // 防止重复提交
    }
    setState(() => _isSubmittingReply = true);
    try {
      await widget.onAddReply(replyContent, widget.comment.id);
      if (mounted) {
        setState(() {
          _showReplyInput = false; // 成功后收起输入框
        });
        // 输入框内容由 GameReplyInput 内部在成功回调后清空 (如果需要)
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '回复失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

  // --- 构建单个回复项的 Widget ---
  Widget _buildReplyWidget(BuildContext context, Comment reply) {
    final theme = Theme.of(context);
    // 直接使用本地状态来驱动UI
    return Container(
      // Key 可以在这里加，也可以在外层 map 时加
      key: ValueKey('reply_${reply.id}'),
      margin: const EdgeInsets.only(top: 8.0), // 回复间距调整
      padding: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: UserInfoBadge(
                  userId: reply.userId,
                  showFollowButton: false,
                  mini: true,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateTimeFormatter.formatRelative(reply.createTime) +
                    (reply.hasBeenEdited ? ' (已编辑)' : ''),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              // 调用通用的 Action Menu，传入 reply 对象
              _buildActionsMenu(context, reply),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              reply.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 主评论 Header ---
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
                // 调用通用的 Action Menu，传入主 comment 对象
                _buildActionsMenu(context, widget.comment),
              ],
            ),
          ),
          // --- 主评论 Content ---
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              widget.comment.content,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
          // --- 主评论 Time & Edit Status ---
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateTimeFormatter.formatRelative(widget.comment.createTime) +
                    (widget.comment.hasBeenEdited ? ' (已编辑)' : ''),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ),
          // --- 分割线和回复按钮 ---
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (!authProvider.isLoggedIn) {
                      AppSnackBar.showError(context, '请先登录后才能回复');
                      return;
                    }
                    setState(() {
                      _showReplyInput = !_showReplyInput;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size(0, 30), // 调整按钮大小
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

          // --- 渲染回复列表 ---
          // 使用 AnimatedSize 包裹回复列表和输入框，使展开/收起更平滑
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              // 将回复列表和输入框放在同一个 Column 里
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 回复列表
                if (widget.comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 40.0, right: 16.0, top: 0, bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.comment.replies
                          .map((reply) => _buildReplyWidget(context, reply))
                          .toList(),
                    ),
                  ),

                // 回复输入框 (仅在 _showReplyInput 为 true 时构建和显示)
                if (_showReplyInput)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GameReplyInput(
                      // Key 确保输入框状态在显示/隐藏时保持（如果需要的话）
                      key: ValueKey('reply_input_${widget.comment.id}'),
                      onSubmitReply: _submitReply,
                      parentCommentId: widget.comment.id,
                      isSubmitting: _isSubmittingReply,
                      onCancel: () => setState(() {
                        _showReplyInput = false;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
