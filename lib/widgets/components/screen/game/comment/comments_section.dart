// lib/widgets/components/screen/game/comment/comments_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/comment/comment.dart';
import 'package:suxingchahui/widgets/components/dialogs/limiter/rate_limit_dialog.dart'; // 确保路径正确
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import './comments/comment_input.dart';
import './comments/comment_list.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../widgets/ui/buttons/login_prompt.dart';

class CommentsSection extends StatefulWidget {
  final String gameId;
  const CommentsSection({super.key, required this.gameId});
  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final GameService _gameService = GameService();
  late Stream<List<Comment>> _commentsStream;
  List<Comment>? _currentComments;
  bool _initialLoadComplete = false;
  Object? _streamError;

  // Loading states
  bool _isAddingComment = false;
  final Set<String> _deletingCommentIds = {};
  final Set<String> _updatingCommentIds = {};
  // 添加一个用于手动刷新的 loading 状态
  bool _isFetchingLatest = false;

  @override
  void initState() {
    super.initState();
    _initializeStreamAndListen();
  }

  void _initializeStreamAndListen() {
    print("Initializing comment stream and listening for ${widget
        .gameId}..."); // 加个日志好调试
    _commentsStream = _gameService.getGameComments(widget.gameId);
    _commentsStream.listen(
          (comments) {
        if (mounted) {
          print("Stream delivered ${comments.length} comments for ${widget
              .gameId}. Updating state.");
          setState(() {
            _currentComments = comments;
            _initialLoadComplete = true; // 流成功返回数据，标记初始加载完成
            _streamError = null; // 清除错误状态
          });
        }
      },
      onError: (error, stackTrace) {
        print("Comments Stream Error in Listener for ${widget
            .gameId}: $error\n$stackTrace");
        if (mounted) {
          setState(() {
            _streamError = error;
            _initialLoadComplete = true; // 即使流出错，也标记初始加载完成（尝试显示错误信息）
            // _currentComments 保持不变或者设为 null/[]，取决于你希望错误时如何显示
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameId != oldWidget.gameId) {
      setState(() {
        _isAddingComment = false;
        _deletingCommentIds.clear();
        _updatingCommentIds.clear();
        _currentComments = null;
        _initialLoadComplete = false;
        _streamError = null;
        _isFetchingLatest = false; // 重置手动刷新状态
        _initializeStreamAndListen(); // 重新初始化并监听
      });
    }
  }

  // --- Action Handlers ---
  // 操作成功后，调用 _fetchLatestCommentsAndUpdateState 强制刷新 UI

  Future<void> _handleAddComment(String content) async {
    if (content.isEmpty || !mounted) return;
    setState(() => _isAddingComment = true);
    try {
      await _gameService.addComment(widget.gameId, content);
      if (mounted) AppSnackBar.showSuccess(context, '成功发表评论');
      await _fetchLatestCommentsAndUpdateState(); // 强制刷新
    } catch (e) {
      _handleError(e, '发表评论失败');
    } finally {
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  Future<void> _handleAddReply(String content, String parentId) async {
    if (content.isEmpty || !mounted) return;
    try {
      await _gameService.addComment(widget.gameId, content, parentId: parentId);
      if (mounted) AppSnackBar.showSuccess(context, '回复已提交');
      await _fetchLatestCommentsAndUpdateState(); // 强制刷新
    } catch (e) {
      _handleError(e, '回复评论失败');
    }
  }

  Future<void> _handleUpdateComment(String commentId, String newContent) async {
    if (!mounted) return;
    setState(() => _updatingCommentIds.add(commentId));
    try {
      await _gameService.updateComment(widget.gameId, commentId, newContent);
      if (mounted) AppSnackBar.showSuccess(context, '评论已更新');
      await _fetchLatestCommentsAndUpdateState(); // 强制刷新
    } catch (e) {
      _handleError(e, '更新评论失败');
    } finally {
      if (mounted) setState(() => _updatingCommentIds.remove(commentId));
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    if (!mounted) return;
    setState(() => _deletingCommentIds.add(commentId));
    try {
      await _gameService.deleteComment(widget.gameId, commentId);
      if (mounted) AppSnackBar.showSuccess(context, '评论已删除');
      await _fetchLatestCommentsAndUpdateState(); // 强制刷新
    } catch (e) {
      _handleError(e, '删除评论失败');
    } finally {
      if (mounted) setState(() => _deletingCommentIds.remove(commentId));
    }
  }

  // --- 获取最新评论并调用 setState 的方法 ---
  Future<void> _fetchLatestCommentsAndUpdateState() async {
    // 防止重复手动刷新
    if (_isFetchingLatest || !mounted) return;
    if (mounted) setState(() => _isFetchingLatest = true);

    print("Manually fetching latest comments for ${widget.gameId}...");
    try {
      // *** 你需要确保 GameService 有一个 getLatestGameComments 方法 ***
      // 这个方法应该直接调用 API 获取最新的评论列表，而不是返回流
      final latestComments =
      await _gameService.getLatestGameComments(widget.gameId);
      if (mounted) {
        setState(() {
          _currentComments = latestComments; // 更新本地状态触发 UI 重建
          _streamError = null; // 清除之前的流错误
          _initialLoadComplete = true; // 标记加载完成
        });
        print("Manual fetch success, updated local state.");
      }
    } catch (e) {
      print("Error fetching latest comments after action: $e");
      if (mounted) {
        AppSnackBar.showError(context, '刷新评论列表失败');
        // 即使刷新失败，也要标记初始加载完成（如果之前未完成）
        if (!_initialLoadComplete) {
          setState(() => _initialLoadComplete = true);
        }
      }
    } finally {
      if (mounted) setState(() => _isFetchingLatest = false);
    }
  }

  // --- Error Handling ---
  void _handleError(Object e, String defaultMessage) {
    if (!mounted) return;
    final errorMsg = e.toString();
    if (errorMsg.contains('评论速率超限') || errorMsg.contains('rate limit')) {
      final remainingSeconds = _parseRemainingSeconds(errorMsg);
      if (remainingSeconds != null) {
        showRateLimitDialog(context, remainingSeconds);
      } else {
        AppSnackBar.showError(context, '$defaultMessage: 速率限制，请稍后再试');
      }
    } else {
      String displayError = errorMsg;
      if (displayError.length > 100) {
        displayError = "${displayError.substring(0, 100)}...";
      }
      AppSnackBar.showError(context, '$defaultMessage: $displayError');
    }
  }

  int? _parseRemainingSeconds(String errorMsg) {
    final match = RegExp(r'in (\d+) seconds').firstMatch(errorMsg);
    return (match != null && match.groupCount >= 1)
        ? int.tryParse(match.group(1)!)
        : null;
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            authProvider.isLoggedIn
                ? Column(
              children: [
                CommentInput(
                  key: ValueKey('comment_input_${widget.gameId}'),
                  onCommentAdded: _handleAddComment,
                  isSubmitting: _isAddingComment,
                ),
                SizedBox(height: 16),
                // *** 调用构建评论列表区域的方法 ***
                _buildCommentListSection(),
              ],
            )
                : LoginPrompt(
              // 完整的 LoginPrompt
              message: '登录后查看和发表评论',
              buttonText: '登录',
              // onLoginPressed: () => NavigationUtils.pushNamed(context, '/login'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 构建评论列表区域的方法 ---
  Widget _buildCommentListSection() {
    // 1. 处理初始加载状态 (或手动刷新时)
    if (!_initialLoadComplete ||
        (_isFetchingLatest && _currentComments == null)) {
      // 如果是手动刷新且没有旧数据，也显示 Loading
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: LoadingWidget.inline(size: 24, message: "加载评论中..."));
    }

    // 2. 处理错误状态 (优先显示错误信息，即使有旧数据)
    if (_streamError != null && _currentComments == null) {
      // 只有在完全没有数据时才显示错误组件
      return InlineErrorWidget(
          errorMessage: '加载评论失败', onRetry: _fetchLatestCommentsAndUpdateState);
    }

    // 3. 显示评论列表 (使用本地状态 _currentComments)
    // 如果 _currentComments 为 null (理论上在加载完成后不会)，显示空列表
    final commentsToDisplay = _currentComments ?? [];

    // 可以选择在列表顶部或底部添加一个小的刷新指示器
    Widget listWidget = CommentList(
      key: ValueKey('comment_list_${widget.gameId}'),
      comments: commentsToDisplay,
      onUpdateComment: _handleUpdateComment,
      onDeleteComment: _handleDeleteComment,
      onAddReply: _handleAddReply,
      deletingCommentIds: _deletingCommentIds,
      updatingCommentIds: _updatingCommentIds,
    );

    // 如果正在手动刷新，可以在列表上方或下方加个小菊花
    if (_isFetchingLatest && _currentComments != null) {
      listWidget = Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: LoadingWidget.inline(size: 16, message: "正在刷新..."), //小的刷新指示器
          ),
          listWidget,
        ],
      );
    }

    return listWidget;
  } // End of _buildCommentListSection
} // End of _CommentsSectionState
