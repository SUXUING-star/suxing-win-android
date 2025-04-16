import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart'; // Service
import 'package:suxingchahui/models/comment/comment.dart'; // Model
import 'package:suxingchahui/widgets/components/dialogs/limiter/rate_limit_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // UI
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // UI
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // UI


import './comments/comment_input.dart'; // Child
import './comments/comment_list.dart';  // Child
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../widgets/ui/buttons/login_prompt.dart';

class CommentsSection extends StatefulWidget {
  final String gameId;
  final VoidCallback? onCommentAdded; // 这个回调可能不再需要，因为列表会自动更新

  const CommentsSection({
    Key? key,
    required this.gameId,
    this.onCommentAdded, // 保留以防外部仍需知道有新评论添加
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  // --- 1. Service Instance (Only here!) ---
  final GameService _gameService = GameService();
  late Stream<List<Comment>> _commentsStream;

  // --- 2. Loading states for actions ---
  bool _isAddingComment = false;
  // 可以为更新/删除也添加 loading 状态，但通常在对话框或按钮内部处理更直观
  // Set<String> _updatingCommentIds = {};
  // Set<String> _deletingCommentIds = {};

  @override
  void initState() {
    super.initState();
    // --- 3. Initialize the stream ---
    _commentsStream = _gameService.getGameComments(widget.gameId);
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 gameId 变了，重新获取 stream
    if (widget.gameId != oldWidget.gameId) {
      setState(() {
        _commentsStream = _gameService.getGameComments(widget.gameId);
      });
    }
  }

  // --- 4. Action Handlers (Calling Service) ---

  Future<void> _handleAddComment(String content) async {
    if (content.isEmpty) return;
    setState(() => _isAddingComment = true);
    try {
      await _gameService.addComment(widget.gameId, content);
      // StreamBuilder 会自动更新列表
      widget.onCommentAdded?.call(); // 通知外部（如果需要）
      if (mounted) AppSnackBar.showSuccess(context, '成功发表评论');
    } catch (e) {
      _handleError(e, '发表评论失败');
    } finally {
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  Future<void> _handleAddReply(String content, String parentId) async {
    if (content.isEmpty) return;
    // 这里可以加一个针对特定评论的回复加载状态，如果需要的话
    // setState(() => _isReplyingTo[parentId] = true);
    try {
      await _gameService.addComment(widget.gameId, content, parentId: parentId);
      // StreamBuilder 会自动更新列表及其回复
      if (mounted) AppSnackBar.showSuccess(context, '回复已提交');
    } catch (e) {
      _handleError(e, '回复评论失败');
    } finally {
      // if (mounted) setState(() => _isReplyingTo[parentId] = false);
    }
  }

  Future<void> _handleUpdateComment(String commentId, String newContent) async {
    // setState(() => _updatingCommentIds.add(commentId));
    try {
      await _gameService.updateComment(widget.gameId, commentId, newContent);
      // StreamBuilder 会自动更新
      if (mounted) AppSnackBar.showSuccess(context, '评论已更新');
    } catch (e) {
      _handleError(e, '更新评论失败');
    } finally {
      // if (mounted) setState(() => _updatingCommentIds.remove(commentId));
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    // setState(() => _deletingCommentIds.add(commentId));
    try {
      await _gameService.deleteComment(widget.gameId, commentId);
      // StreamBuilder 会自动更新
      if (mounted) AppSnackBar.showSuccess(context, '评论已删除');
    } catch (e) {
      _handleError(e, '删除评论失败');
    } finally {
      // if (mounted) setState(() => _deletingCommentIds.remove(commentId));
    }
  }

  // --- Helper for Error Handling ---
  void _handleError(Object e, String defaultMessage) {
    if (!mounted) return;
    final errorMsg = e.toString();
    if (errorMsg.contains('评论速率超限')) {
      final remainingSeconds = parseRemainingSecondsFromError(errorMsg);
      showRateLimitDialog(context, remainingSeconds);
    } else {
      AppSnackBar.showError(context, '$defaultMessage: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // --- 样式代码保持不变 ---
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
                Container(width: 4, height: 20, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2),),),
                SizedBox(width: 8),
                Text('评论区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800],),),
              ],
            ),
            SizedBox(height: 16),

            // --- 根据登录状态显示不同内容 ---
            authProvider.isLoggedIn
                ? Column(
              children: [
                // --- 5. Pass Callbacks Down ---
                CommentInput(
                  // REMOVED: gameId (not needed directly)
                  onCommentAdded: _handleAddComment, // Pass the action handler
                  isSubmitting: _isAddingComment,   // Pass loading state
                ),
                // --- 6. Use StreamBuilder for the list ---
                StreamBuilder<List<Comment>>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return InlineErrorWidget(errorMessage: '加载评论失败：${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      // Show loading only initially or if stream resets
                      return snapshot.connectionState == ConnectionState.waiting
                          ? LoadingWidget.inline(size: 10, message: "正在加载评论")
                          : const SizedBox.shrink(); // Or an empty state if preferred after initial load
                    }

                    final comments = snapshot.data!;

                    // Pass data and *all* necessary callbacks down to CommentList
                    return CommentList(
                      comments: comments, // Pass the data
                      onUpdateComment: _handleUpdateComment,
                      onDeleteComment: _handleDeleteComment,
                      onAddReply: _handleAddReply,
                    );
                  },
                ),
              ],
            )
                : LoginPrompt(
              message: '登录后查看和发表评论',
              buttonText: '登录',
            ),
          ],
        ),
      ),
    );
  }
}