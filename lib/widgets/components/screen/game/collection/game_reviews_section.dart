// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'dart:async'; // 引入 FutureOr

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class GameReviewSection extends StatefulWidget {
  final Game game;

  const GameReviewSection({Key? key, required this.game}) : super(key: key);

  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  final GameCollectionService _collectionService = GameCollectionService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true; // 整体加载状态标志 (包括初始加载、刷新、加载更多)
  String? _error;
  int _page = 1;
  final int _pageSize = 5;
  bool _hasMoreReviews = true;

  // *** 锁：防止处理第一页的操作（初始加载/刷新）并发执行 ***
  bool _isProcessingPageOne = false;
  int _loadReviewsCallCount = 0; // 调试计数器

  @override
  void initState() {
    super.initState();
    //print(">>> GRS (${widget.game.id}): initState CALLED.");
    // initState 里调用 _loadReviews 来加载初始数据
    // 它会负责设置和管理锁
    _loadReviews(isInitialLoad: true);
  }

  @override
  void dispose() {
    //print(">>> GRS (${widget.game.id}): dispose CALLED.");
    super.dispose();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool gameIdChanged = oldWidget.game.id != widget.game.id;
    bool ratingDataChanged = widget.game.rating != oldWidget.game.rating ||
        widget.game.ratingCount != oldWidget.game.ratingCount;

    //print(">>> GRS (${widget.game.id}): didUpdateWidget. GameId changed: $gameIdChanged, Rating changed: $ratingDataChanged");

    if (gameIdChanged) {
      //print(">>> GRS (${widget.game.id}): Game ID changed. Calling refresh().");
      // 调用 refresh，它会检查锁并可能触发 _loadReviews
      refresh();
    } else if (ratingDataChanged) {
      //print(">>> GRS (${widget.game.id}): Rating data changed. Calling internal setState() for UI rebuild ONLY.");
      if (mounted) {
        setState(() {}); // 只重建 UI 显示新评分
      }
    }
  }

  /// 公开的刷新方法 (供外部调用，如父组件或下拉刷新)
  void refresh() {
    final callId = DateTime.now().millisecondsSinceEpoch; // 调试 ID
    //print(">>> GRS (${widget.game.id}): refresh() CALLED [$callId]. Current lock status: $_isProcessingPageOne");

    // 1. 检查是否已经在处理第一页，如果是，则忽略本次刷新请求
    if (_isProcessingPageOne) {
      //print(">>> GRS (${widget.game.id}): refresh() ABORTED [$callId] - Already processing page 1.");
      return;
    }

    // 2. 检查组件是否还挂载
    if (!mounted) {
      //print(">>> GRS (${widget.game.id}): refresh() ABORTED [$callId] - Widget not mounted.");
      return;
    }

    // 3. 重置状态，准备刷新
    //print(">>> GRS (${widget.game.id}): refresh() PROCEEDING [$callId]. Resetting state.");
    setState(() {
      _page = 1;
      _reviews = [];
      _isLoading = true; // *** 进入加载状态 ***
      _error = null;
      _hasMoreReviews = true;
      // 注意：这里不再设置 _isProcessingPageOne 锁，交由 _loadReviews 统一处理
    });

    // 4. 调用加载逻辑
    print(">>> GRS (${widget.game.id}): refresh() calling _loadReviews [$callId].");
    _loadReviews(isInitialLoad: true, debugCallId: callId);
  }

  /// 内部加载数据的方法 (核心逻辑)
  /// [isInitialLoad] 标记是否由 initState 或 refresh 触发
  /// [debugCallId] 仅用于调试追踪
  Future<void> _loadReviews({bool isInitialLoad = false, int? debugCallId}) async {
    _loadReviewsCallCount++;
    final currentCallCount = _loadReviewsCallCount;
    final bool forPageOne = isInitialLoad || _page == 1; // 判断是否是针对第一页的操作

    print(">>> GRS (${widget.game.id}): _loadReviews CALLED (Count: $currentCallCount, Page: $_page, Initial: $isInitialLoad, ForPage1: $forPageOne) [$debugCallId]. Lock status: $_isProcessingPageOne, IsLoading: $_isLoading");

    // --- 防并发和重复加载 ---
    // 1. 如果是针对第一页的操作 (Initial Load 或 Refresh)
    if (forPageOne) {
      if (_isProcessingPageOne) { // 检查锁是否已被其他调用（如并发的 refresh 或 initState）占用
        print(">>> GRS (${widget.game.id}): _loadReviews ABORTED (Count: $currentCallCount, Page: $_page) [$debugCallId] - Already processing page 1 (Lock is ON).");
        return; // 阻止并发执行
      } else {
        // 如果没有锁，说明这是第一个到达的针对第一页的操作，获取锁
        print(">>> GRS (${widget.game.id}): _loadReviews Setting page 1 lock (Count: $currentCallCount, Page: $_page) [$debugCallId].");
        _isProcessingPageOne = true;
        // 因为 refresh 或 initState 可能已经设置了 _isLoading=true，这里不需要重复 setState
        // 但如果逻辑允许其他地方调用 _loadReviews(page:1)，这里可能需要 setState({_isLoading = true, _isProcessingPageOne = true})
        // 为了安全，如果发现 _isLoading 是 false，还是强制设为 true
        if (!_isLoading && mounted) {
          print(">>> GRS (${widget.game.id}): Forcing _isLoading=true while setting page 1 lock [$debugCallId].");
          setState(() { _isLoading = true; }); // 确保 UI 显示加载状态
        } else if (!_isLoading && !mounted) {
          print(">>> GRS (${widget.game.id}): Tried to set _isLoading=true but unmounted [$debugCallId]. Aborting.");
          _isProcessingPageOne = false; // 释放刚设置的锁
          return;
        }
      }
    }
    // 2. 如果是加载更多页 (不是第一页)
    else {
      // 必须同时满足：不在加载中 + 还有更多
      if (_isLoading) {
        print(">>> GRS (${widget.game.id}): _loadReviews ABORTED loading more (Count: $currentCallCount, Page: $_page) [$debugCallId] - _isLoading is true.");
        return;
      }
      if (!_hasMoreReviews) {
        print(">>> GRS (${widget.game.id}): _loadReviews ABORTED loading more (Count: $currentCallCount, Page: $_page) [$debugCallId] - _hasMoreReviews is false.");
        return;
      }
      // 加载更多时，不需要关心 _isProcessingPageOne 锁
      // 设置整体加载状态
      if (mounted) {
        print(">>> GRS (${widget.game.id}): Setting _isLoading=true for loading page $_page [$debugCallId].");
        setState(() { _isLoading = true; });
      } else {
        print(">>> GRS (${widget.game.id}): Tried to set _isLoading=true for page $_page but unmounted [$debugCallId]. Aborting.");
        return;
      }
    }
    // --- 防并发检查结束 ---

    // 组件检查，防止在 API 调用前卸载
    if (!mounted) {
      print(">>> GRS (${widget.game.id}): _loadReviews ABORTED before API call (Count: $currentCallCount, Page: $_page) [$debugCallId] - Widget not mounted.");
      // 如果是第一页的操作，并且在 API 调用前就 unmounted 了，需要释放锁
      if (forPageOne && _isProcessingPageOne) {
        print(">>> GRS (${widget.game.id}): Releasing page 1 lock early due to unmount before API call [$debugCallId].");
        _isProcessingPageOne = false;
      }
      return;
    }

    // *** 开始 API 请求 ***
    try {
      print(">>> GRS (${widget.game.id}): Fetching API for page $_page (Count: $currentCallCount) [$debugCallId]...");
      final reviews = await _collectionService.getGameReviews(widget.game.id, page: _page, limit: _pageSize);
      print(">>> GRS (${widget.game.id}): API fetched for page $_page (Count: $currentCallCount) [$debugCallId]. Mounted: $mounted");

      // API 返回后再次检查是否挂载
      if (!mounted) {
        print(">>> GRS (${widget.game.id}): Widget unmounted after API call for page $_page (Count: $currentCallCount) [$debugCallId].");
        // finally 块会处理锁
        return;
      }

      // 处理成功结果
      setState(() {
        final fetchedList = List<Map<String, dynamic>>.from(reviews ?? []);
        if (_page == 1) { // 使用 _page 判断，因为 forPageOne 可能在分页加载时为 false
          _reviews = fetchedList;
        } else {
          _reviews.addAll(fetchedList);
        }
        _hasMoreReviews = fetchedList.length >= _pageSize;
        _error = null;
        // _isLoading = false; // 移到 finally 处理
        print(">>> GRS (${widget.game.id}): Page $_page loaded successfully (Count: $currentCallCount) [$debugCallId]. HasMore: $_hasMoreReviews. Total: ${_reviews.length}");
      });

    } catch (e, s) {
      print(">>> GRS (${widget.game.id}): ERROR loading page $_page (Count: $currentCallCount) [$debugCallId]: $e\n$s");
      if (!mounted) {
        print(">>> GRS (${widget.game.id}): Widget unmounted after API error for page $_page (Count: $currentCallCount) [$debugCallId].");
        // finally 块会处理锁
        return;
      }
      // 处理错误结果
      setState(() {
        // _isLoading = false; // 移到 finally 处理
        if (_page == 1) { // 使用 _page 判断
          _error = '加载评价失败: ${e.toString().split(':').last.trim()}';
          _reviews = [];
        } else {
          // 加载更多失败，用 Snackbar 提示
          if(context.mounted) { // 确保 context 可用
            AppSnackBar.showError(context, '加载更多评价失败');
          }
          _hasMoreReviews = false; // 标记没有更多
        }
      });
    } finally {
      // *** 无论成功失败，最终执行 ***
      final bool stillMounted = mounted; // 记录当前挂载状态
      print(">>> GRS (${widget.game.id}): Finally block for page $_page (Count: $currentCallCount) [$debugCallId]. Mounted: $stillMounted, Lock before release: $_isProcessingPageOne");

      // 标记：是否需要在 finally 块结束后释放锁
      bool shouldReleaseLock = false;
      if (forPageOne && _isProcessingPageOne) {
        shouldReleaseLock = true;
      }

      if (stillMounted) {
        // 如果组件还挂载，安全地调用 setState
        setState(() {
          // *** 释放页面 1 的锁（仅当这个调用是处理页面1且持有锁时）***
          if (shouldReleaseLock) {
            print(">>> GRS (${widget.game.id}): Releasing page 1 lock in finally (mounted) [$debugCallId].");
            _isProcessingPageOne = false;
          }
          // *** 总是重置整体加载状态 ***
          _isLoading = false;
          print(">>> GRS (${widget.game.id}): Setting _isLoading=false in finally (mounted) [$debugCallId].");
        });
      } else {
        // 如果组件已卸载，不能调用 setState，但需要确保锁状态被更新
        if (shouldReleaseLock) {
          print(">>> GRS (${widget.game.id}): Releasing page 1 lock in finally (unmounted) [$debugCallId].");
          _isProcessingPageOne = false; // 直接修改成员变量
        }
        // _isLoading 在卸载后无所谓
      }
      print(">>> GRS (${widget.game.id}): End of finally for page $_page (Count: $currentCallCount) [$debugCallId]. Lock status: $_isProcessingPageOne, IsLoading: $_isLoading");
    }
  }

  /// 加载更多评论（由按钮触发）
  void _loadMoreReviews() {
    print(">>> GRS (${widget.game.id}): _loadMoreReviews CALLED. Lock: $_isProcessingPageOne, Loading: $_isLoading, HasMore: $_hasMoreReviews");
    // 必须同时满足：不在加载中 + 还有更多
    // 注意：加载更多不关心 _isProcessingPageOne 锁
    if (!_isLoading && _hasMoreReviews) {
      setState(() {
        _page++; // 先增加页码
      });
      print(">>> GRS (${widget.game.id}): Incremented page to $_page, calling _loadReviews.");
      _loadReviews(); // 调用加载
    } else {
      print(">>> GRS (${widget.game.id}): _loadMoreReviews ignored.");
    }
  }

  // --- UI 构建方法 (无省略号) ---
  @override
  Widget build(BuildContext context) {
    print(">>> GRS (${widget.game.id}): build CALLED. Current State: isLoading=$_isLoading, isProcessingP1=$_isProcessingPageOne, page=$_page, error=$_error, reviews=${_reviews.length}, hasMore=$_hasMoreReviews");
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildAverageRatingDisplay(),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 8),
            _buildContent(),
            _buildLoadMoreSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '玩家评价',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[850],
          ),
        ),
      ],
    );
  }

  Widget _buildAverageRatingDisplay() {
    final game = widget.game;
    final bool hasRating = game.ratingCount > 0;
    final int currentLoadedReviews = _reviews.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Stars and average rating
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 6),
            if (hasRating)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: game.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: ' / 10',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Text(
                '暂无评分',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        // Right: Rating count and review count
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasRating)
              Text(
                '共有 ${game.ratingCount} 份评分',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (currentLoadedReviews > 0 && !(_isLoading && _page == 1))
              Padding(
                padding: EdgeInsets.only(top: hasRating ? 4.0 : 0),
                child: Text(
                  '$currentLoadedReviews 条评价',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    // 1. Initial loading state for page 1
    if (_isLoading && _page == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: LoadingWidget.inline(message: '正在加载评价...'),
      );
    }
    // 2. Error state for page 1 load failure
    if (_error != null && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        // Pass the refresh method to the error widget's retry button
        child: InlineErrorWidget(errorMessage: _error!, onRetry: refresh),
      );
    }
    // 3. Empty state after loading page 1 successfully but finding no reviews
    if (_reviews.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: EmptyStateWidget(message: '暂无玩家评价，快来抢沙发吧！'),
      );
    }
    // 4. Display the list of reviews
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          // Log index for debugging potential list issues
          // print(">>> GRS (${widget.game.id}): Building review item at index $index");
          return _buildReviewItem(_reviews[index]);
        }
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final userId = user['userId']?.toString() ?? '';
    DateTime? updateTime;
    final updateTimeString = review['updateTime']?.toString();
    if (updateTimeString != null) {
      try {
        updateTime = DateTime.parse(updateTimeString).toLocal();
      } catch (_) {}
    }
    final dynamic rawRating = review['rating'];
    final double? rating = (rawRating is num) ? rawRating.toDouble() : null;
    final String reviewText = review['review']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and timestamp row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UserInfoBadge(
                  userId: userId,
                  showFollowButton: false,
                  mini: true,
                ),
              ),
              const SizedBox(width: 8),
              if (updateTime != null)
                Text(
                  DateTimeFormatter.formatRelative(updateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          // Rating stars (5-star scale)
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                children: List.generate(5, (index) {
                  double starValue = rating / 2.0;
                  IconData starIcon;
                  Color starColor = Colors.amber;
                  if (index < starValue.floor()) {
                    starIcon = Icons.star_rounded;
                  } else if (index < starValue && (starValue - index) >= 0.25) {
                    starIcon = Icons.star_half_rounded;
                  } else {
                    starIcon = Icons.star_border_rounded;
                    starColor = Colors.grey[400]!;
                  }
                  return Icon(starIcon, size: 16, color: starColor);
                }),
              ),
            ),
          // Review text
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                reviewText,
                style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreSection() {
    // Show loading indicator when loading more pages (isLoading is true, but not processing page 1)
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: LoadingWidget.inline(size: 20, message: "加载中...")
      );
    }
    // Show "Load More" button if not loading, there are more reviews, and some reviews are already loaded
    if (!_isLoading && _hasMoreReviews && _reviews.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextButton(
            onPressed: _loadMoreReviews,
            child: const Text('加载更多评价'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ),
      );
    }
    // Otherwise, show nothing
    return const SizedBox.shrink();
  }
}