// lib/widgets/components/screen/game/comment/comments/game_comment_list.dart

/// 该文件定义了 GameCommentList 组件，用于显示游戏评论列表。
/// GameCommentList 负责渲染评论项并传递相关操作回调。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/models/game/game_comment.dart';
import 'game_comment_item.dart';

/// `GameCommentList` 类：显示游戏评论列表的 StatelessWidget。
///
/// 该组件负责渲染评论列表，并为每个评论项传递必要的服务和回调函数。
class GameCommentList extends StatelessWidget {
  final User? currentUser; // 当前登录用户
  final AuthProvider authProvider; // 认证 Provider
  final UserInfoService infoService; // 用户信息服务
  final UserFollowService followService; // 用户关注服务
  final InputStateService inputStateService; // 输入状态服务
  final List<GameComment> comments; // 评论列表数据
  final Future<void> Function(GameComment comment, String content)
      onUpdateComment; // 更新评论的回调函数
  final Future<void> Function(GameComment comment) onDeleteComment; // 删除评论的回调函数
  final Future<void> Function(String content, String parentId)
      onAddReply; // 添加回复的回调函数
  final Set<String> deletingCommentIds; // 正在删除的评论ID集合
  final Set<String> updatingCommentIds; // 正在更新的评论ID集合

  /// 构造函数。
  const GameCommentList({
    super.key,
    required this.currentUser,
    required this.authProvider,
    required this.infoService,
    required this.followService,
    required this.inputStateService,
    required this.comments,
    required this.onUpdateComment,
    required this.onDeleteComment,
    required this.onAddReply,
    required this.deletingCommentIds,
    required this.updatingCommentIds,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      // 评论列表为空时显示空状态组件
      return const EmptyStateWidget(
          message: '暂无评论', iconData: Icons.maps_ugc_outlined);
    }

    return StreamBuilder<User?>(
      stream: authProvider.currentUserStream, // 监听当前用户 Stream
      initialData: authProvider.currentUser, // 初始用户数据
      builder: (context, authSnapshot) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 0), // 底部内边距
          shrinkWrap: true, // 根据内容收缩列表高度
          physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
          itemCount: comments.length, // 评论数量
          itemBuilder: (context, index) {
            final comment = comments[index]; // 当前评论对象
            return GameCommentItem(
              key: ValueKey(comment.id), // 为每个评论项设置唯一键
              currentUser: authSnapshot.data, // 传递当前用户数据
              authProvider: authProvider, // 传递认证 Provider
              comment: comment, // 传递评论数据
              infoService: infoService, // 传递用户信息服务
              inputStateService: inputStateService, // 传递输入状态服务
              followService: followService, // 传递用户关注服务
              onUpdateComment: onUpdateComment, // 传递更新评论回调
              onDeleteComment: onDeleteComment, // 传递删除评论回调
              onAddReply: onAddReply, // 传递添加回复回调
              isDeleting: deletingCommentIds.contains(comment.id), // 传递删除状态
              isUpdating: updatingCommentIds.contains(comment.id), // 传递更新状态
            );
          },
        );
      },
    );
  }
}
