// lib/widgets/components/screen/forum/panel/forum_right_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart'; // 需要 PostTag 相关
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart'; // 引入 PostTagItem
import '../../../../../models/post/post.dart';
import '../../../../../models/stats/tag_stat.dart';
import '../../../../../services/main/forum/stats/forum_stats_service.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../routes/app_routes.dart'; // 需要路由
import '../../../../../utils/navigation/navigation_utils.dart'; // 需要导航工具

class ForumRightPanel extends StatelessWidget {
  final List<Post> currentPosts;
  // --- 参数类型修改 ---
  final PostTag? selectedTag; // 接收 PostTag?
  final Function(PostTag?)? onTagSelected; // 回调函数类型改变 (可选)

  // 服务实例 (可以考虑用 Provider 获取)
  final ForumStatsService _statsService = ForumStatsService();

  ForumRightPanel({
    super.key,
    required this.currentPosts,
    this.selectedTag,
    this.onTagSelected, // 接收可选的回调
  });

  @override
  Widget build(BuildContext context) {
    // 获取统计数据
    final List<TagStat> tagStats = _statsService.getTagStatistics(currentPosts);
    final int uniqueTagsCount = tagStats.length;
    final int uniqueAuthorsCount =
        _statsService.getUniqueAuthorsCount(currentPosts);
    final List<Post> mostDiscussedPosts =
        _statsService.getMostDiscussedPosts(currentPosts, limit: 3);
    final List<Post> mostViewedPosts =
        _statsService.getMostViewedPosts(currentPosts, limit: 3);

    final panelWidth = DeviceUtils.getSidePanelWidth(context);
    final primaryColor = Theme.of(context).primaryColor; // 获取主题色

    return Container(
      width: panelWidth,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // 统一使用 Decoration
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        // 内部内容裁剪圆角
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // 使用渐变
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.9),
                    primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      color: Colors.white, size: 18), // 换个图标
                  SizedBox(width: 8),
                  Text(
                    '本页统计', // 改个名字
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
                // 使用 ListView 代替 Column + SingleChildScrollView
                padding: const EdgeInsets.all(12),
                children: [
                  _buildStatsCard(
                      context,
                      '页面摘要',
                      [
                        StatsItem('显示帖子数', '${currentPosts.length}'),
                        StatsItem('不同标签数', '$uniqueTagsCount'), // 使用计算好的值
                        StatsItem('不同作者数', '$uniqueAuthorsCount'),
                      ],
                      primaryColor),
                  const SizedBox(height: 16),
                  // 标签统计部分
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

  // 构建统计卡片 (添加主题色参数)
  Widget _buildStatsCard(BuildContext context, String title,
      List<StatsItem> items, Color themeColor) {
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
        const SizedBox(height: 10), // 增大间距
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ), // 标签颜色变淡
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3), // 调整 padding
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1), // 使用主题色透明背景
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
        }).toList(),
        Divider(height: 20, thickness: 0.5, color: Colors.grey[300]), // 分隔线样式
      ],
    );
  }

  // 构建标签统计 (核心修改点)
  Widget _buildTagsStats(
      BuildContext context, List<TagStat> tagStats, Color themeColor) {
    // 排序 (可选)
    tagStats.sort((a, b) => b.count.compareTo(a.count));

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
            // 清除按钮 (逻辑不变，检查 selectedTag 和 onTagSelected)
            if (selectedTag != null && onTagSelected != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTagSelected!(null), // 点击传递 null
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
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
                  // 从 stat.name (String) 转换回 PostTag?
                  final PostTag? currentTagEnum =
                      PostTagsUtils.tagFromString(stat.name);
                  // 判断是否选中
                  final bool isSelected = selectedTag == currentTagEnum;

                  // 使用 PostTagItem 显示
                  return PostTagItem(
                    tagString: stat.name, // 传递字符串给 PostTagItem
                    count: stat.count, // 传递统计数量
                    isSelected: isSelected,
                    onTap: onTagSelected, // 直接传递回调 (PostTagItem 内部会传递 PostTag?)
                    isMini: true, // 右侧面板用 Mini 样式
                  );
                }).toList(),
              ),
        Divider(height: 20, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  // 构建热门帖子区域 (添加主题色参数，修改导航)
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
        const SizedBox(height: 10), // 标题和列表间距
        posts.isEmpty
            ? const EmptyStateWidget(
                // 使用空状态组件
                message: '暂无相关帖子',
                iconData: Icons.article_outlined, // 图标
                iconSize: 40, // 尺寸
              )
            : Column(
                // 如果非空，则构建帖子列表
                children: posts
                    .map((post) => _buildPostItem(context, post, themeColor))
                    .toList(), // 调用 _buildPostItem
              ),
        if (posts.isNotEmpty)
          Divider(
              height: 20, thickness: 0.5, color: Colors.grey[300]), // 有内容才显示分割线
      ],
    );
  }

  // 构建单个帖子项 (添加主题色参数，修改导航)
  Widget _buildPostItem(BuildContext context, Post post, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // 列表项底部外边距
      child: Material(
        // 使用 Material 提供点击效果和圆角
        color: themeColor.withOpacity(0.05), // 用主题色的淡背景
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          // 添加点击效果
          onTap: () {
            // 使用 NavigationUtils 跳转到帖子详情页
            NavigationUtils.pushNamed(context, AppRoutes.postDetail,
                arguments: post.id);
          },
          borderRadius: BorderRadius.circular(8), // InkWell 圆角要匹配 Material
          splashColor: themeColor.withOpacity(0.1), // 水波纹颜色
          highlightColor: themeColor.withOpacity(0.08), // 高亮颜色
          child: Container(
            // 使用 Container 控制内边距
            padding: const EdgeInsets.all(10), // 统一内边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 帖子标题
                Text(
                  post.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87), // 调整标题样式
                ),
                const SizedBox(height: 6), // 标题和统计信息间距
                // 统计信息行
                Row(
                  children: [
                    // 调用辅助方法构建浏览数
                    _buildStatIconText(Icons.visibility_outlined,
                        '${post.viewCount}', Colors.grey[600]!),
                    const SizedBox(width: 12), // 统计项间距
                    // 调用辅助方法构建回复数
                    _buildStatIconText(Icons.chat_bubble_outline,
                        '${post.replyCount}', Colors.grey[600]!),
                    const Spacer(), // 把统计信息推到两边（如果需要的话）
                    // 这里可以考虑加作者或时间等信息
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 辅助构建图标和文本
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
} // ForumRightPanel 类结束

// 辅助类 StatsItem (保持不变)
class StatsItem {
  final String label;
  final String value;
  StatsItem(this.label, this.value);
}
