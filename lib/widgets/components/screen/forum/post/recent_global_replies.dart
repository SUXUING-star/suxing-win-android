// lib/widgets/components/screen/forum/global_replies/recent_global_replies.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/global_reply_item.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../screens/forum/post/post_detail_screen.dart';
import '../../../../../screens/profile/open_profile_screen.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_user_avatar.dart';

class RecentGlobalReplies extends StatefulWidget {
  final int limit;

  const RecentGlobalReplies({super.key, this.limit = 5});

  @override
  _RecentGlobalRepliesState createState() => _RecentGlobalRepliesState();
}

class _RecentGlobalRepliesState extends State<RecentGlobalReplies> {
  final ForumService _forumService = ForumService();
  late Stream<List<GlobalReplyItem>> _repliesStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print(
        'Initializing RecentGlobalReplies widget with limit: ${widget.limit}');
    // 直接在 initState 中获取 Stream
    _repliesStream = _forumService.getRecentGlobalReplies(limit: widget.limit);
  }

  @override
  void dispose() {
    print('Disposing RecentGlobalReplies widget for limit: ${widget.limit}');
    super.dispose();
  }

  // 主动刷新的方法
  void _handleRefresh() {}

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
                // 添加刷新按钮
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                  // 调用新的刷新方法
                  onPressed: _handleRefresh, // <--- 修改这里
                  tooltip: '刷新最新活跃',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<List<GlobalReplyItem>>(
            stream: _repliesStream,
            builder: (context, snapshot) {
              // 异步操作开始但未完成时
              if (_isLoading && !snapshot.hasData) {
                return SizedBox(
                    height: 200,
                    child: LoadingWidget.inline(
                      size: 12,
                    ));
              }

              // 设置不再加载
              if (_isLoading && snapshot.hasData) {
                _isLoading = false;
              }

              // 发生错误时显示错误信息和重试按钮
              if (snapshot.hasError) {
                return InlineErrorWidget(
                  onRetry: _handleRefresh,
                  errorMessage: "发生错误",
                );
              }

              final replies = snapshot.data ?? [];
              if (replies.isEmpty) {
                return EmptyStateWidget(
                    message: "暂无回复", iconData: Icons.maps_ugc_outlined);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: replies.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) =>
                    _buildReplyItem(context, replies[index]),
              );
            },
          ),
        ],
      ),
    );
  }

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
                  // 使用安全头像组件
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
