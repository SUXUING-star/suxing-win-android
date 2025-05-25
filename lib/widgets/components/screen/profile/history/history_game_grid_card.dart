// lib/widgets/components/screen/game/history/history_game_grid_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';

/// 为游戏浏览历史屏幕的网格视图设计的卡片组件
class HistoryGameGridCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final VoidCallback? onDeletePressed;

  const HistoryGameGridCard({
    super.key,
    required this.historyItem,
    this.onDeletePressed,
  });

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
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 游戏封面
                  SafeCachedImage(
                    imageUrl: historyItem['coverImage']?.toString() ?? '',
                    fit: BoxFit.cover,
                    memCacheWidth: DeviceUtils.isDesktop ? 400 : 240,
                    onError: (url, error) {
                      // print('历史游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  if (historyItem['category'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withSafeOpacity(0.8),
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

                  // 删除按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: onDeletePressed,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withSafeOpacity(0.7),
                        padding: EdgeInsets.all(8),
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
                              DateTime.parse(
                                  historyItem['lastViewTime']?.toString() ??
                                      DateTime.now().toIso8601String()),
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
                            Icon(Icons.visibility,
                                size: 14, color: Colors.blue),
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
                            DateTime.parse(
                                historyItem['lastViewTime']?.toString() ??
                                    DateTime.now().toIso8601String()),
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
