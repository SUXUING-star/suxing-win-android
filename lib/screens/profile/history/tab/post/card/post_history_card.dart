// lib/screens/profile/tab/widgets/post_history_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';

// 帖子历史卡片组件
class PostHistoryCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const PostHistoryCard({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          final postId = historyItem['postId']?.toString() ?? '';
          if (postId.isNotEmpty) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.postDetail,
              arguments: postId,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                historyItem['title']?.toString() ?? '未知帖子',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8),

              // 帖子内容预览
              if (historyItem['content'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    historyItem['content']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // 帖子作者信息
              if (historyItem['authorName'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        historyItem['authorName']?.toString() ?? '匿名用户',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // 底部统计信息和浏览时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧统计信息
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye,
                          size: 14, color: Colors.blueAccent),
                      SizedBox(width: 4),
                      Text(
                        '${historyItem['viewCount'] ?? 0}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.comment, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '${historyItem['replyCount'] ?? 0}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  // 右侧浏览时间
                  Row(
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateTimeFormatter.formatRelative(
                          DateTime.parse(
                              historyItem['lastViewTime']?.toString() ??
                                  DateTime.now().toIso8601String()),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
