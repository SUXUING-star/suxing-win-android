// lib/widgets/components/screen/forum/post/reply/reply_list.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 引入 LoadingWidget
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import 'reply_item.dart';

class ReplyList extends StatefulWidget {
  final String postId;
  final VoidCallback? onReplyChanged;

  const ReplyList({
    super.key,
    required this.postId,
    this.onReplyChanged,
  });

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
        // 1. 优先处理错误状态
        if (snapshot.hasError) {
          // 最好能记录一下具体的错误信息，方便调试
          debugPrint("Error loading replies: ${snapshot.error}");
          debugPrint("Stack trace: ${snapshot.stackTrace}");
          return InlineErrorWidget(
            errorMessage: "加载回复列表出错", // 可以更具体一点
            onRetry: () {
              // 如果你的 _forumService.getReplies 支持重试或重新获取，可以在这里调用
              setState(() {}); // 简单地触发重建以重新监听流
            },
          );
        }

        // 2. 处理正在加载的状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 在卡片内部显示加载指示器，保持UI结构一致性
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 保持标题和分割线可见
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
                // 在列表区域显示加载指示器
                Expanded(
                  child: Center(
                    // 使用 LoadingWidget 或标准的 CircularProgressIndicator
                    child: LoadingWidget.inline(message: "正在加载回复..."),
                    // 或者: child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          );
        }

        // 3. 处理没有数据的情况（流已激活或完成，但数据为空或null）
        //    注意：Firestore Streams 通常在没有文档时会返回一个空列表 `[]`，而不是 null。
        //    所以 `snapshot.data == null` 的情况较少见，但加上更保险。
        //    `snapshot.data!.isEmpty` 是更常见的空状态判断。
        final allReplies = snapshot.data ?? []; // 安全获取数据，如果为null则视为空列表

        // --- UI 构建逻辑 (保持不变) ---
        // 使用 allReplies 来构建列表，如果为空，则显示 EmptyStateWidget

        final topLevelReplies = allReplies
            .where((r) => r.parentId == null || r.parentId!.isEmpty)
            .toList();
        final nestedRepliesMap = groupBy(
          allReplies.where((r) => r.parentId != null && r.parentId!.isNotEmpty),
              (Reply r) => r.parentId!,
        );
        topLevelReplies.sort((a, b) => a.createTime.compareTo(b.createTime));

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: allReplies.isEmpty
                    ? EmptyStateWidget(
                  message: "还没有人占沙发啊",
                  iconData: Icons.forum_outlined,
                  iconColor: Colors.grey[300],
                  iconSize: 32,
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
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
                          ReplyItem(
                            reply: topReply,
                            floor: index + 1,
                            onReplyChanged: widget.onReplyChanged,
                            postId: widget.postId,
                          ),
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
                                      floor: 0,
                                      onReplyChanged:
                                      widget.onReplyChanged,
                                      postId: widget.postId,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
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