// lib/widgets/components/screen/forum/post/reply/reply_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import 'reply_item.dart';

class ReplyList extends StatefulWidget {
  final String postId;
  final VoidCallback? onReplyChanged;

  const ReplyList({
    Key? key,
    required this.postId,
    this.onReplyChanged,
  }) : super(key: key);

  @override
  _ReplyListState createState() => _ReplyListState();
}

class _ReplyListState extends State<ReplyList> {
  final ForumService _forumService = ForumService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reply>>(
      stream: _forumService.getReplies(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allReplies = snapshot.data!;
        final topLevelReplies = allReplies
            .where((r) => r.parentId == null || r.parentId!.isEmpty)
            .toList();
        final nestedRepliesMap = groupBy(
          allReplies.where((r) => r.parentId != null && r.parentId!.isNotEmpty),
          (Reply r) => r.parentId!,
        );
        topLevelReplies.sort((a, b) => a.createTime.compareTo(b.createTime));

        // --- 保持原来的白色背景卡片结构 ---
        return Container(
          // margin: const EdgeInsets.symmetric(vertical: 8.0), // 外边距由 PostDetail 控制比较好
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 全部回复标题 (保持不变) ---
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '全部回复',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),

              // --- 回复列表或无回复时的占位符 ---
              // --- 核心改动：重新使用 Expanded 包裹 ListView ---
              Expanded(
                child: allReplies
                        .isEmpty // 使用 allReplies 还是 topLevelReplies 判断？应该用 allReplies
                    ? EmptyStateWidget(
                        message: "还没有人占沙发啊",
                        iconData: Icons.forum_outlined,
                        iconColor: Colors.grey[300],
                        iconSize: 32,
                      ) // 如果总回复为空
                    : ListView.builder(
                        // 不再是 ListView.separated
                        padding: const EdgeInsets.only(
                            top: 16, bottom: 16), // 列表上下内边距
                        // --- 移除 shrinkWrap 和 physics ---
                        // shrinkWrap: true,
                        // physics: const NeverScrollableScrollPhysics(),
                        itemCount: topLevelReplies.length,
                        itemBuilder: (context, index) {
                          final topReply = topLevelReplies[index];
                          final children = nestedRepliesMap[topReply.id] ?? [];
                          children.sort(
                              (a, b) => a.createTime.compareTo(b.createTime));

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 渲染顶级回复
                                ReplyItem(
                                  reply: topReply,
                                  floor: index + 1,
                                  onReplyChanged: widget.onReplyChanged,
                                  postId: widget.postId,
                                ),
                                // 渲染嵌套回复
                                if (children.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 32.0, top: 8.0, bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: children.map((nestedReply) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: ReplyItem(
                                            reply: nestedReply,
                                            floor: 0, // 楼中楼不显示楼层
                                            onReplyChanged:
                                                widget.onReplyChanged,
                                            postId: widget.postId,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                // 手动添加分隔线
                                if (index < topLevelReplies.length - 1)
                                  const Divider(
                                      height: 32, thickness: 0.5, indent: 48),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
