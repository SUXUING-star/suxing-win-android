// lib/widgets/components/screen/game/section/comment/game_comments_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'dart:async';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/game/game/game_comment.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/comment/comments/game_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/comment/comments/game_comment_list.dart';
import 'package:suxingchahui/widgets/ui/buttons/login_prompt_button.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误提示 Widget
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载 Widget
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // SnackBar 提示

class GameCommentsSection extends StatefulWidget {
  final GameService gameService;
  final String gameId;
  final User? currentUser;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final UserInfoService infoService;
  final InputStateService inputStateService;

  const GameCommentsSection({
    super.key,
    required this.gameService,
    required this.authProvider,
    required this.currentUser,
    required this.gameId,
    required this.followService,
    required this.infoService,
    required this.inputStateService,
  });
  @override
  State<GameCommentsSection> createState() => _GameCommentsSectionState();
}

class _GameCommentsSectionState extends State<GameCommentsSection> {
  late Future<List<GameComment>> _commentsFuture;

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
      _commentsFuture = widget.gameService.getGameComments(widget.gameId);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _currentUser = null;
  }

  // 加载/重新加载评论数据的方法
  void _loadComments() {
    _commentsFuture = widget.gameService.getGameComments(widget.gameId);
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

  bool _checkCanUpdateOrDeleteComment(GameComment comment) {
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
      if (mounted) AppSnackBar.showSuccess('成功发表评论'); // 成功提示
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
      if (mounted) AppSnackBar.showSuccess('回复已提交');
      _refreshComments();
    } catch (e) {
      _handleError(e, '回复评论失败');
    }
    // 回复的 loading 通常在 CommentItem 内部管理，这里不需要 finally
  }

  /// 处理更新评论
  Future<void> _handleUpdateComment(
      GameComment comment, String newContent) async {
    if (!mounted) return;
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanUpdateOrDeleteComment(comment)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    final commentId = comment.id;
    setState(() => _updatingCommentIds.add(commentId)); // 添加到更新中的 ID 集合

    try {
      await widget.gameService
          .updateComment(widget.gameId, comment, newContent);
      if (mounted) AppSnackBar.showSuccess('评论已更新');
      _refreshComments();
    } catch (e) {
      _handleError(e, '更新评论失败');
    } finally {
      // 移除 ID，结束 loading 状态
      if (mounted) setState(() => _updatingCommentIds.remove(commentId));
    }
  }

  /// 处理删除评论
  Future<void> _handleDeleteComment(GameComment comment) async {
    if (!mounted) return;
    if (_currentUser != null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanUpdateOrDeleteComment(comment)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    final commentId = comment.id;
    setState(() => _deletingCommentIds.add(commentId)); // 添加到删除中的 ID 集合

    try {
      await widget.gameService.deleteComment(widget.gameId, comment);
      AppSnackBar.showSuccess('评论已删除');
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
    AppSnackBar.showError('$defaultMessage: ${e.toString()}');
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),

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
                    const SizedBox(height: 16),
                    // --- 评论列表构建区域 ---
                    _buildCommentListSection(), // 调用下面封装的方法
                  ],
                )
              : const LoginPromptButton(
                  // 未登录：显示登录提示
                  message: '登录后查看和发表评论',
                  buttonText: '去登录', // 修改按钮文字
                ),
        ],
      ),
    );
  }

  // --- 构建评论列表区域的方法 (使用 FutureBuilder) ---
  Widget _buildCommentListSection() {
    return FutureBuilder<List<GameComment>>(
      future: _commentsFuture, //
      builder: (context, snapshot) {
        // 1. 处理加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0), // 添加一些垂直间距
            child: LoadingWidget(size: 24, message: "加载评论中..."),
          );
        }

        // 2. 处理错误状态
        if (snapshot.hasError) {
          return Padding(
            // 加个 Padding 让错误提示不至于贴边
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: InlineErrorWidget(
              errorMessage: '加载评论失败',
              onRetry: _refreshComments,
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
                style: TextStyle(
                  color: Colors.grey[600],
                ),
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
          infoService: widget.infoService,
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
