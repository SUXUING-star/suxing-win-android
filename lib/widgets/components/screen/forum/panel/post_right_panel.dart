// lib/widgets/components/screen/forum/panel/post_right_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/stats/tag_stat.dart';
import 'package:suxingchahui/services/main/forum/post_stats_service.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class PostRightPanel extends StatelessWidget {
  final double panelWidth;
  final List<Post> currentPosts;
  final PostTag? selectedTag;
  final Function(PostTag?)? onTagSelected;

  const PostRightPanel({
    super.key,
    required this.panelWidth,
    required this.currentPosts,
    this.selectedTag,
    this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<TagStat> tagStats =
        PostStatsService.getTagStatistics(currentPosts);
    final int uniqueTagsCount = tagStats.length;
    final int uniqueAuthorsCount =
        PostStatsService.getUniqueAuthorsCount(currentPosts);
    final List<Post> mostDiscussedPosts =
        PostStatsService.getMostDiscussedPosts(currentPosts, limit: 3);
    final List<Post> mostViewedPosts =
        PostStatsService.getMostViewedPosts(currentPosts, limit: 3);
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: panelWidth,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withSafeOpacity(0.9),
                    primaryColor.withSafeOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '本页统计',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildStatsCard(
                      context,
                      '页面摘要',
                      [
                        StatsItem('显示帖子数', '${currentPosts.length}'),
                        StatsItem('不同标签数', '$uniqueTagsCount'),
                        StatsItem('不同作者数', '$uniqueAuthorsCount'),
                      ],
                      primaryColor),
                  const SizedBox(height: 16),
                  _buildTagsStats(context, tagStats, primaryColor),
                  const SizedBox(height: 16),
                  _buildTopPostsSection(
                      context, '讨论最热', mostDiscussedPosts, primaryColor),
                  const SizedBox(height: 16),
                  _buildTopPostsSection(
                      context, '浏览最多', mostViewedPosts, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    List<StatsItem> items,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withSafeOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Divider(height: 20, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildTagsStats(
      BuildContext context, List<TagStat> tagStats, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '标签分布',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: themeColor,
              ),
            ),
            if (selectedTag != null && onTagSelected != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTagSelected!(null),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor.withSafeOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all, size: 12, color: themeColor),
                        const SizedBox(width: 4),
                        Text(
                          '全部',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
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
              ))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tagStats.map((stat) {
                  final PostTag currentTagEnum =
                      PostTagsUtils.tagFromString(stat.name);
                  final bool isSelected = selectedTag == currentTagEnum;

                  return PostTagItem(
                    tagString: stat.name,
                    count: stat.count,
                    isSelected: isSelected,
                    onTap: onTagSelected,
                    isMini: true,
                  );
                }).toList(),
              ),
        Divider(height: 20, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildTopPostsSection(
      BuildContext context, String title, List<Post> posts, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 10),
        posts.isEmpty
            ? const EmptyStateWidget(
                message: '暂无相关帖子',
                iconData: Icons.article_outlined,
                iconSize: 40,
              )
            : Column(
                children: posts
                    .map((post) => _buildPostItem(context, post, themeColor))
                    .toList(),
              ),
        if (posts.isNotEmpty)
          Divider(height: 20, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, Post post, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: themeColor.withSafeOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            NavigationUtils.pushNamed(context, AppRoutes.postDetail,
                arguments: post.id);
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: themeColor.withSafeOpacity(0.1),
          highlightColor: themeColor.withSafeOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatIconText(Icons.visibility_outlined,
                        '${post.viewCount}', Colors.grey[600]!),
                    const SizedBox(width: 12),
                    _buildStatIconText(Icons.chat_bubble_outline,
                        '${post.replyCount}', Colors.grey[600]!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

class StatsItem {
  final String label;
  final String value;
  StatsItem(this.label, this.value);
}
