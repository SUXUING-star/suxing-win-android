// lib/widgets/components/screen/home/section/home_hot_posts.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class HomeHotPosts extends StatelessWidget {
  final List<Post>? posts;
  final User? currentUser;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final double screenWidth;
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
    required this.screenWidth,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
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
                const SizedBox(width: 12),
                Text(
                  '热门帖子',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPostListArea(context), // 传递 context 和 providers
        ],
      ),
    );
  }

  Widget _buildPostListArea(BuildContext context) {
    if (isLoading && posts == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget(
          message: '加载热门帖子...',
          size: 24,
        ),
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
        // 使用封装好的 AnimatedListView
        AnimatedListView<Post>(
          listKey: const ValueKey('home_hot_posts_list'),
          items: itemsToShow,
          shrinkWrap: true, // 关键：使其在 Column 内正常工作
          physics: const NeverScrollableScrollPhysics(), // 关键：禁用其内部滚动
          padding: EdgeInsets.zero, // 外部已有 padding
          itemBuilder: (ctx, index, post) {
            return Column(
              children: [
                _buildPostListItem(ctx, post),
                if (index < itemsToShow.length - 1)
                  Divider(
                    height: 20,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.withSafeOpacity(0.15),
                  ),
              ],
            );
          },
        ),
        if (isLoading && displayPosts.isNotEmpty)
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5),
            child: const LoadingWidget(size: 30),
          )),
      ],
    );
  }

  Widget _buildPostListItem(
    BuildContext context, // 传入 context
    Post post,
  ) {
    return BasePostCard(
      followService: followService,
      infoProvider: infoProvider,
      availableWidth: screenWidth,
      post: post,
      currentUser: currentUser,
    );
  }
}
