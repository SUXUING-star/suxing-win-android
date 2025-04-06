import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入依赖 (需要 ActivityComment)
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart'; // 导入依赖
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 导入依赖

class ActivityCommentsSection extends StatelessWidget { // 公共类
  final String activityId;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final Function(String) onAddComment;
  final Function(String) onCommentDeleted;
  final Function(ActivityComment) onCommentLikeToggled;
  final bool isDesktop;

  const ActivityCommentsSection({ // 构造函数
    Key? key,
    required this.activityId,
    required this.comments,
    required this.isLoadingComments,
    required this.onAddComment,
    required this.onCommentDeleted,
    required this.onCommentLikeToggled,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 评论输入框 Widget
    final commentInput = Padding(
      padding: EdgeInsets.only(
          top: isDesktop ? 0 : 16,
          bottom: isDesktop ? 16 : 0
      ),
      child: Column(
        children: [
          if(!isDesktop) ...[const SizedBox(height: 10), const Divider(), const SizedBox(height: 10)],
          ActivityCommentInput(
            onSubmit: onAddComment,
            isAlternate: false,
            hintText: '添加你的看法...',
          ),
          if(isDesktop) ...[const SizedBox(height: 20), const Divider(), const SizedBox(height: 16)],
        ],
      ),
    );

    // 评论列表 Widget
    Widget commentList;
    if (isLoadingComments && comments.isEmpty) {
      commentList = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (comments.isEmpty && !isLoadingComments) {
      commentList = EmptyStateWidget(
        message: '暂无评论，发表第一条评论吧',
        iconData: Icons.chat_outlined,
      );
    } else {
      commentList = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: comments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ActivityCommentItem(
              comment: comments[index],
              activityId: activityId,
              isAlternate: false,
              onLikeToggled: onCommentLikeToggled,
              onCommentDeleted: onCommentDeleted,
            ),
          );
        },
      );
    }

    // 根据 isDesktop 决定输入框和列表的顺序
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isDesktop
          ? [
        commentInput,
        if (comments.isNotEmpty || isLoadingComments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text("评论列表", style: Theme.of(context).textTheme.titleMedium),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: commentList,
        ),
      ]
          : [
        commentList,
        commentInput,
      ],
    );
  }
}