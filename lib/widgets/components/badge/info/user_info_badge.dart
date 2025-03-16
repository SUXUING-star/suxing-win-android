// lib/widgets/components/badge/user_info_badge.dart
import 'package:flutter/material.dart';
import '../../../../services/main/user/user_service.dart';
import '../../../../screens/profile/open_profile_screen.dart';
import '../../../common/image/safe_user_avatar.dart';
import 'follow_user_button.dart';

class UserInfoBadge extends StatelessWidget {
  final String userId;
  final bool showFollowButton;
  final bool mini;
  final bool showLevel;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;

  final UserService _userService = UserService();

  UserInfoBadge({
    Key? key,
    required this.userId,
    this.showFollowButton = true,
    this.mini = false,
    this.showLevel = true,
    this.padding,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getUserInfoById(userId),
      builder: (context, snapshot) {
        final username = snapshot.data?['username'] ?? '未知用户';
        final avatarUrl = snapshot.data?['avatar'];
        final experience = snapshot.data?['experience'] ?? 0;
        final level = snapshot.data?['level'] ?? 1;

        return FutureBuilder<String?>(
            future: _userService.currentUserId,
            builder: (context, currentUserSnapshot) {
              // 判断当前用户是否是自己，如果是自己则不显示关注按钮
              final bool isCurrentUser = currentUserSnapshot.hasData &&
                  currentUserSnapshot.data == userId;
              final bool shouldShowFollowButton = showFollowButton && !isCurrentUser;

              return Container(
                padding: padding,
                decoration: backgroundColor != null
                    ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(mini ? 12 : 16),
                )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeUserAvatar(
                      userId: userId,
                      avatarUrl: avatarUrl,
                      username: username,
                      radius: mini ? 14 : 18,
                      backgroundColor: Colors.grey[100],
                      enableNavigation: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenProfileScreen(userId: userId),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: mini ? 13 : 15,
                            color: textColor ?? Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (showLevel)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(level),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Lv.$level',
                                  style: TextStyle(
                                    fontSize: mini ? 10 : 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$experience XP',
                                style: TextStyle(
                                  fontSize: mini ? 10 : 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (shouldShowFollowButton) ...[
                      SizedBox(width: 8),
                      FollowUserButton(
                        userId: userId,
                        mini: mini,
                        showIcon: !mini,
                      ),
                    ],
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // 根据等级返回不同的颜色
  Color _getLevelColor(int level) {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 20) return Colors.purple;
    if (level < 50) return Colors.orange;
    return Colors.red;
  }
}