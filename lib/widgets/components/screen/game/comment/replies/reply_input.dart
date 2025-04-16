import 'package:flutter/material.dart';
import '../../../../../ui/inputs/comment_input_field.dart';

class ReplyInput extends StatefulWidget {
  // --- Callbacks received from Parent (CommentItem) ---
  final Future<void> Function(String reply) onSubmitReply;
  final VoidCallback? onCancel;
  final bool isSubmitting; // Loading state from parent

  const ReplyInput({
    Key? key,
    required this.onSubmitReply,
    required this.isSubmitting,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  // REMOVED: final GameService _commentService = GameService();
  // REMOVED: bool _isSubmitting = false; (Now passed from parent)
  final TextEditingController _controller = TextEditingController(); // Keep controller local

  Future<void> _submitReply(String reply) async {
    if (reply.isEmpty || widget.isSubmitting) return;

    // Call the parent's handler (CommentItem's _submitReply)
    // Error/Success handling is done higher up (CommentsSection)
    await widget.onSubmitReply(reply);

    // Clear input optimistically
    if (mounted) {
      _controller.clear();
      // Consider calling widget.onCancel here automatically after success if desired
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Use the shared CommentInputField ---
    return CommentInputField(
      controller: _controller, // Pass local controller
      hintText: '回复评论...',
      submitButtonText: '回复',
      isSubmitting: widget.isSubmitting, // Use parent's loading state
      onSubmit: _submitReply, // Pass local submit handler
      isReply: true,
      maxLines: 1,
      onCancel: widget.onCancel, // Pass cancel callback through
    );
  }
}