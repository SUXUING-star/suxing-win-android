// lib/screens/profile/tab/widgets/game_history_grid_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../../widgets/ui/image/safe_cached_image.dart';

// 游戏历史网格卡片组件
class GameHistoryGridCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const GameHistoryGridCard({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 游戏封面
                  SafeCachedImage(
                    imageUrl: historyItem['coverImage']?.toString() ?? '',
                    fit: BoxFit.cover,
                    onError: (url, error) {
                      print('历史游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  if (historyItem['category'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
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

                  // 上次浏览时间
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            DateTimeFormatter.formatRelative(
                              DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 游戏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historyItem['title']?.toString() ?? '未知游戏',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (historyItem['summary'] != null)
                      Text(
                        historyItem['summary']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    Spacer(),

                    // 浏览次数和上次浏览时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              '${historyItem['viewCount'] ?? 0}次',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateTimeFormatter.formatShort(
                            DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}