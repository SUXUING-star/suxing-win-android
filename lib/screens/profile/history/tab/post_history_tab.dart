// lib/screens/profile/history/tab/post_history_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/post_list_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';

class PostHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;
  final User? currentUser;
  final PostService postService;
  final UserInfoProvider userInfoProvider;
  final UserFollowService userFollowService;

  const PostHistoryTab({
    super.key,
    required this.isLoaded,
    required this.onLoad,
    required this.currentUser,
    required this.postService,
    required this.userInfoProvider,
    required this.userFollowService,
  });

  @override
  _PostHistoryTabState createState() => _PostHistoryTabState();
}

class _PostHistoryTabState extends State<PostHistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<Post>? _postHistoryItems;
  PaginationData? _postHistoryPagination;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  late int _page;
  final int _pageSize = 10;
  User? _currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _page = 1;
    _currentUser = widget.currentUser;

    if (widget.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadHistory();
      });
    } else {
      _isInitialLoading = false;
    }
  }

  @override
  void didUpdateWidget(PostHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoaded && !oldWidget.isLoaded) {
      setState(() {
        _page = 1;
        _postHistoryItems = null;
        _isInitialLoading = true;
      });
      _loadHistory();
    }
    if (_currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      if (_page == 1) {
        if (!_isInitialLoading) _postHistoryItems = null;
      }
    });

    try {
      final PostListPagination postListResult =
          await widget.postService.getPostHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      final List<Post> newItems = postListResult.posts;
      final PaginationData paginationData = postListResult.pagination;

      setState(() {
        if (_page == 1) {
          _postHistoryItems = newItems;
        } else {
          _postHistoryItems = [...(_postHistoryItems ?? []), ...newItems];
        }
        _postHistoryPagination = paginationData;
        _isLoading = false;
        if (_isInitialLoading) _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading || !mounted) return;
    if (_postHistoryPagination == null ||
        !_postHistoryPagination!.hasNextPage()) {
      return;
    }
    _page++;

    try {
      final PostListPagination postListResult =
          await widget.postService.getPostHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      final List<Post> newItems = postListResult.posts;
      final PaginationData paginationData = postListResult.pagination;

      setState(() {
        if (newItems.isNotEmpty) {
          _postHistoryItems = [...(_postHistoryItems ?? []), ...newItems];
        }
        _postHistoryPagination = paginationData;
      });
    } catch (e) {
      if (!mounted) return;
      _page--;
    }
  }

  Widget _buildInitialLoadButton() {
    return Center(
      child: FadeInSlideUpItem(
        child: FunctionalTextButton(
          onPressed: widget.onLoad,
          label: '加载帖子浏览记录',
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return LoadingWidget.inline(message: "正在加载数据...");
  }

  Widget _buildEmptyState() {
    return FadeInSlideUpItem(
      child: EmptyStateWidget(
        message: '暂无帖子浏览记录',
        iconColor: Colors.grey[400],
        iconData: Icons.article_outlined,
        iconSize: 64,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return LoadingWidget.inline(message: "加载更多...");
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: FadeInItem(
          child: FunctionalTextButton(
            onPressed: _loadMoreHistory,
            label: '加载更多',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isLoaded) {
      return _buildInitialLoadButton();
    }

    if (_isLoading &&
        (_postHistoryItems == null || _postHistoryItems!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_postHistoryItems == null || _postHistoryItems!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildListLayout(context);
  }

  Widget _buildListLayout(BuildContext context) {
    final listKey = ValueKey<int>(_postHistoryItems?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoading &&
            (_postHistoryPagination?.hasNextPage() ?? false)) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await _loadHistory();
        },
        child: ListView.builder(
          key: listKey,
          padding: const EdgeInsets.all(16),
          itemCount: (_postHistoryItems?.length ?? 0) + 1,
          itemBuilder: (context, index) {
            if (index == (_postHistoryItems?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                return _buildLoadMoreIndicator();
              } else if (!_isLoading &&
                  (_postHistoryPagination?.hasNextPage() ?? false)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink();
              }
            }

            final Post postItem = _postHistoryItems![index];
            return FadeInSlideUpItem(
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: const Duration(milliseconds: 350),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: BasePostCard(
                  post: postItem,
                  currentUser: _currentUser,
                  infoProvider: widget.userInfoProvider, // 使用 widget.
                  followService: widget.userFollowService, // 使用 widget.
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
