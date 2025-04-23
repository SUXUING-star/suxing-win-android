// lib/widgets/components/screen/forum/panel/forum_right_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../models/post/post.dart';
import '../../../../../models/stats/tag_stat.dart';
import '../../../../../services/main/forum/stats/forum_stats_service.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../routes/app_routes.dart';

class ForumRightPanel extends StatelessWidget {
  final List<Post> currentPosts;
  final String? selectedTag;
  final Function(String)? onTagSelected;

  // 服务实例
  final ForumStatsService _statsService = ForumStatsService();

  ForumRightPanel({
    super.key,
    required this.currentPosts,
    this.selectedTag,
    this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取统计数据
    final List<TagStat> tagStats = _statsService.getTagStatistics(currentPosts);
    final int uniqueTagsCount = _statsService.getUniqueTagsCount(currentPosts);
    final int uniqueAuthorsCount =
        _statsService.getUniqueAuthorsCount(currentPosts);
    final List<Post> mostDiscussedPosts =
        _statsService.getMostDiscussedPosts(currentPosts, limit: 3);
    final List<Post> mostViewedPosts =
        _statsService.getMostViewedPosts(currentPosts, limit: 3);

    // 面板宽度
    final panelWidth = DeviceUtils.getSidePanelWidth(context);

    return Container(
      width: panelWidth,
      margin: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8, // 透明度设置为0.8，与game panels保持一致
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.blue,
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '论坛统计',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 统计区
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(12),
                    children: [
                      _buildStatsCard(
                        context,
                        '页面摘要',
                        [
                          StatsItem('显示帖子数', '${currentPosts.length}'),
                          StatsItem('标签数', '$uniqueTagsCount'),
                          StatsItem('发帖用户数', '$uniqueAuthorsCount'),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildTagsStats(context, tagStats),
                      SizedBox(height: 16),
                      _buildTopPostsSection(
                          context, '讨论最热', mostDiscussedPosts),
                      SizedBox(height: 16),
                      _buildTopPostsSection(context, '浏览最多', mostViewedPosts),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, String title, List<StatsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Divider(height: 16),
      ],
    );
  }

  Widget _buildTagsStats(BuildContext context, List<TagStat> tagStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '标签统计',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            if (selectedTag != null && onTagSelected != null)
              InkWell(
                onTap: () => onTagSelected!(selectedTag!),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        '清除',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        tagStats.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '暂无标签数据',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tagStats.map((stat) {
                  final isSelected = selectedTag == stat.name;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: onTagSelected != null
                          ? () => onTagSelected!(stat.name)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stat.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${stat.count}',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
        Divider(height: 16),
      ],
    );
  }

  Widget _buildTopPostsSection(
      BuildContext context, String title, List<Post> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        posts.isEmpty
            ? const EmptyStateWidget(
                message: '暂无帖子数据',
                iconData: Icons.post_add_outlined,
              )
            : Column(
                children:
                    posts.map((post) => _buildPostItem(context, post)).toList(),
              ),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, Post post) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.postDetail,
            arguments: post.id,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Text(
                        '${post.viewCount ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Row(
                    children: [
                      Icon(Icons.forum, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Text(
                        '${post.replyCount ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  // 用户简称或匿名
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 辅助类
class StatsItem {
  final String label;
  final String value;

  StatsItem(this.label, this.value);
}
