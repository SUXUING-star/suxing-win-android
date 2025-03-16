// lib/widgets/components/common/rate_limit_dialog.dart
import 'package:flutter/material.dart';

class RateLimitDialog extends StatelessWidget {
  final int remainingSeconds;

  const RateLimitDialog({Key? key, required this.remainingSeconds}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('评论速率限制'),
      content: Text('您的评论/回复速率超出限制。每分钟最多只能发送2条评论或回复。\n\n请在 $remainingSeconds 秒后再尝试。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('了解'),
        ),
      ],
    );
  }
}

// Helper function to show the rate limit dialog
void showRateLimitDialog(BuildContext context, int remainingSeconds) {
  showDialog(
    context: context,
    builder: (context) => RateLimitDialog(remainingSeconds: remainingSeconds),
  );
}

// Function to parse error message and extract remaining seconds
int parseRemainingSecondsFromError(String errorMessage) {
  // Extract number from error message like "评论速率超限。请在 45 秒后再尝试。"
  final RegExp regex = RegExp(r'(\d+)\s*秒');
  final match = regex.firstMatch(errorMessage);
  if (match != null && match.groupCount >= 1) {
    return int.tryParse(match.group(1)!) ?? 60;
  }
  return 60; // Default to 60 seconds if parsing fails
}