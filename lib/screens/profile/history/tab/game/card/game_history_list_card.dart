// lib/screens/profile/tab/widgets/game_history_list_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../../widgets/ui/image/safe_cached_image.dart';

// 游戏历史列表卡片组件
class GameHistoryListCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const GameHistoryListCard({Key? key, required this.historyItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          final gameId = historyItem['gameId']?.toString() ?? '';
          if (gameId.isNotEmpty) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.gameDetail,
              arguments: gameId,
            );
          }
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 游戏封面
              SizedBox(
                width: 100,
                height: 75,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeCachedImage(
                      imageUrl: historyItem['coverImage']?.toString() ?? '',
                      fit: BoxFit.cover,
                      onError: (url, error) {
                        print('历史记录游戏封面加载失败: $url, 错误: $error');
                      },
                    ),
                    if (historyItem['category'] != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            historyItem['category']?.toString() ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 游戏信息
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyItem['title']?.toString() ?? '未知游戏',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '上次浏览: ${DateTimeFormatter.formatStandard(
                            DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String())
                        )}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye, size: 14, color: Colors.blueAccent),
                          SizedBox(width: 4),
                          Text(
                            '${historyItem['viewCount'] ?? 0}',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (historyItem['rating'] != null) ...[
                            SizedBox(width: 12),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '${historyItem['rating']}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}