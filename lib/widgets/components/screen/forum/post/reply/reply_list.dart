// lib/widgets/components/screen/forum/post/reply/reply_list.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/forum/forum_service.dart'; // 确认路径
import 'reply_item.dart';

class ReplyList extends StatefulWidget {
  final String postId;

  const ReplyList({
    super.key,
    required this.postId,
  });

  @override
  _ReplyListState createState() => _ReplyListState();
}

class _ReplyListState extends State<ReplyList> {
  final ForumService _forumService = ForumService(); // 获取实例
  late Future<List<Reply>> _repliesFuture; // 用 late 初始化

  @override
  void initState() {
    super.initState();
    _loadReplies(); // 初始加载
  }

  // 加载数据的方法
  void _loadReplies() {
    _repliesFuture = _forumService.fetchReplies(widget.postId);
  }

  // --- 这就是那个回调函数！---
  void _refreshReplies() {
    print("ReplyList: Refresh triggered!");
    if (!mounted) return; // 增加 mounted 检查
    setState(() {
      // 创建一个新的 Future 实例来触发 FutureBuilder 重新执行
      _repliesFuture = _forumService.fetchReplies(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reply>>(
      future: _repliesFuture, // 使用状态变量里的 Future
      builder: (context, snapshot) {
        // ---- 公共的外部容器和标题 ----
        Widget buildContent(Widget child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding( // <<<--- 标题部分 ---
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
                Expanded(child: child), // 内容区域
              ],
            ),
          );
        }
        // ---- 公共的外部容器和标题结束 ----

        // 1. 处理错误状态
        if (snapshot.hasError) {
          debugPrint("Error loading replies: ${snapshot.error}");
          debugPrint("Stack trace: ${snapshot.stackTrace}"); // 加上 stack trace 方便调试
          return buildContent( // 使用公共布局
            InlineErrorWidget(
              errorMessage: "加载回复列表出错: ${snapshot.error}",
              onRetry: _refreshReplies,
            ),
          );
        }

        // 2. 处理正在加载的状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildContent( // 使用公共布局
            Center(
              child: LoadingWidget.inline(message: "正在加载回复..."),
            ),
          );
        }

        // 3. 处理成功获取数据
        final allReplies = snapshot.data ?? []; // 安全获取数据

        // --- UI 构建逻辑 ---
        final topLevelReplies = allReplies
            .where((r) => r.parentId == null || r.parentId!.isEmpty)
            .toList();
        final nestedRepliesMap = groupBy(
          allReplies.where((r) => r.parentId != null && r.parentId!.isNotEmpty),
              (Reply r) => r.parentId!,
        );
        topLevelReplies.sort((a, b) => a.createTime.compareTo(b.createTime));

        // 返回最终的成功状态 UI
        return buildContent( // 使用公共布局
          allReplies.isEmpty
              ? EmptyStateWidget( // <<<--- 空状态 ---
            message: "还没有人占沙发啊",
            iconData: Icons.forum_outlined,
            iconColor: Colors.grey[300],
            iconSize: 32,
          )
              : ListView.builder( // <<<--- 列表 ---
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: topLevelReplies.length,
            itemBuilder: (context, index) {
              final topReply = topLevelReplies[index];
              final children = nestedRepliesMap[topReply.id] ?? [];
              children.sort(
                      (a, b) => a.createTime.compareTo(b.createTime));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReplyItem( // <<<--- 顶层回复 ---
                      reply: topReply,
                      floor: index + 1,
                      postId: widget.postId,
                      onActionSuccess: _refreshReplies, // 传递回调
                    ),
                    if (children.isNotEmpty) // <<<--- 嵌套回复 ---
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
                                floor: 0, // 非顶层楼层号为 0
                                postId: widget.postId,
                                onActionSuccess: _refreshReplies, // 传递回调
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (index < topLevelReplies.length - 1) // <<<--- 分割线 ---
                      const Divider(
                          height: 32, thickness: 0.5, indent: 48),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}