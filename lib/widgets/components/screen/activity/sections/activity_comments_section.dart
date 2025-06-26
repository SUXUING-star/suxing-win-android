// lib/widgets/components/screen/activity/sections/activity_comments_section.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity_comment.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class ActivityCommentsSection extends StatelessWidget {
  final String activityId;
  final UserFollowService userFollowService;
  final UserInfoService userInfoService;
  final InputStateService inputStateService;
  final User? currentUser;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final Function(String) onAddComment;
  final FutureOr<void> Function(ActivityComment comment) onCommentDeleted;
  final Future<bool>  Function(ActivityComment comment) onCommentLike;
  final Future<bool>  Function(ActivityComment comment) onCommentUnLike;
  final bool isDesktopLayout;

  const ActivityCommentsSection({
    super.key,
    required this.activityId,
    required this.userFollowService,
    required this.userInfoService,
    required this.inputStateService,
    required this.currentUser,
    required this.comments,
    required this.isLoadingComments,
    required this.onAddComment,
    required this.onCommentDeleted,
    required this.onCommentLike,
    required this.onCommentUnLike,
    required this.isDesktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktopLayout ? 20 : 16);

    final commentInput = Padding(
      padding: EdgeInsets.only(bottom: isDesktopLayout ? 16 : 0), // 调整padding
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start, // 移除以使分割线居中
        children: [
          if (!isDesktopLayout) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10)
          ],
          ActivityCommentInput(
            inputStateService: inputStateService,
            currentUser: currentUser,
            onSubmit: onAddComment,
            isAlternate: false,
            hintText: '添加你的看法...',
          ),
          if (isDesktopLayout) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16)
          ], // 输入框和列表间的分割线
        ],
      ),
    );

    // --- 评论列表内容 Widget (ListView.builder本身) ---
    Widget commentListContent;
    if (isLoadingComments && comments.isEmpty) {
      commentListContent = Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0), // 增加Loading时的垂直间距
          child: const LoadingWidget(message: "正在加载评论...") // 居中显示
          );
    } else if (comments.isEmpty && !isLoadingComments) {
      commentListContent = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0), // 增加Empty时的垂直间距
        child: Center(
          // 居中显示
          child: EmptyStateWidget(
            message: '暂无评论，发表第一条评论吧',
            iconData: Icons.chat_bubble_outline, // 换个图标试试
          ),
        ),
      );
    } else {
      // 这里的 ListView 不再需要外部滚动控制，因为它会在 ConstrainedBox + SingleChildScrollView 内部
      commentListContent = ListView.builder(
        shrinkWrap: true, // 在 SingleChildScrollView 内部通常需要
        physics:
            const NeverScrollableScrollPhysics(), // 在 SingleChildScrollView 内部不需要自己的滚动
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final comment = comments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0), // 评论项之间的间距增大一些
            child: ActivityCommentItem(
              userFollowService: userFollowService,
              userInfoService: userInfoService,
              comment: comment,
              currentUser: currentUser,
              activityId: activityId,
              isAlternate: false,
              onLike: () => onCommentLike(comment),
              onUnlike: () => onCommentUnLike(comment),
              onCommentDeleted: () => onCommentDeleted(comment),
            ),
          );
        },
      );
    }

    // --- 构建桌面端的评论列表区域 (带滚动约束) ---
    Widget buildDesktopCommentListArea() {
      // 只有在有评论或者正在加载时才显示滚动区域
      if ((comments.isNotEmpty || isLoadingComments)) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 500, // *** 关键：限制最大高度 ***
          ),
          child: SingleChildScrollView(
            child: commentListContent,
          ),
        );
      } else {
        // 如果没评论也不在加载（即空状态），直接显示空状态内容，不需要滚动和高度限制
        return commentListContent;
      }
    }

    // --- 根据 isDesktop 决定输入框和列表的顺序 ---
    List<Widget> childrenInOrder = isDesktopLayout
        ? [
            commentInput, // 输入框 (包含其下的分割线)
            // --- 桌面评论列表区域 ---
            buildDesktopCommentListArea(),
          ]
        : [
            // --- 移动端列表内容直接放这里 ---
            commentListContent,
            // --- 移动端输入框 (包含其上的分割线) ---
            commentInput,
          ];

    // --- 使用 Container 实现卡片样式 ---
    return Container(
      padding: sectionPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 让内容撑满卡片宽度
        mainAxisSize: MainAxisSize.min, // *** 关键：让卡片高度自适应内容 ***
        children: childrenInOrder,
      ),
    );
  }
}
