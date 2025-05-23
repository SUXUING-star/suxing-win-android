// lib/widgets/components/screen/game/comment/game_comments_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'dart:async';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/comment/comment.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/dialogs/limiter/rate_limit_dialog.dart'; // 速率限制对话框
import 'package:suxingchahui/widgets/components/screen/game/comment/comments/game_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/game/comment/comments/game_comment_list.dart';
import 'package:suxingchahui/widgets/ui/buttons/login_prompt.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误提示 Widget
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载 Widget
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // SnackBar 提示

class GameCommentsSection extends StatefulWidget {
  final GameService gameService;
  final String gameId;
  final User? currentUser;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;

  const GameCommentsSection({
    super.key,
    required this.gameService,
    required this.authProvider,
    required this.currentUser,
    required this.gameId,
    required this.followService,
    required this.infoProvider,
    required this.inputStateService,
  });
  @override
  State<GameCommentsSection> createState() => _GameCommentsSectionState();
}

class _GameCommentsSectionState extends State<GameCommentsSection> {
  late Future<List<Comment>> _commentsFuture;

  // Loading 状态 (用于 UI 反馈，例如按钮禁用、显示菊花等)
  bool _isAddingComment = false; // 正在提交顶级评论
  final Set<String> _deletingCommentIds = {}; // 正在删除的评论 ID 集合
  final Set<String> _updatingCommentIds = {}; // 正在更新的评论 ID 集合

  bool _hasInitializedDependencies = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _commentsFuture = widget.gameService.fetchGameComments(widget.gameId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 加载/重新加载评论数据的方法
  void _loadComments() {
    _commentsFuture = widget.gameService.fetchGameComments(widget.gameId);
  }

  // --- 刷新回调函数 ---
  /// 触发重新加载评论列表的 Future
  void _refreshComments() {
    if (!mounted) return; // 确保组件还挂载着
    setState(() {
      // 创建一个新的 Future 实例，这会通知 FutureBuilder 重新执行 future
      _loadComments();
    });
  }

  @override
  void didUpdateWidget(covariant GameCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 gameId 变了，需要重新加载评论
    if (widget.gameId != oldWidget.gameId) {
      setState(() {
        // 重置所有与旧 gameId 相关的状态
        _isAddingComment = false;
        _deletingCommentIds.clear();
        _updatingCommentIds.clear();
        _loadComments(); // 重新加载新 gameId 的评论
      });
    }
    if (_currentUser != widget.currentUser ||
        oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  bool _checkCanUpdateOrDeleteComment(Comment comment) {
    return _currentUser?.isAdmin ?? false
        ? true
        : _currentUser?.id == comment.userId;
  }

  /// 处理添加顶级评论
  Future<void> _handleAddComment(String content) async {
    if (content.isEmpty || !mounted) return;
    setState(() => _isAddingComment = true); // 开始 loading
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    try {
      await widget.gameService.addComment(widget.gameId, content);
      if (mounted) AppSnackBar.showSuccess(context, '成功发表评论'); // 成功提示
      _refreshComments();
    } catch (e) {
      _handleError(e, '发表评论失败'); // 统一错误处理
    } finally {
      // 确保 loading 状态被重置，无论成功还是失败
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  /// 处理添加回复
  Future<void> _handleAddReply(String content, String parentId) async {
    if (content.isEmpty || !mounted) return;
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    try {
      await widget.gameService
          .addComment(widget.gameId, content, parentId: parentId);
      if (mounted) AppSnackBar.showSuccess(context, '回复已提交');
      _refreshComments();
    } catch (e) {
      _handleError(e, '回复评论失败');
    }
    // 回复的 loading 通常在 CommentItem 内部管理，这里不需要 finally
  }

  /// 处理更新评论
  Future<void> _handleUpdateComment(Comment comment, String newContent) async {
    if (!mounted) return;
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanUpdateOrDeleteComment(comment)) {
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    final commentId = comment.id;
    setState(() => _updatingCommentIds.add(commentId)); // 添加到更新中的 ID 集合

    try {
      await widget.gameService
          .updateComment(widget.gameId, comment, newContent);
      if (mounted) AppSnackBar.showSuccess(context, '评论已更新');
      _refreshComments();
    } catch (e) {
      _handleError(e, '更新评论失败');
    } finally {
      // 移除 ID，结束 loading 状态
      if (mounted) setState(() => _updatingCommentIds.remove(commentId));
    }
  }

  /// 处理删除评论
  Future<void> _handleDeleteComment(Comment comment) async {
    if (!mounted) return;
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanUpdateOrDeleteComment(comment)) {
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    final commentId = comment.id;
    setState(() => _deletingCommentIds.add(commentId)); // 添加到删除中的 ID 集合

    try {
      await widget.gameService.deleteComment(widget.gameId, comment);
      if (mounted) AppSnackBar.showSuccess(context, '评论已删除');
      _refreshComments();
    } catch (e) {
      _handleError(e, '删除评论失败');
    } finally {
      // 移除 ID，结束 loading 状态
      if (mounted) setState(() => _deletingCommentIds.remove(commentId));
    }
  }

  // --- 错误处理函数 (保持不变) ---
  void _handleError(Object e, String defaultMessage) {
    if (!mounted) return;
    final errorMsg = e.toString();

    if (errorMsg.contains('评论速率超限') ||
        errorMsg.contains('Rate limit exceeded')) {
      final remainingSeconds = _parseRemainingSeconds(errorMsg);
      if (remainingSeconds != null) {
        showRateLimitDialog(context, remainingSeconds); // 显示速率限制对话框
      } else {
        AppSnackBar.showError(context, '$defaultMessage: 速率限制，请稍后再试');
      }
    } else if (errorMsg.contains("Invalid ID")) {
      // 处理无效 ID 错误
      AppSnackBar.showError(context, '$defaultMessage: 无效的操作对象');
    } else if (errorMsg.contains("not found")) {
      // 处理未找到错误
      AppSnackBar.showError(context, '$defaultMessage: 对象不存在或已被删除');
    } else if (errorMsg.contains("unauthorized")) {
      // 处理权限错误
      AppSnackBar.showError(context, '$defaultMessage: 您没有权限执行此操作');
    } else {
      // 其他通用错误
      String displayError = errorMsg;
      // 避免显示过长的错误信息给用户
      if (displayError.startsWith('Exception: ')) {
        displayError = displayError.substring('Exception: '.length);
      }
      if (displayError.length > 100) {
        displayError = "${displayError.substring(0, 100)}...";
      }
      AppSnackBar.showError(context, '$defaultMessage: $displayError');
    }
  }

  /// 解析错误信息中的剩余秒数 (保持不变)
  int? _parseRemainingSeconds(String errorMsg) {
    final match = RegExp(r'in (\d+) seconds').firstMatch(errorMsg);
    if (match != null && match.groupCount >= 1) {
      final group1 = match.group(1);
      if (group1 != null) {
        return int.tryParse(group1);
      }
    }
    // 尝试匹配另一种可能的格式 (例如，直接是数字)
    final matchDirect = RegExp(r'速率超限 \((\d+) s\)').firstMatch(errorMsg);
    if (matchDirect != null && matchDirect.groupCount >= 1) {
      final group1 = matchDirect.group(1);
      if (group1 != null) {
        return int.tryParse(group1);
      }
    }
    return null;
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Opacity(
      // 最外层容器和样式
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 评论区标题 ---
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '评论区',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // --- 根据登录状态显示输入框或登录提示 ---
            _currentUser != null
                ? Column(
                    // 已登录：显示输入框和评论列表
                    children: [
                      GameCommentInput(
                        currentUser: widget.currentUser,
                        gameId: widget.gameId,
                        key: ValueKey(
                            'comment_input_${widget.gameId}'), // 使用 ValueKey 保证状态保留
                        onCommentAdded: _handleAddComment, // 传递添加评论的处理函数
                        isSubmitting: _isAddingComment, // 传递顶级评论提交状态
                        inputStateService: widget.inputStateService,
                      ),
                      SizedBox(height: 16),
                      // --- 评论列表构建区域 ---
                      _buildCommentListSection(), // 调用下面封装的方法
                    ],
                  )
                : LoginPrompt(
                    // 未登录：显示登录提示
                    message: '登录后查看和发表评论',
                    buttonText: '去登录', // 修改按钮文字
                  ),
          ],
        ),
      ),
    );
  }

  // --- 构建评论列表区域的方法 (使用 FutureBuilder) ---
  Widget _buildCommentListSection() {
    return FutureBuilder<List<Comment>>(
      future: _commentsFuture, //
      builder: (context, snapshot) {
        // 1. 处理加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0), // 添加一些垂直间距
              child: LoadingWidget.inline(size: 24, message: "加载评论中..."));
        }

        // 2. 处理错误状态
        if (snapshot.hasError) {
          return Padding(
            // 加个 Padding 让错误提示不至于贴边
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: InlineErrorWidget(
                errorMessage: '加载评论失败', // 简化错误信息
                // 移除错误详情: ${snapshot.error} 避免暴露过多信息
                onRetry: _refreshComments // 点击重试调用刷新
                ),
          );
        }

        // 3. 处理成功获取数据，但数据为空的情况
        final commentsToDisplay = snapshot.data ?? []; // 安全获取数据
        if (commentsToDisplay.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                '还没有评论，快来抢沙发吧！',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        // 4. 显示评论列表 (CommentList 本身不需要改动)
        // 将 Action Handlers 和 Loading 状态传递给 CommentList
        return GameCommentList(
          key: ValueKey('comment_list_${widget.gameId}'), // 保证列表状态
          currentUser: _currentUser,
          authProvider: widget.authProvider,
          inputStateService: widget.inputStateService,
          infoProvider: widget.infoProvider,
          followService: widget.followService,
          comments: commentsToDisplay,
          onUpdateComment: _handleUpdateComment, // 传递更新处理
          onDeleteComment: _handleDeleteComment, // 传递删除处理
          onAddReply: _handleAddReply, // 传递回复处理
          deletingCommentIds: _deletingCommentIds, // 传递删除中的 ID 集合
          updatingCommentIds: _updatingCommentIds, // 传递更新中的 ID 集合
        );
      },
    );
  }
}
