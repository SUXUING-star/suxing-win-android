// lib/widgets/components/screen/forum/panel/forum_right_panel.dart
import 'package:flutter/material.dart';
import '../../../../../models/post/post.dart';
import '../../../../../models/stats/tag_stat.dart';
import '../../../../../services/main/forum/stats/forum_stats_service.dart';
import '../../gamelist/tag/tag_cloud.dart';

class ForumRightPanel extends StatelessWidget {
  final List<Post> currentPosts;
  final String? selectedTag;
  final Function(String)? onTagSelected;

  // 服务实例 - 统计逻辑放在服务层
  final ForumStatsService _statsService = ForumStatsService();

  ForumRightPanel({
    Key? key,
    required this.currentPosts,
    this.selectedTag,
    this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从服务层获取统计数据
    final List<TagStat> tagStats = _statsService.getTagStatistics(currentPosts);
    final int uniqueTagsCount = _statsService.getUniqueTagsCount(currentPosts);
    final int uniqueAuthorsCount = _statsService.getUniqueAuthorsCount(currentPosts);
    final List<Post> mostDiscussedPosts = _statsService.getMostDiscussedPosts(currentPosts, limit: 3);
    final List<Post> mostViewedPosts = _statsService.getMostViewedPosts(currentPosts, limit: 3);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildForumSummary(context, uniqueTagsCount, uniqueAuthorsCount),
              SizedBox(height: 12),
              _buildTagsPanel(context, tagStats),
              SizedBox(height: 12),
              _buildTopPostsPanel(context, '讨论最热', mostDiscussedPosts),
              SizedBox(height: 12),
              _buildTopPostsPanel(context, '浏览最多', mostViewedPosts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumSummary(BuildContext context, int tagsCount, int authorsCount) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前版块摘要',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildInfoRow('帖子数量', '${currentPosts.length}'),
            Divider(height: 16),
            _buildInfoRow('标签数量', '$tagsCount'),
            Divider(height: 16),
            _buildInfoRow('发帖用户数', '$authorsCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsPanel(BuildContext context, List<TagStat> tagStats) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '热门标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedTag != null && onTagSelected != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () => onTagSelected!(selectedTag!),
                    tooltip: '清除筛选',
                    constraints: BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            SizedBox(height: 8),
            tagStats.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('无标签数据'),
            )
                : StatTagCloud(
              tags: tagStats,
              selectedTag: selectedTag,
              onTagSelected: onTagSelected,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPostsPanel(BuildContext context, String title, List<Post> posts) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            posts.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('暂无帖子数据'),
            )
                : ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: posts.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.visibility, size: 12),
                      SizedBox(width: 2),
                      Text(
                        '${post.viewCount ?? 0}',
                        style: TextStyle(fontSize: 11),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.forum, size: 12),
                      SizedBox(width: 2),
                      Text(
                        '${post.replyCount ?? 0}',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/forum/post/${post.id}',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}