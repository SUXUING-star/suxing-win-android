import 'package:flutter/material.dart';
// REMOVED: import 'package:suxingchahui/services/main/game/game_service.dart';
// REMOVED: import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
// REMOVED: import '../../../../dialogs/limiter/rate_limit_dialog.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // Use the shared input field

class CommentInput extends StatefulWidget {
  // --- Callback received from Parent (CommentsSection) ---
  final Future<void> Function(String comment) onCommentAdded;
  final bool isSubmitting; // Loading state from parent

  const CommentInput({
    Key? key,
    required this.onCommentAdded,
    required this.isSubmitting,
    // REMOVED: gameId
    // REMOVED: onCommentAdded (renamed to onCommentAdded)
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  // REMOVED: final GameService _commentService = GameService();
  // REMOVED: bool _isSubmitting = false; (Now passed from parent)
  final TextEditingController _controller = TextEditingController(); // Keep controller local

  Future<void> _submitComment(String comment) async {
    if (comment.isEmpty || widget.isSubmitting) return;

    // Call the parent's handler
    // Error/Success handling is done in the parent (CommentsSection)
    await widget.onCommentAdded(comment);

    // Clear input only if submission was handled (might fail)
    // Parent should ideally signal success/failure, but clearing optimistically is common
    if (mounted) { // Check if widget is still in the tree
      _controller.clear(); // Clear the input field after submitting
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Use the shared CommentInputField ---
    return CommentInputField(
      controller: _controller, // Pass the local controller
      hintText: '发表评论...',
      submitButtonText: '发表',
      isSubmitting: widget.isSubmitting, // Use parent's loading state
      onSubmit: _submitComment, // Pass the local submit handler
      maxLines: 3,
    );
  }
}

