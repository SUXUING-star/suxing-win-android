// lib/widgets/components/common/avatar_rate_limit_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class AvatarRateLimitDialog extends StatelessWidget {
  final int remainingSeconds;

  const AvatarRateLimitDialog({
    super.key,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('头像上传速率限制'),
      content:
          Text('您的头像上传速率超出限制。每分钟最多只能上传2次头像。\n\n请在 $remainingSeconds 秒后再尝试。'),
      actions: [
        TextButton(
          onPressed: () => NavigationUtils.of(context).pop(),
          child: const Text('了解'),
        ),
      ],
    );
  }
}

// Helper function to show the rate limit dialog
void showAvatarRateLimitDialog(BuildContext context, int remainingSeconds) {
  showDialog(
    context: context,
    builder: (context) =>
        AvatarRateLimitDialog(remainingSeconds: remainingSeconds),
  );
}

// Function to parse error message and extract remaining seconds
int parseRemainingSecondsFromError(String errorMessage) {
  // Extract number from error message like "头像上传速率超限。请在 45 秒后再尝试。"
  final RegExp regex = RegExp(r'(\d+)\s*秒');
  final match = regex.firstMatch(errorMessage);
  if (match != null && match.groupCount >= 1) {
    return int.tryParse(match.group(1)!) ?? 60;
  }
  return 60; // Default to 60 seconds if parsing fails
}
