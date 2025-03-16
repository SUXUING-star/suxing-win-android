// lib/widgets/user/user_card_mini.dart
import 'package:flutter/material.dart';
import '../../badge/user_info_badge.dart';

class UserCardMini extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatar;

  const UserCardMini({
    Key? key,
    required this.userId,
    required this.username,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: UserInfoBadge(
        userId: userId,
        showFollowButton: true,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}