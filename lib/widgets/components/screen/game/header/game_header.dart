// lib/widgets/game/game_header.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/user/user_service.dart';
import '../../../../../screens/profile/open_profile_screen.dart';


class GameHeader extends StatelessWidget {
  final Game game;
  final UserService _userService = UserService();

  GameHeader({
    Key? key,
    required this.game,
  }) : super(key: key);

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getUserInfoById(game.authorId),
      builder: (context, snapshot) {
        final username = snapshot.data?['username'] ?? '未知用户';
        final avatarUrl = snapshot.data?['avatar'];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _navigateToProfile(context, game.authorId),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person_outline, size: 16, color: Colors.grey[600])
                      : null,
                ),
                SizedBox(width: 8),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 4),
                      Text(
                        game.rating.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              game.summary,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 12),
            _buildMetaInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[600],
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAuthorInfo(context),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              height: 12,
              color: Colors.grey[300],
            ),
            Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text('${game.viewCount} 次浏览', style: textStyle),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text('发布于 ${DateFormatter.format(game.createTime)}', style: textStyle),
          ],
        ),
      ],
    );
  }
}
class DateFormatter {
  static String format(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
