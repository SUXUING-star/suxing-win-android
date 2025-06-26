// lib/widgets/components/screen/forum/post/section/recent_global_replies.dart

/// 该文件定义了 RecentGlobalReplies 组件，用于显示最新活跃的全局回复列表。
/// RecentGlobalReplies 负责加载和展示近期回复，并提供刷新功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/post/global_post_reply_item.dart'; // 全局帖子回复项模型所需
import 'package:suxingchahui/models/post/post.dart'; // 帖子模型所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务所需
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由所需
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 帖子服务所需
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务所需
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具所需
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类所需
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件所需
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态组件所需
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 提示条组件所需

/// `RecentGlobalReplies` 类：显示最新活跃回复列表的 StatefulWidget。
///
/// 该组件加载和展示近期回复，并提供刷新功能。
class RecentGlobalReplies extends StatefulWidget {
  final int limit; // 回复数量限制
  final Post post; // 相关的帖子对象
  final User? currentUser; // 当前登录用户
  final PostService postService; // 帖子服务实例
  final UserInfoService infoService; // 用户信息服务实例
  final UserFollowService followService; // 用户关注服务实例

  /// 构造函数。
  ///
  /// [limit]：回复数量限制。
  /// [post]：相关的帖子对象。
  /// [infoService]：用户信息服务实例。
  /// [followService]：用户关注服务实例。
  /// [postService]：帖子服务实例。
  /// [currentUser]：当前登录用户。
  const RecentGlobalReplies({
    super.key,
    this.limit = 5,
    required this.post,
    required this.infoService,
    required this.followService,
    required this.postService,
    required this.currentUser,
  });

  @override
  _RecentGlobalRepliesState createState() => _RecentGlobalRepliesState();
}

class _RecentGlobalRepliesState extends State<RecentGlobalReplies> {
  Future<List<GlobalPostReplyItem>>? _repliesFuture; // 存储获取全局回复的异步操作
  User? _currentUser; // 当前用户实例
  bool _isRefreshing = false; // 刷新操作进行中标记
  DateTime? _lastRefreshTime; // 上次刷新时间
  static const Duration _minRefreshInterval = Duration(seconds: 15); // 最小刷新间隔

  bool _hasInit = false; // 初始化标记

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    _currentUser = widget.currentUser; // 初始化当前用户
  }

  @override
  void didUpdateWidget(covariant RecentGlobalReplies oldWidget) {
    super.didUpdateWidget(oldWidget); // 调用父类 didUpdateWidget
    if (_currentUser != widget.currentUser ||
        oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies(); // 调用父类 didChangeDependencies
    if (!_hasInit) {
      _hasInit = true; // 标记依赖已初始化
    }
    if (_hasInit) {
      _loadReplies(); // 加载回复
    }
  }

  /// 封装加载回复的逻辑。
  ///
  /// 该方法将获取全局回复的 Future 赋值给 `_repliesFuture`。
  void _loadReplies() {
    _repliesFuture =
        widget.postService.getRecentGlobalReplies(limit: widget.limit);
  }

  @override
  void dispose() {
    super.dispose(); // 调用父类 dispose
  }

  /// 处理主动刷新操作。
  ///
  /// [forceRefresh]：是否强制刷新，忽略时间间隔限制。
  /// 该方法包含节流逻辑，防止短时间内重复刷新。
  void _handleRefresh({bool forceRefresh = false}) {
    if (_isRefreshing) {
      // 刷新操作进行中时阻止
      return;
    }

    final now = DateTime.now(); // 获取当前时间

    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minRefreshInterval) {
      // 检查是否达到最小刷新间隔
      AppSnackBar.showWarning('操作太快了，请稍后再试'); // 显示警告信息
      return;
    }

    if (mounted) {
      // 检查组件是否挂载
      setState(() {
        _isRefreshing = true; // 设置刷新状态
        _lastRefreshTime = now; // 更新上次刷新时间

        _repliesFuture = widget.postService.getRecentGlobalReplies(
          limit: widget.limit,
          forceRefresh: forceRefresh,
        ); // 调用服务获取最新回复
      });
    }

    _repliesFuture?.whenComplete(() {
      // 刷新操作完成后执行
      if (mounted) {
        // 检查组件是否挂载
        setState(() {
          _isRefreshing = false; // 清除刷新状态
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16), // 顶部外边距
      decoration: BoxDecoration(
        color: Colors.white, // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        border: Border.all(color: Colors.grey[200]!), // 边框
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // 内边距
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
                    const SizedBox(width: 8), // 间距
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
                  icon: Icon(Icons.refresh,
                      size: 20, color: Colors.grey[600]), // 刷新图标
                  onPressed: _handleRefresh, // 刷新按钮点击回调
                  tooltip: '刷新最新活跃', // 工具提示
                ),
              ],
            ),
          ),
          const Divider(height: 1), // 分割线
          FutureBuilder<List<GlobalPostReplyItem>>(
            future: _repliesFuture, // 绑定 Future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // 加载中状态
                return const SizedBox(
                  height: 200, // 固定高度
                  child: LoadingWidget(
                    size: 12,
                  ),
                );
              }

              if (snapshot.hasError) {
                // 错误状态
                return InlineErrorWidget(
                  onRetry: _handleRefresh, // 提供重试回调
                  errorMessage: "加载失败: ${snapshot.error}", // 显示错误信息
                );
              }

              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                // 加载完成且有数据
                final replies = snapshot.data ?? []; // 获取回复数据
                if (replies.isEmpty) {
                  // 数据为空
                  return const EmptyStateWidget(
                      message: "暂无回复", iconData: Icons.maps_ugc_outlined);
                }

                return ListView.separated(
                  shrinkWrap: true, // 在 Column 里需要
                  physics: const NeverScrollableScrollPhysics(), // 在 Column 里需要
                  padding: const EdgeInsets.all(16), // 内边距
                  itemCount: replies.length, // 回复数量
                  separatorBuilder: (_, __) => const Divider(height: 16), // 分隔线
                  itemBuilder: (context, index) => _buildReplyItem(
                    context,
                    replies[index],
                  ),
                );
              }

              return const SizedBox(
                // 默认占位符
                height: 200,
                child: LoadingWidget(size: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建单个回复项。
  ///
  /// [context]：Build 上下文。
  /// [reply]：全局帖子回复项。
  /// 返回一个表示单个回复的 Card Widget。
  Widget _buildReplyItem(
    BuildContext context,
    GlobalPostReplyItem reply,
  ) {
    final userId = reply.authorId; // 作者 ID
    final postTitle = reply.postTitle; // 帖子标题

    return Card(
      elevation: 0,
      color: Colors.grey[50], // 背景色
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 圆角
      ),
      child: InkWell(
        onTap: () {
          if (widget.post.id != reply.postId) {
            // 检查是否为当前帖子
            NavigationUtils.pushNamed(context, AppRoutes.postDetail,
                arguments: reply.postId); // 跳转到帖子详情页
          }
        },
        borderRadius: BorderRadius.circular(8), // 圆角
        child: Padding(
          padding: const EdgeInsets.all(12.0), // 内边距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UserInfoBadge(
                    // 用户信息徽章
                    targetUserId: userId,
                    showFollowButton: false,
                    currentUser: widget.currentUser,
                    infoService: widget.infoService,
                    followService: widget.followService,
                    mini: true,
                  ),
                  const SizedBox(width: 8), // 间距
                  Text(
                    DateTimeFormatter.formatTimeAgo(reply.createTime), // 格式化时间
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // 间距
              Text(
                reply.content, // 回复内容
                style: const TextStyle(fontSize: 14),
                maxLines: 2, // 最大行数
                overflow: TextOverflow.ellipsis, // 溢出时显示省略号
              ),
              const SizedBox(height: 8), // 间距
              Text(
                postTitle == null ? '回复了帖子' : '回复了帖子 $postTitle', // 帖子标题或默认文本
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1, // 最大行数
                overflow: TextOverflow.ellipsis, // 溢出时显示省略号
              ),
            ],
          ),
        ),
      ),
    );
  }
}
