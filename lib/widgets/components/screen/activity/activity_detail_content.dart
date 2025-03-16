// lib/widgets/components/screen/activity/activity_detail_content.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ActivityDetailContent extends StatelessWidget {
  final UserActivity activity;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final ScrollController scrollController;
  final Function(String) onAddComment;
  final Function(String) onCommentDeleted;
  final Function(ActivityComment) onCommentLikeToggled;
  final VoidCallback onActivityUpdated;

  const ActivityDetailContent({
    Key? key,
    required this.activity,
    required this.comments,
    required this.isLoadingComments,
    required this.scrollController,
    required this.onAddComment,
    required this.onCommentDeleted,
    required this.onCommentLikeToggled,
    required this.onActivityUpdated,
  }) : super(key: key);

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // 活动卡片和评论区
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 活动卡片 - 不需要自己的背景，因为已经在Card里面了
              ActivityCard(
                activity: activity,
                isAlternate: false,
                isInDetailView: true,
                onUpdated: onActivityUpdated,
                hasOwnBackground: false, // 不需要自己的背景
              ),

              const SizedBox(height: 16),

              // 评论区标题
              Row(
                children: [
                  const Icon(Icons.comment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '评论 (${activity.commentsCount})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Divider(),

              // 评论列表
              if (isLoadingComments && comments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      '暂无评论，发表第一条评论吧',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                AnimationLimiter(
                  child: Column(
                    children: List.generate(
                      comments.length,
                          (index) => AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: ActivityCommentItem(
                              comment: comments[index],
                              activityId: activity.id,
                              isAlternate: false,
                              onLikeToggled: onCommentLikeToggled,
                              onCommentDeleted: onCommentDeleted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 底部留白，确保评论输入框不会挡住内容
              const SizedBox(height: 100),
            ],
          ),
        ),

        // 评论输入框 (固定在底部)
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.all(8.0),
          child: ActivityCommentInput(
            onSubmit: onAddComment,
            isAlternate: false,
            hintText: '添加评论...',
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：活动卡片
          Expanded(
            flex: 5,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ActivityCard(
                  activity: activity,
                  isAlternate: false,
                  isInDetailView: true,
                  onUpdated: onActivityUpdated,
                  hasOwnBackground: false, // 不需要自己的背景
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // 右侧：评论区
          Expanded(
            flex: 4,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 评论区标题
                    Row(
                      children: [
                        const Icon(Icons.comment, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '评论 (${activity.commentsCount})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // 评论输入框
                    ActivityCommentInput(
                      onSubmit: onAddComment,
                      isAlternate: false,
                      hintText: '添加评论...',
                    ),

                    const SizedBox(height: 16),

                    // 评论列表
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 600, // 限制最大高度
                      ),
                      child: isLoadingComments && comments.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                          : comments.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '暂无评论，发表第一条评论吧',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return ActivityCommentItem(
                            comment: comments[index],
                            activityId: activity.id,
                            isAlternate: false,
                            onLikeToggled: onCommentLikeToggled,
                            onCommentDeleted: onCommentDeleted,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面端布局
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context);
  }
}