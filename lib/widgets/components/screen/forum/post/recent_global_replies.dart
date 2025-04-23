// lib/widgets/components/screen/forum/global_replies/recent_global_replies.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/global_reply_item.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 确认 ErrorWidget 改名为 InlineErrorWidget 或反之
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../screens/forum/post/post_detail_screen.dart';
import '../../../../../screens/profile/open_profile_screen.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/badges/safe_user_avatar.dart';

class RecentGlobalReplies extends StatefulWidget {
  final int limit;

  const RecentGlobalReplies({super.key, this.limit = 5});

  @override
  _RecentGlobalRepliesState createState() => _RecentGlobalRepliesState();
}

class _RecentGlobalRepliesState extends State<RecentGlobalReplies> {
  final ForumService _forumService = ForumService();
  // 把 Stream 换成 Future
  Future<List<GlobalReplyItem>>? _repliesFuture;
  // 不需要 _isLoading 了，FutureBuilder 自己会管加载状态

  @override
  void initState() {
    super.initState();
    print(
        'Initializing RecentGlobalReplies widget with limit: ${widget.limit}');
    // 初始化时调用 Future 方法
    _loadReplies();
  }

  // 封装加载逻辑，方便复用
  void _loadReplies() {
    // 注意这里直接赋值给 Future 变量，不需要 setState
    _repliesFuture = _forumService.fetchRecentGlobalRepliesOnce(limit: widget.limit);
  }

  @override
  void dispose() {
    print('Disposing RecentGlobalReplies widget for limit: ${widget.limit}');
    // Future 不需要像 Stream 那样手动关闭
    super.dispose();
  }

  // 主动刷新的方法
  void _handleRefresh() {
    print("Refreshing RecentGlobalReplies...");
    // 调用强制刷新方法，并用 setState 更新 Future，让 FutureBuilder 重新构建
    setState(() {
      _repliesFuture = _forumService.forceRefreshRecentGlobalReplies(limit: widget.limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop ||
        DeviceUtils.isWeb ||
        DeviceUtils.isTablet(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '最新活跃',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                  onPressed: _handleRefresh, // 刷新按钮现在能用了
                  tooltip: '刷新最新活跃',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 把 StreamBuilder 换成 FutureBuilder
          FutureBuilder<List<GlobalReplyItem>>(
            future: _repliesFuture, // 绑定 Future
            builder: (context, snapshot) {
              // 1. 处理加载状态
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                    height: 200, // 给个固定高度防止跳动
                    child: LoadingWidget.inline(
                      size: 12,
                    ));
              }

              // 2. 处理错误状态 (加载完成后)
              if (snapshot.hasError) {
                print("Error loading replies: ${snapshot.error}"); // 打印错误方便调试
                // 确保你的 InlineErrorWidget 存在并且签名匹配
                return InlineErrorWidget( // 或者叫 ErrorWidget，看你实际命名
                  onRetry: _handleRefresh, // 提供重试回调
                  errorMessage: "加载失败: ${snapshot.error}", // 显示错误信息
                );
              }

              // 3. 处理成功状态 (加载完成后且无错误)
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final replies = snapshot.data ?? []; // 获取数据
                if (replies.isEmpty) {
                  // 数据为空
                  return const EmptyStateWidget(
                      message: "暂无回复", iconData: Icons.maps_ugc_outlined);
                }

                // 数据正常，构建列表
                return ListView.separated(
                  shrinkWrap: true, // 在 Column 里需要
                  physics: const NeverScrollableScrollPhysics(), // 在 Column 里需要
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) =>
                      _buildReplyItem(context, replies[index]),
                );
              }

              // 4. 其他情况 (理论上 FutureBuilder 主要关注 waiting 和 done)
              // 可以返回一个初始占位符或者加载指示器
              return SizedBox(
                  height: 200,
                  child: LoadingWidget.inline(size: 12));
            },
          ),
        ],
      ),
    );
  }

  // _buildReplyItem 方法保持不变
  Widget _buildReplyItem(BuildContext context, GlobalReplyItem reply) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          NavigationUtils.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: reply.postId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeUserAvatar(
                    userId: reply.author['id'],
                    avatarUrl: reply.author['avatar'],
                    username: reply.author['username'] ?? '未知用户',
                    radius: 14,
                    enableNavigation: true,
                    onTap: () {
                      if (reply.author['id'] != null) {
                        NavigationUtils.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OpenProfileScreen(userId: reply.author['id']),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.author['username'] ?? '未知用户',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '回复了: ${reply.postTitle}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateTimeFormatter.formatTimeAgo(reply.createTime),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reply.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}