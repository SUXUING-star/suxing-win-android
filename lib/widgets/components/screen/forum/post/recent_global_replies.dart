// lib/widgets/components/screen/forum/post/recent_global_replies.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/global_post_reply_item.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class RecentGlobalReplies extends StatefulWidget {
  final int limit;
  final Post post;
  final User? currentUser;
  final PostService postService;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;

  const RecentGlobalReplies({
    super.key,
    this.limit = 5,
    required this.post,
    required this.infoProvider,
    required this.followService,
    required this.postService,
    required this.currentUser,
  });

  @override
  _RecentGlobalRepliesState createState() => _RecentGlobalRepliesState();
}

class _RecentGlobalRepliesState extends State<RecentGlobalReplies> {
  // 把 Stream 换成 Future
  Future<List<GlobalPostReplyItem>>? _repliesFuture;
  User? _currentUser;
  bool _isRefreshing = false; // 标记是否正在执行刷新操作
  DateTime? _lastRefreshTime; // 上次刷新的时间戳
  // 定义最小刷新间隔 (例如：3秒)
  static const Duration _minRefreshInterval = Duration(seconds: 15);

  bool _hasInit = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  @override
  void didUpdateWidget(covariant RecentGlobalReplies oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUser != widget.currentUser ||
        oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInit) {
      _hasInit = true;
    }
    if (_hasInit) {
      _loadReplies();
    }
  }

  // 封装加载逻辑，方便复用
  void _loadReplies() {
    // 注意这里直接赋值给 Future 变量，不需要 setState
    _repliesFuture =
        widget.postService.getRecentGlobalReplies(limit: widget.limit);
  }

  @override
  void dispose() {
    // Future 不需要像 Stream 那样手动关闭
    super.dispose();
  }

  // 主动刷新的方法
  // --- 主动刷新的方法 (加入节流逻辑) ---
  void _handleRefresh({bool forceRefresh = false}) {
    // 1. 防止重复触发：如果已经在刷新中，直接返回
    if (_isRefreshing) {
      return;
    }

    final now = DateTime.now();

    // 2. 检查时间间隔：判断离上次刷新是否足够久
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minRefreshInterval) {
      AppSnackBar.showWarning(context, '操作太快了，请稍后再试');

      return; // 时间不够，直接返回
    }

    // 3. 时间足够 或 首次刷新 -> 执行刷新逻辑
    if (mounted) {
      setState(() {
        _isRefreshing = true; // 开始刷新
        _lastRefreshTime = now; // 更新上次刷新的时间

        // 调用实际的刷新方法
        _repliesFuture = widget.postService.getRecentGlobalReplies(
          limit: widget.limit,
          forceRefresh: forceRefresh,
        );
      });
    }

    // 4. 刷新结束后清除状态 (使用 Future 的 whenComplete 回调)
    //    注意：这里假设 forceRefreshRecentGlobalReplies 返回的 Future 完成时代表刷新操作结束
    _repliesFuture?.whenComplete(() {
      if (mounted) {
        setState(() {
          _isRefreshing = false; // 结束刷新
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          FutureBuilder<List<GlobalPostReplyItem>>(
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
                // 确保你的 InlineErrorWidget 存在并且签名匹配
                return InlineErrorWidget(
                  // 或者叫 ErrorWidget，看你实际命名
                  onRetry: _handleRefresh, // 提供重试回调
                  errorMessage: "加载失败: ${snapshot.error}", // 显示错误信息
                );
              }

              // 3. 处理成功状态 (加载完成后且无错误)
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
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
                  itemBuilder: (context, index) => _buildReplyItem(
                    context,
                    replies[index],
                  ),
                );
              }

              // 4. 其他情况 (理论上 FutureBuilder 主要关注 waiting 和 done)
              // 可以返回一个初始占位符或者加载指示器
              return SizedBox(
                  height: 200, child: LoadingWidget.inline(size: 12));
            },
          ),
        ],
      ),
    );
  }

  // _buildReplyItem 方法保持不变
  Widget _buildReplyItem(
    BuildContext context,
    GlobalPostReplyItem reply,
  ) {
    final userId = reply.authorId;
    final postTitle = reply.postTitle;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          if (widget.post.id != reply.postId) {
            NavigationUtils.pushNamed(context, AppRoutes.postDetail,
                arguments: reply.postId);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UserInfoBadge(
                    targetUserId: userId,
                    showFollowButton: false,
                    currentUser: widget.currentUser,
                    infoProvider: widget.infoProvider,
                    followService: widget.followService,
                    mini: true,
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 8),
              Text(
                postTitle == null ? '回复了帖子' : '回复了帖子 $postTitle',
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
      ),
    );
  }
}
