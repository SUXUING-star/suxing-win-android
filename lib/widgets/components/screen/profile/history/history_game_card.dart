// lib/widgets/components/screen/game/history/history_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../common/image/safe_cached_image.dart';
import '../../../../../routes/app_routes.dart';

/// 为游戏浏览历史屏幕专门设计的列表卡片组件
class HistoryGameCard extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final VoidCallback? onDeletePressed;

  const HistoryGameCard({
    Key? key,
    required this.historyItem,
    this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面布局
    final bool isDesktop = DeviceUtils.isDesktop;

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
            Navigator.pushNamed(context, AppRoutes.gameDetail, arguments: gameId);
          }
        },
        child: IntrinsicHeight( // 确保左右两侧高度一致
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧图片
              _buildGameCover(context, isDesktop),

              // 右侧信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildGameInfo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 游戏封面（左侧）
  Widget _buildGameCover(BuildContext context, bool isDesktop) {
    // 根据设备类型调整图片大小
    final coverWidth = isDesktop ? 120.0 : 100.0;

    return Stack(
      children: [
        SizedBox(
          width: coverWidth,
          height: coverWidth * 0.75, // 4:3 比例
          child: SafeCachedImage(
            imageUrl: historyItem['coverImage']?.toString() ?? '',
            fit: BoxFit.cover,
            memCacheWidth: isDesktop ? 240 : 200,
            backgroundColor: Colors.grey[200],
            onError: (url, error) {
              print('历史游戏卡片图片加载失败: $url, 错误: $error');
            },
          ),
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
      ],
    );
  }

  // 游戏信息（右侧）
  Widget _buildGameInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和删除图标在一行
        Row(
          children: [
            Expanded(
              child: Text(
                historyItem['title']?.toString() ?? '未知游戏',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
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

        SizedBox(height: 4),

        // 上次浏览时间
        Row(
          children: [
            Icon(Icons.history, size: 14, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              DateTimeFormatter.formatStandard(
                DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),

        // 中间可以放简短描述
        if (historyItem['summary'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              historyItem['summary']?.toString() ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        Spacer(),

        // 底部统计信息
        Row(
          children: [
            // 浏览次数
            Icon(Icons.visibility, size: 14, color: Colors.blueAccent),
            SizedBox(width: 4),
            Text(
              '${historyItem['viewCount'] ?? 0}次浏览',
              style: TextStyle(fontSize: 12),
            ),

            // 如果有其他数据也可以添加，例如评分等
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
    );
  }
}