// lib/widgets/components/screen/game/section/comment/comments/game_comment_item.dart

/// 该文件定义了 GameCommentItem 组件，用于显示单个游戏评论及回复。
/// GameCommentItem 封装了评论的显示、编辑、删除和回复功能。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/comment/replies/game_reply_input.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/models/game/game/game_comment.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

/// `GameCommentItem` 类：显示单个游戏评论或回复的 StatefulWidget。
///
/// 该组件提供评论内容的展示、用户徽章、时间格式化、以及编辑、删除和回复操作。
class GameCommentItem extends StatefulWidget {
  final User? currentUser; // 当前登录用户
  final AuthProvider authProvider; // 认证 Provider
  final UserInfoService infoService; // 用户信息服务
  final InputStateService inputStateService; // 输入状态服务
  final UserFollowService followService; // 用户关注服务
  final GameComment comment; // 要显示的评论对象
  final Future<void> Function(GameComment comment, String newContent)
      onUpdateComment; // 更新评论的回调函数
  final Future<void> Function(GameComment comment) onDeleteComment; // 删除评论的回调函数
  final Future<void> Function(String content, String parentId)
      onAddReply; // 添加回复的回调函数
  final bool isDeleting; // 外部传入的全局删除状态
  final bool isUpdating; // 外部传入的全局更新状态

  /// 构造函数。
  const GameCommentItem({
    super.key,
    required this.currentUser,
    required this.authProvider,
    required this.infoService,
    required this.inputStateService,
    required this.followService,
    required this.comment,
    required this.onUpdateComment,
    required this.onDeleteComment,
    required this.onAddReply,
    this.isDeleting = false, // 默认值为 false
    this.isUpdating = false, // 默认值为 false
  });

  @override
  State<GameCommentItem> createState() => _GameCommentItemState();
}

class _GameCommentItemState extends State<GameCommentItem> {
  bool _showReplyInput = false; // 是否显示回复输入框
  bool _isSubmittingReply = false; // 新回复提交状态

  User? _currentUser; // 当前用户实例

  // --- 本地加载状态 ---
  bool _isMainCommentDeleting = false; // 主评论删除状态
  bool _isMainCommentUpdating = false; // 主评论更新状态
  final Map<String, bool> _replyDeletingStates = {}; // 回复项删除状态
  final Map<String, bool> _replyUpdatingStates = {}; // 回复项更新状态
  // ------------------

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _currentUser = widget.currentUser; // 更新当前用户
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant GameCommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_currentUser != widget.currentUser ||
        oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户状态
      });
    }
  }

  /// 构建操作菜单。
  ///
  /// [context]：Build 上下文。
  /// [item]：评论或回复项。
  /// 返回一个 [StylishPopupMenuButton] Widget。
  Widget _buildActionsMenu(BuildContext context, GameComment item) {
    final theme = Theme.of(context);
    final bool isReply = item.parentId != null;

    bool isLocallyDeleting = false;
    bool isLocallyUpdating = false;
    if (isReply) {
      isLocallyDeleting = _replyDeletingStates[item.id] ?? false;
      isLocallyUpdating = _replyUpdatingStates[item.id] ?? false;
    } else {
      isLocallyDeleting = _isMainCommentDeleting;
      isLocallyUpdating = _isMainCommentUpdating;
    }
    final bool isDisabled = isLocallyDeleting ||
        isLocallyUpdating ||
        (isReply
            ? false
            : (widget.isDeleting || widget.isUpdating)); // 判断按钮是否禁用
    if (widget.currentUser == null) {
      return const SizedBox.shrink(); // 无当前用户时隐藏菜单
    }
    final bool isAdmin = widget.currentUser?.isAdmin ?? false; // 判断是否为管理员
    final bool isAuthor = widget.currentUser?.id == item.userId; // 判断是否为作者
    final bool canDelete = isAdmin ? true : isAuthor; // 判断是否可删除
    if (!canDelete) return const SizedBox.shrink(); // 不可删除时隐藏菜单
    return StylishPopupMenuButton<String>(
      icon: Icons.more_vert,
      iconSize: isReply ? 18 : 20,
      iconColor: Colors.grey[600],
      triggerPadding: const EdgeInsets.all(0),
      tooltip: isReply ? '回复选项' : '评论选项',
      menuColor: theme.canvasColor,
      elevation: 2.0,
      itemHeight: 40,
      isEnabled: !isDisabled, // 按钮可用性
      items: [
        if (isAuthor) // 仅当是作者时显示编辑选项
          StylishMenuItemData(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: isReply ? 16 : 18, color: theme.colorScheme.primary),
                SizedBox(width: isReply ? 8 : 10),
                const Text('编辑'),
              ],
            ),
            enabled: !isLocallyDeleting &&
                !(isReply ? false : widget.isDeleting), // 编辑项可用性
          ),
        if (canDelete) // 仅当可删除时显示删除选项
          StylishMenuItemData(
            value: 'delete',
            child: isLocallyDeleting
                ? Row(
                    children: [
                      SizedBox(
                        width: isReply ? 16 : 18,
                        height: isReply ? 16 : 18,
                        child: const LoadingWidget(), // 显示加载动画
                      ),
                      SizedBox(width: isReply ? 8 : 10),
                      Text(
                        '删除中...',
                        style: TextStyle(color: theme.disabledColor),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: isReply ? 16 : 18,
                          color: theme.colorScheme.error),
                      SizedBox(width: isReply ? 8 : 10),
                      Text(
                        '删除',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
            enabled: !isLocallyDeleting &&
                !(isReply ? false : widget.isDeleting), // 删除项可用性
          ),
      ],
      onSelected: (value) {
        if (isDisabled) return; // 禁用状态下阻止操作

        switch (value) {
          case 'edit':
            if (!isLocallyDeleting && !(isReply ? false : widget.isDeleting)) {
              _showEditDialog(context, item); // 显示编辑对话框
            }
            break;
          case 'delete':
            if (!isLocallyDeleting && !(isReply ? false : widget.isDeleting)) {
              _showDeleteDialog(context, item); // 显示删除对话框
            }
            break;
        }
      },
    );
  }

  /// 显示编辑对话框。
  ///
  /// [context]：Build 上下文。
  /// [item]：要编辑的评论或回复项。
  void _showEditDialog(BuildContext context, GameComment item) {
    EditDialog.show(
      inputStateService: widget.inputStateService,
      context: context,
      title: item.parentId == null ? '编辑评论' : '编辑回复', // 对话框标题
      initialText: item.content, // 初始文本内容
      hintText: item.parentId == null ? '编辑评论内容' : '编辑回复内容', // 提示文本
      onSave: (text) async {
        if (!mounted) return; // 检查组件是否挂载
        bool isReply = item.parentId != null; // 判断是否为回复

        setState(() {
          if (isReply) {
            _replyUpdatingStates[item.id] = true; // 设置回复更新状态
          } else {
            _isMainCommentUpdating = true; // 设置主评论更新状态
          }
        });

        try {
          await widget.onUpdateComment(item, text); // 调用父级更新回调
        } catch (e) {
          AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误消息
          if (mounted) {
            // 检查组件是否挂载
            setState(() {
              if (isReply) {
                _replyUpdatingStates.remove(item.id); // 移除回复更新状态
              } else {
                _isMainCommentUpdating = false; // 清除主评论更新状态
              }
            });
          }
        } finally {
          if (mounted && // 检查组件是否挂载且状态未被清除
              (item.parentId != null
                  ? _replyUpdatingStates.containsKey(item.id)
                  : _isMainCommentUpdating)) {
            setState(() {
              if (isReply) {
                _replyUpdatingStates.remove(item.id); // 移除回复更新状态
              } else {
                _isMainCommentUpdating = false; // 清除主评论更新状态
              }
            });
          }
        }
      },
    );
  }

  /// 显示删除确认对话框。
  ///
  /// [context]：Build 上下文。
  /// [item]：要删除的评论或回复项。
  void _showDeleteDialog(BuildContext context, GameComment item) {
    CustomConfirmDialog.show(
      context: context,
      title: item.parentId == null ? '删除评论' : '删除回复', // 对话框标题
      message: item.parentId == null
          ? '确定要删除这条评论吗？\n(评论下的所有回复也会被删除)'
          : '确定要删除这条回复吗？', // 提示消息
      confirmButtonText: '删除', // 确认按钮文本
      confirmButtonColor: Colors.red, // 确认按钮颜色
      onConfirm: () async {
        if (!mounted) return; // 检查组件是否挂载
        bool isReply = item.parentId != null; // 判断是否为回复

        setState(() {
          if (isReply) {
            _replyDeletingStates[item.id] = true; // 设置回复删除状态
          } else {
            _isMainCommentDeleting = true; // 设置主评论删除状态
          }
        });

        try {
          await widget.onDeleteComment(item); // 调用父级删除回调
        } catch (e) {
          AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误消息
          if (mounted) {
            // 检查组件是否挂载
            setState(() {
              if (isReply) {
                _replyDeletingStates.remove(item.id); // 移除回复删除状态
              } else {
                _isMainCommentDeleting = false; // 清除主评论删除状态
              }
            });
          }
        }
      },
    );
  }

  /// 提交新回复。
  ///
  /// [replyContent]：回复内容。
  Future<void> _submitReply(String replyContent) async {
    if (replyContent.isEmpty || !mounted || _isSubmittingReply) {
      return; // 内容为空或组件未挂载或正在提交时阻止操作
    }
    setState(() => _isSubmittingReply = true); // 设置提交中状态
    try {
      await widget.onAddReply(replyContent, widget.comment.id); // 调用父级添加回复回调
      if (mounted) {
        // 检查组件是否挂载
        setState(() {
          _showReplyInput = false; // 隐藏回复输入框
        });
      }
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误消息
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false); // 清除提交中状态
    }
  }

  /// 构建单个回复项的 Widget。
  ///
  /// [context]：Build 上下文。
  /// [reply]：回复评论项。
  /// 返回一个表示单个回复的 Widget。
  Widget _buildReplyWidget(BuildContext context, GameComment reply) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('reply_${reply.id}'), // 唯一键
      margin: const EdgeInsets.only(top: 8.0), // 顶部外边距
      padding: const EdgeInsets.only(bottom: 8.0), // 底部内边距
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
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
                  infoService: widget.infoService,
                  followService: widget.followService,
                  targetUserId: reply.userId,
                  currentUser: widget.currentUser,
                  showFollowButton: false,
                  mini: true,
                ),
              ),
              const SizedBox(width: 8), // 间距
              Text(
                DateTimeFormatter.formatRelative(reply.createTime) + // 格式化时间
                    (reply.hasBeenEdited ? ' (已编辑)' : ''), // 显示编辑状态
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              _buildActionsMenu(context, reply), // 构建操作菜单
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0), // 顶部内边距
            child: Text(
              reply.content, // 回复内容
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: UserInfoBadge(
                    // 用户信息徽章
                    infoService: widget.infoService,
                    followService: widget.followService,
                    currentUser: widget.currentUser,
                    targetUserId: widget.comment.userId,
                    showFollowButton: false,
                  ),
                ),
                _buildActionsMenu(context, widget.comment), // 操作菜单
              ],
            ),
          ),
          // 主评论内容
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Text(
              widget.comment.content, // 评论内容
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateTimeFormatter.formatRelative(
                        widget.comment.createTime) + // 格式化时间
                    (widget.comment.hasBeenEdited ? ' (已编辑)' : ''), // 显示编辑状态
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          // 分割线
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 4.0,
              bottom: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (widget.currentUser == null) {
                      AppSnackBar.showLoginRequiredSnackBar(context); // 提示登录
                      return;
                    }
                    setState(() {
                      _showReplyInput = !_showReplyInput; // 切换回复输入框显示状态
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showReplyInput ? Icons.close : Icons.reply, // 图标切换
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(_showReplyInput ? '收起' : '回复'), // 文本切换
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 回复列表和输入框
          AnimatedSize(
            duration: const Duration(milliseconds: 200), // 动画持续时间
            curve: Curves.easeInOut, // 动画曲线
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.comment.replies.isNotEmpty) // 仅当存在回复时显示
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 40.0,
                      right: 16.0,
                      top: 0,
                      bottom: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.comment.replies
                          .map((reply) =>
                              _buildReplyWidget(context, reply)) // 构建回复 Widget
                          .toList(),
                    ),
                  ),
                if (_showReplyInput) // 仅当显示回复输入框时显示
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GameReplyInput(
                      inputStateService: widget.inputStateService,
                      currentUser: widget.currentUser,
                      key: ValueKey('reply_input_${widget.comment.id}'), // 唯一键
                      onSubmitReply: _submitReply, // 提交回复回调
                      parentCommentId: widget.comment.id, // 父评论 ID
                      isSubmitting: _isSubmittingReply, // 提交状态
                      onCancel: () => setState(() {
                        _showReplyInput = false; // 取消时隐藏输入框
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
