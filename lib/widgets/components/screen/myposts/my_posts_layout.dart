// lib/widgets/components/screen/myposts/my_posts_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_grid_view.dart';

enum StatType {
  views,
  replies,
  likes,
  agrees,
  favorites,
}

class MyPostsLayout extends StatelessWidget {
  final List<Post> posts;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final VoidCallback onAddPost;
  final Future<void> Function(Post post) onDeletePost;
  final void Function(Post post) onEditPost;
  final String? errorMessage;
  final VoidCallback onRetry;
  final User? currentUser;
  final UserInfoService infoService;
  final UserFollowService followService;
  final int totalPostCount;
  final bool isDesktopLayout;
  final double screenWidth;

  static const int desktopStatsFlex = 1;
  static const int desktopGameListFlex = 4;
  static const double desktopDividerWidth = 1.0;

  static const double mobileStatsTopPadding = 12;
  static const double mobileStatsBottomPadding = 8;

  const MyPostsLayout({
    super.key,
    required this.posts,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onAddPost,
    required this.onDeletePost,
    required this.onEditPost,
    this.errorMessage,
    required this.onRetry,
    required this.currentUser,
    required this.infoService,
    required this.followService,
    required this.totalPostCount,
    required this.isDesktopLayout,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && posts.isEmpty && !isLoadingMore) {
      return Center(
        child: FunctionalTextButton(
          label: '加载失败: $errorMessage. 点我重试',
          onPressed: onRetry,
        ),
      );
    }

    if (posts.isEmpty && !isLoadingMore && errorMessage == null) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '你还没有发布过帖子哦',
          iconData: Icons.dynamic_feed_outlined,
          action: FunctionalTextButton(
            onPressed: onAddPost,
            label: '去发第一篇帖子',
          ),
        ),
      );
    }

    return isDesktopLayout
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildMyPostsStatistics(context),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 4,
          child: _buildPostsContent(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            mobileStatsTopPadding,
            12,
            mobileStatsBottomPadding,
          ),
          child: _buildMyPostsStatistics(
            context,
          ),
        ),
        Expanded(
          child: _buildPostsContent(context),
        ),
      ],
    );
  }

  Widget _buildMyPostsStatistics(
    BuildContext context,
  ) {
    if (isDesktopLayout) {
      final cardPadding = const EdgeInsets.all(16);
      final titleStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );

      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('帖子统计', style: titleStyle),
              const SizedBox(height: 16),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.description_outlined,
                  title: '总帖子数',
                  value: totalPostCount.toString(),
                  color: Colors.blueAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.visibility_outlined,
                  title: '总浏览量',
                  value: _calculateTotalStat(StatType.views).toString(),
                  color: Colors.orangeAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.thumb_up_alt_outlined,
                  title: '总点赞数',
                  value: _calculateTotalStat(StatType.likes).toString(),
                  color: Colors.green),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.question_answer_outlined,
                  title: '总回复数',
                  value: _calculateTotalStat(StatType.replies).toString(),
                  color: Colors.purpleAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.add_reaction_outlined,
                  title: '总赞成数',
                  value: _calculateTotalStat(StatType.agrees).toString(),
                  color: Colors.cyan),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.favorite_border,
                  title: '总收藏数',
                  value: _calculateTotalStat(StatType.favorites).toString(),
                  color: Colors.redAccent),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout using ExpansionTile
      final titleStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );
      final totalCountStyle = TextStyle(
        fontSize: 14,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withSafeOpacity(0.85),
      );

      return Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const PageStorageKey<String>('my_posts_stats_expansion_tile'),
          title: Text('帖子统计', style: titleStyle),
          trailing: Text(
            '总帖: $totalPostCount',
            style: totalCountStyle,
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          childrenPadding:
              const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          children: <Widget>[
            _buildStatRow(context, // Total post count is already in trailing
                isDesktop: false,
                icon: Icons.description_outlined,
                title: '总帖子数',
                value: totalPostCount.toString(),
                color: Colors.blueAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.visibility_outlined,
                title: '总浏览量',
                value: _calculateTotalStat(StatType.views).toString(),
                color: Colors.orangeAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.thumb_up_alt_outlined,
                title: '总点赞数',
                value: _calculateTotalStat(StatType.likes).toString(),
                color: Colors.green),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.question_answer_outlined,
                title: '总回复数',
                value: _calculateTotalStat(StatType.replies).toString(),
                color: Colors.purpleAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.add_reaction_outlined,
                title: '总赞成数',
                value: _calculateTotalStat(StatType.agrees).toString(),
                color: Colors.cyan),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.favorite_border,
                title: '总收藏数',
                value: _calculateTotalStat(StatType.favorites).toString(),
                color: Colors.redAccent),
          ],
        ),
      );
    }
  }

  int _calculateTotalStat(StatType type) {
    double totalDouble = 0;

    for (var post in posts) {
      if (type == StatType.views) {
        totalDouble += post.viewCount.toDouble();
      } else if (type == StatType.replies) {
        totalDouble += post.replyCount.toDouble();
      } else if (type == StatType.likes) {
        totalDouble += post.likeCount.toDouble();
      } else if (type == StatType.agrees) {
        totalDouble += post.agreeCount.toDouble();
      } else if (type == StatType.favorites) {
        totalDouble += post.favoriteCount.toDouble();
      }
    }
    return totalDouble.toInt();
  }

  Widget _buildStatRow(BuildContext context,
      {required bool isDesktop,
      required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    final titleTextStyle = TextStyle(
        color:
            Theme.of(context).textTheme.bodyMedium?.color?.withSafeOpacity(0.7),
        fontSize: isDesktop ? 14 : 13);
    final valueTextStyle = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isDesktop ? 16 : 15,
        color: Theme.of(context).textTheme.bodyLarge?.color);
    final iconSize = isDesktop ? 22.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withSafeOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleTextStyle),
                const SizedBox(height: 2),
                Text(value, style: valueTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsContent(
    BuildContext context,
  ) {
    double availableWidth;
    if (isDesktopLayout) {
      availableWidth = (screenWidth - desktopDividerWidth) *
          desktopGameListFlex /
          (desktopStatsFlex + desktopGameListFlex);
    } else {
      availableWidth = screenWidth;
    }
    return PostGridView(
      posts: posts,
      availableWidth: availableWidth,
      isDesktopLayout: isDesktopLayout,
      currentUser: currentUser,
      infoService: infoService,
      followService: followService,
      scrollController: scrollController,
      isLoading: isLoadingMore,
      hasMoreData: hasMore,
      onDeleteAction: onDeletePost,
      onEditAction: onEditPost,
    );
  }
}
