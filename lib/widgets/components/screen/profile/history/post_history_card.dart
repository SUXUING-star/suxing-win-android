// lib/widgets/components/screen/post/history/post_history_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../../routes/app_routes.dart';

/// 为帖子浏览历史屏幕专门设计的卡片组件
class PostHistoryCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final VoidCallback? onDeletePressed;

  const PostHistoryCard({
    super.key,
    required this.historyItem,
    this.onDeletePressed,
  });

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
          final postId = historyItem['postId']?.toString() ?? '';
          if (postId.isNotEmpty) {
            NavigationUtils.pushNamed(context, AppRoutes.postDetail, arguments: postId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和删除按钮
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      historyItem['title']?.toString() ?? '未知帖子',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: onDeletePressed,
                  ),
                ],
              ),

              SizedBox(height: 8),

              // 帖子内容预览
              if (historyItem['previewContent'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    historyItem['previewContent']?.toString() ?? '',
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
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.blueAccent),
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
                          DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
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