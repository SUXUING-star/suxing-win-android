import 'package:flutter/material.dart';

import 'package:suxingchahui/models/activity/activity_stats.dart';
import 'package:suxingchahui/models/activity/activity_type_count.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

/// 一个可展开/收起，且极致紧凑的用户动态统计组件。
///
/// 默认收起，只显示总数。展开后使用 Wrap 布局高效展示所有类型。
class ActivityStatsCard extends StatefulWidget {
  final ActivityStats? activityStats;
  final bool isLoading;

  const ActivityStatsCard({
    super.key,
    required this.activityStats,
    required this.isLoading,
  });

  @override
  State<ActivityStatsCard> createState() => _ActivityStatsCardState();
}

class _ActivityStatsCardState extends State<ActivityStatsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(height: 50, child: LoadingWidget());
    }

    if (widget.activityStats == null ||
        widget.activityStats!.countsByType.isEmpty) {
      return const SizedBox(
          height: 50, child: EmptyStateWidget(message: "暂无统计"));
    }

    final sortedCounts =
        List<ActivityTypeCount>.from(widget.activityStats!.countsByType)
          ..sort((a, b) => b.count.compareTo(a.count));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 让 Column 高度自适应
        children: [
          // 始终显示的头部，包含总数和展开/收起按钮
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                const Text(
                  '动态统计',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${widget.activityStats!.totalActivities})',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // 可展开的详细内容区域
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8.0), // 与头部有点间距
              child: Wrap(
                spacing: 6.0, // 水平间距
                runSpacing: 4.0, // 垂直间距
                children:
                    sortedCounts.map((item) => _buildStatChip(item)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建一个极小的、像标签一样的统计块。
  Widget _buildStatChip(ActivityTypeCount item) {
    final typeName = item.textLabel;
    final bgColor = item.backgroundColor;
    final textColor =
        bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 让 Row 宽度自适应内容
        children: [
          Text(
            typeName,
            style: TextStyle(color: textColor, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            '${item.count}',
            style: TextStyle(
                color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
