// lib/widgets/components/screen/home/section/home_hot_posts.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

class HomeHotPosts extends StatelessWidget {
  final Stream<List<Post>>? postsStream;

  // 构造函数保持不变
  HomeHotPosts({Key? key, required this.postsStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 整体结构和样式保持不变
    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏保持不变
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '热门帖子',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  Spacer(),
                  // InkWell(...) // 更多按钮（如果需要）
                ],
              ),
            ),
            SizedBox(height: 16),

            // --- 帖子列表 StreamBuilder ---
            StreamBuilder<List<Post>>(
              stream: postsStream,
              builder: (context, snapshot) {
                // 加载、错误、空状态处理保持不变
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: LoadingWidget.inline(message: '加载热门帖子...', size: 24),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: InlineErrorWidget( // 确保这个 Widget 存在或替换
                      errorMessage: '加载失败: ${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: EmptyStateWidget(
                      message: '暂无热门帖子',
                      iconData: Icons.forum_outlined,
                      iconSize: 30,
                      iconColor: Colors.grey[400],
                    ),
                  );
                }

                // --- 有数据，显示列表 ---
                final posts = snapshot.data!;
                final displayPosts = posts.take(5).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: displayPosts.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 20,
                    thickness: 1,
                    indent: 16, // 左侧缩进调整 (因为头像现在在UserInfoBadge里)
                    endIndent: 16,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  itemBuilder: (context, index) {
                    final post = displayPosts[index];
                    // --- ↓↓↓ 调用修改后的列表项构建方法 ↓↓↓ ---
                    return _buildPostListItem(context, post);
                    // --- ↑↑↑ 结束调用 ↑↑↑ ---
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ★★★ 修改后的列表项构建方法 (使用 UserInfoBadge) ★★★ ---
  Widget _buildPostListItem(BuildContext context, Post post) {

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        NavigationUtils.pushNamed(
          context,
          AppRoutes.postDetail,
          arguments: post.id,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0), // 微调垂直内边距
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 改为垂直居中对齐可能更好看
          children: [
            // --- 左侧/中间：包含标题、作者信息和时间 ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 帖子标题
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0), // 微调标题左边距
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[850],
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8), // 标题和下方信息的间距

                  // 作者信息 (UserInfoBadge) 和 发布时间
                  Row(
                    children: [
                      // --- ↓↓↓ 使用 UserInfoBadge 显示作者信息 ↓↓↓ ---
                      UserInfoBadge(
                        userId: post.authorId, // 传递 authorId
                        mini: true,             // 使用迷你模式
                        showLevel: false,       // 不显示等级
                        showFollowButton: false,// 不显示关注按钮
                        // 可选：设置内边距为0，如果默认有内边距的话
                        padding: EdgeInsets.zero,
                      ),
                      // --- ↑↑↑ 结束使用 UserInfoBadge ↑↑↑ ---

                      SizedBox(width: 8), // Badge 和时间的间距

                      // 发布时间 (用 Flexible 防止极端情况下的溢出)
                      Flexible(
                        child: Text(
                          '· ${DateTimeFormatter.formatTimeAgo(post.createTime)}', // 显示相对时间
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12, // 时间字号调小一点
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16), // 中间内容和右侧统计的间距

            // --- 右侧：帖子统计数据 (保持不变) ---
            _buildPostStats(context, post),
          ],
        ),
      ),
    );
  }
  // --- ★★★ 结束修改 ★★★ ---


  // --- 构建帖子统计部分的方法 (保持不变) ---
  Widget _buildPostStats(BuildContext context, Post post) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem(context, Icons.mode_comment_outlined, post.replyCount, Colors.blueGrey[400]),
        SizedBox(height: 8),
        _buildStatItem(context, Icons.thumb_up_alt_outlined, post.likeCount, Colors.pink[300]),
        SizedBox(height: 8),
        _buildStatItem(context, Icons.bookmark_border_outlined, post.favoriteCount, Colors.teal[400]),
      ],
    );
  }

  // --- 构建单个统计项的方法 (保持不变) ---
  Widget _buildStatItem(BuildContext context, IconData icon, int count, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.grey[500],
          size: 16,
        ),
        SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}