// lib/widgets/components/screen/forum/global_replies/recent_global_replies.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/post/post.dart';
import '../../../../../services/main/forum/global_replies_service.dart';
import '../../../../../screens/forum/post/post_detail_screen.dart';
import '../../../../../screens/profile/open_profile_screen.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_user_avatar.dart';

class RecentGlobalReplies extends StatefulWidget {
  final int limit;

  const RecentGlobalReplies({Key? key, this.limit = 5}) : super(key: key);

  @override
  _RecentGlobalRepliesState createState() => _RecentGlobalRepliesState();
}

class _RecentGlobalRepliesState extends State<RecentGlobalReplies> {
  final GlobalRepliesService _globalRepliesService = GlobalRepliesService();
  late Stream<List<GlobalReplyItem>> _repliesStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('Initializing RecentGlobalReplies widget with limit: ${widget.limit}');
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    _repliesStream = _globalRepliesService.getRecentGlobalReplies(limit: widget.limit);
  }

  @override
  void dispose() {
    print('Disposing RecentGlobalReplies widget');
    _globalRepliesService.cancelTimer(widget.limit);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop || DeviceUtils.isWeb || DeviceUtils.isTablet(context);

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
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _initStream();
                    });
                  },
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
                return Container(
                  height: 200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // 设置不再加载
              if (_isLoading && snapshot.hasData) {
                _isLoading = false;
              }

              // 发生错误时显示错误信息和重试按钮
              if (snapshot.hasError) {
                return Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('加载失败: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _initStream();
                            });
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final replies = snapshot.data ?? [];
              if (replies.isEmpty) {
                return Container(
                  height: 200,
                  child: const Center(
                    child: Text('暂无回复'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: replies.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) => _buildReplyItem(context, replies[index]),
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
                            builder: (context) => OpenProfileScreen(userId: reply.author['id']),
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
                    _formatTime(reply.createTime),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}