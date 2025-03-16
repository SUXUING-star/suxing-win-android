// lib/widgets/components/screen/activity/activity_comment_input.dart

import 'package:flutter/material.dart';

class ActivityCommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isAlternate; // 是否交替布局
  final String hintText;

  const ActivityCommentInput({
    Key? key,
    required this.onSubmit,
    this.isAlternate = false,
    this.hintText = '发表评论...',
  }) : super(key: key);

  @override
  _ActivityCommentInputState createState() => _ActivityCommentInputState();
}

class _ActivityCommentInputState extends State<ActivityCommentInput> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {
        _isComposing = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    widget.onSubmit(comment);
    _commentController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr, // 输入框文本方向始终是从左到右
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isComposing
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              iconSize: 20,
              onPressed: _isComposing ? _handleSubmit : null,
            ),
          ),
        ],
      ),
    );
  }
}