// lib/widgets/components/screen/home/section/home_hot_posts.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class HomeHotPosts extends StatelessWidget {
  final List<Post>? posts;
  final User? currentUser;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const HomeHotPosts({
    super.key,
    required this.posts,
    required this.currentUser,
    required this.infoProvider,
    required this.followService,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withSafeOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 1))),
              child: Row(
                children: [
                  Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(3))),
                  SizedBox(width: 12),
                  Text('热门帖子',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900])),
                  Spacer(),
                  // 可选：如果需要更多按钮
                  // InkWell(...)
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildPostListArea(
                context), // 传递 context 和 providers
          ],
        ),
      ),
    );
  }

  Widget _buildPostListArea(
    BuildContext context,
  ) {
    if (isLoading && posts == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget.inline(message: '加载热门帖子...', size: 24),
      );
    }

    if (errorMessage != null && posts == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: InlineErrorWidget(
          errorMessage: errorMessage!,
          onRetry: onRetry,
        ),
      );
    }

    final displayPosts = posts ?? [];
    if (!isLoading && displayPosts.isEmpty) {
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

    final itemsToShow = displayPosts.take(5).toList();

    return Stack(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: itemsToShow.length,
          separatorBuilder: (_, __) => Divider(
              height: 20,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.withSafeOpacity(0.15)),
          itemBuilder: (ctx, index) {
            // 使用 ctx
            final post = itemsToShow[index];
            return _buildPostListItem(
                ctx, post); // 传递 ctx 和 authProvider
          },
        ),
        if (isLoading && displayPosts.isNotEmpty)
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5),
            child: Center(child: LoadingWidget.inline(size: 30)),
          )),
      ],
    );
  }

  Widget _buildPostListItem(
    BuildContext context, // 传入 context
    Post post,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        NavigationUtils.pushNamed(
          context, // 使用这里的 context
          AppRoutes.postDetail,
          arguments: post.id,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(post.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[850],
                            fontSize: 15,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      UserInfoBadge(
                          followService: followService,
                          infoProvider: infoProvider,
                          currentUser: currentUser,
                          targetUserId: post.authorId,
                          mini: true,
                          showLevel: false,
                          showFollowButton: false,
                          padding: EdgeInsets.zero),
                      SizedBox(width: 8),
                      Flexible(
                          child: Text(
                              '· ${DateTimeFormatter.formatTimeAgo(post.createTime)}',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            _buildPostStats(post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStats(Post post) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem(
            Icons.mode_comment_outlined, post.replyCount, Colors.blueGrey[400]),
        SizedBox(height: 8),
        _buildStatItem(
            Icons.thumb_up_alt_outlined, post.likeCount, Colors.pink[300]),
        SizedBox(height: 8),
        _buildStatItem(Icons.bookmark_border_outlined, post.favoriteCount,
            Colors.teal[400]),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int count, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor ?? Colors.grey[500], size: 16),
        SizedBox(width: 5),
        Text('$count',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
