// lib/widgets/game/game_header.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../../models/game/game.dart';
import '../tag/game_tags.dart'; // 导入游戏标签组件
import '../../../../ui/badges/user_info_badge.dart'; // 导入新的用户信息组件

class GameHeader extends StatelessWidget {
  final Game game;

  const GameHeader({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

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
            AppText(
              game.title,
              fontSize: isDesktop ? 24 : 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            SizedBox(height: 8),
            Text(
              game.summary,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            if (game.tags.isNotEmpty) ...[
              SizedBox(height: 12),
              GameTags(
                game: game,
                wrap: false,
                maxTags: 5,
              ),
            ],
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
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 使用新的用户信息组件
            UserInfoBadge(
              userId: game.authorId,
              mini: true,
              showLevel: true,
            ),
            Container(
              width: 1,
              height: 12,
              color: Colors.grey[300],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.remove_red_eye_outlined,
                    size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('${game.viewCount} 次浏览', style: textStyle),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up_off_alt_outlined,
                    size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('${game.likeCount} 人点赞', style: textStyle),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_added_outlined,
                    size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                AppText('${game.totalCollections} 人收藏', style: textStyle),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border_outlined,
                    size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                AppText('评分值${game.rating}', style: textStyle),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text('发布于 ${DateTimeFormatter.formatTimeAgo(game.createTime)}',
                style: textStyle),
            SizedBox(width: 4),
            Text('编辑于 ${DateTimeFormatter.formatTimeAgo(game.updateTime)}',
                style: textStyle),
          ],
        ),
      ],
    );
  }
}
