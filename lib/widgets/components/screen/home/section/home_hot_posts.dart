// lib/widgets/components/screen/home/section/home_hot_posts.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart'; // 引入 Service
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'dart:async';

import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 需要 Timer (如果之前没有)

// *** 修改：改为 StatefulWidget ***
class HomeHotPosts extends StatefulWidget {
  // 移除 Stream 参数
  const HomeHotPosts({super.key}); // 使用 Key
  @override
  _HomeHotPostsState createState() => _HomeHotPostsState();
}

class _HomeHotPostsState extends State<HomeHotPosts> {
  // 内部状态
  List<Post>? _cachedPosts;
  bool _isLoading = false;
  String? _errorMessage;

  bool _hasInit = false;
  late final ForumService _forumService;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInit) {
      // 使用 watch 监听变化，确保 Provider 更新时 Widget 重建

      _forumService = context.read<ForumService>();
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _hasInit = true;
    }
    if (_hasInit) {
      _fetchData(); // initState 获取数据
    }
  }

  // 获取数据的 Future 方法
  Future<void> _fetchData() async {
    if (!mounted) return;
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _forumService.getHotPosts();

      if (mounted && posts.isNotEmpty) {
        setState(() {
          _cachedPosts = posts;
        });
      } else {
        _errorMessage = '加载热门帖子失败';
        setState(() {
          _isLoading = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载热门帖子失败'; // 简化错误信息

          _cachedPosts = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 确保 isLoading 被重置
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 整体结构和样式保持不变
    return Opacity(
      opacity: 0.9,
      child: Container(
        // margin: EdgeInsets.all(16), // 外层 Padding 会处理
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withSafeOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 标题栏保持不变 ---
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 1))),
              child: Row(
                children: [
                  Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(3))),
                  SizedBox(width: 12),
                  Text('热门帖子',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900])),
                  Spacer(),
                  // 可选：如果需要更多按钮
                  // InkWell(...)
                ],
              ),
            ),
            SizedBox(height: 16),

            // --- 使用内部状态构建列表区域 ---
            _buildPostListArea(context),
          ],
        ),
      ),
    );
  }

  // 构建列表区域的辅助方法
  Widget _buildPostListArea(BuildContext context) {
    // 1. 加载状态
    if (_isLoading && _cachedPosts == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget.inline(message: '加载热门帖子...', size: 24),
      );
    }

    // 2. 错误状态
    if (_errorMessage != null && _cachedPosts == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: InlineErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _fetchData,
        ),
      );
    }

    // 3. 空状态
    if (!_isLoading && (_cachedPosts == null || _cachedPosts!.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: EmptyStateWidget(
          message: '暂无热门帖子',
          iconData: Icons.forum_outlined,
          iconSize: 30,
          iconColor: Colors.grey[400],
        ),
      );
    }

    // 4. 正常显示列表 (或加载中但有旧数据)
    final posts = _cachedPosts ?? []; // 使用缓存或空列表
    final displayPosts = posts.take(5).toList(); // 最多显示 5 条

    final userInfoProvider = context.watch<UserInfoProvider>();

    return Stack(
      // 使用 Stack 添加加载覆盖层
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: displayPosts.length,
          separatorBuilder: (context, index) => Divider(
              height: 20,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.withSafeOpacity(0.15)),
          itemBuilder: (context, index) {
            final post = displayPosts[index];
            final userId = post.authorId;
            userInfoProvider.ensureUserInfoLoaded(userId);
            final UserDataStatus userDataStatus =
                userInfoProvider.getUserStatus(userId);
            return _buildPostListItem(context, post, userDataStatus);
          },
        ),
        // 加载覆盖层
        if (_isLoading && posts.isNotEmpty)
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5),
            child: Center(child: LoadingWidget.inline(size: 30)),
          )),
      ],
    );
  }

  // --- _buildPostListItem, _buildPostStats, _buildStatItem 保持不变 ---
  Widget _buildPostListItem(
      BuildContext context, Post post, UserDataStatus userDataStatus) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        NavigationUtils.pushNamed(
          context,
          AppRoutes.postDetail,
          arguments: post.id,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(post.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[850],
                            fontSize: 15,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      UserInfoBadge(
                          userDataStatus: userDataStatus,
                          currentUser: _authProvider.currentUser,
                          userId: post.authorId,
                          mini: true,
                          showLevel: false,
                          showFollowButton: false,
                          padding: EdgeInsets.zero),
                      SizedBox(width: 8),
                      Flexible(
                          child: Text(
                              '· ${DateTimeFormatter.formatTimeAgo(post.createTime)}',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            _buildPostStats(context, post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStats(BuildContext context, Post post) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem(context, Icons.mode_comment_outlined, post.replyCount,
            Colors.blueGrey[400]),
        SizedBox(height: 8),
        _buildStatItem(context, Icons.thumb_up_alt_outlined, post.likeCount,
            Colors.pink[300]),
        SizedBox(height: 8),
        _buildStatItem(context, Icons.bookmark_border_outlined,
            post.favoriteCount, Colors.teal[400]),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, int count, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor ?? Colors.grey[500], size: 16),
        SizedBox(width: 5),
        Text('$count',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
} // End of _HomeHotPostsState
