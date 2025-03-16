// lib/widgets/components/screen/activity/activity_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ActivityActionButtons extends StatelessWidget {
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final bool isAlternate;
  final double cardHeight;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const ActivityActionButtons({
    Key? key,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
    this.isAlternate = false,
    this.cardHeight = 1.0,
    required this.onLike,
    required this.onComment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isAlternate
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        _buildLikeButton(),
        SizedBox(width: 8 * cardHeight),
        _buildCommentButton(),
      ],
    );
  }

  Widget _buildLikeButton() {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onLike();
      },
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : Colors.grey.shade600,
        size: 20 * math.sqrt(cardHeight),
      ),
      label: Text(
        '$likesCount',
        style: TextStyle(
          fontSize: 14 * math.sqrt(cardHeight),
          color: isLiked ? Colors.red : Colors.grey.shade600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * math.sqrt(cardHeight),
          vertical: 8 * math.sqrt(cardHeight),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCommentButton() {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onComment();
      },
      icon: Icon(
        Icons.comment_outlined,
        color: Colors.grey.shade600,
        size: 20 * math.sqrt(cardHeight),
      ),
      label: Text(
        '$commentsCount',
        style: TextStyle(
          fontSize: 14 * math.sqrt(cardHeight),
          color: Colors.grey.shade600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * math.sqrt(cardHeight),
          vertical: 8 * math.sqrt(cardHeight),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}