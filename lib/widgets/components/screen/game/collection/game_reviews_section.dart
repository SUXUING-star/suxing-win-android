// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 需要 intl 来格式化数字
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

  const GameReviewSection({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  final GameCollectionService _collectionService = GameCollectionService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 5;
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews(isInitialLoad: true);
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      print(
          "GameReviewSection (${widget.game.id}): Game ID changed. Refreshing...");
      refresh();
    }
    // 如果 game 对象本身发生变化（例如父组件更新了评分），也需要 setState 来更新 UI
    // 这里简单比较 rating 和 ratingCount，更复杂的比较可以覆盖更多字段
    if (widget.game.rating != oldWidget.game.rating ||
        widget.game.ratingCount != oldWidget.game.ratingCount) {
      print(
          "GameReviewSection (${widget.game.id}): Game rating data changed. Triggering UI rebuild.");
      if (mounted) {
        setState(() {}); // 触发 UI 重建以显示新的评分
      }
    }
  }

  void refresh() {
    print("GameReviewSection (${widget.game.id}): refresh() called.");
    if (mounted) {
      setState(() {
        _page = 1;
        _reviews = [];
        _isLoading = true;
        _error = null;
        _hasMoreReviews = true;
      });
      _loadReviews(isInitialLoad: true);
    } else {
      print(
          "GameReviewSection (${widget.game.id}): refresh() called but widget is not mounted.");
    }
  }

  Future<void> _loadReviews({bool isInitialLoad = false}) async {
    if (_isLoading && !isInitialLoad) return;
    if (!_hasMoreReviews && !isInitialLoad) return;

    if (!isInitialLoad && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else if (!mounted) {
      return;
    }

    try {
      final reviews = await _collectionService.getGameReviews(widget.game.id,
          page: _page, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        final fetchedList = List<Map<String, dynamic>>.from(reviews);
        if (_page == 1) {
          _reviews = fetchedList;
        } else {
          _reviews.addAll(fetchedList);
        }
        _hasMoreReviews = fetchedList.length >= _pageSize;
        _isLoading = false;
        _error = null;
        // 页码增加移到 _loadMoreReviews 或成功加载后
        // if (_hasMoreReviews) { _page++; } // 不在这里增加
      });
    } catch (e, s) {
      print(
          'GameReviewSection (${widget.game.id}): Error loading reviews page $_page: $e\n$s');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_page == 1) {
          _error = '加载评价失败: ${e.toString()}';
          _reviews = [];
        } else {
          AppSnackBar.showError(context, '加载更多评价失败');
          _hasMoreReviews = false;
        }
      });
    }
  }

  void _loadMoreReviews() {
    if (!_isLoading && _hasMoreReviews) {
      print(
          "GameReviewSection (${widget.game.id}): Loading more reviews (Page ${_page + 1})...");
      setState(() {
        _page++; // 在请求前增加页码
      });
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 12), // 标题和评分之间的间距

            // *** 在这里加上平均评分显示区域 ***
            _buildAverageRatingDisplay(), // <--- 新增调用

            const SizedBox(height: 16), // 评分和内容列表之间的间距
            Divider(color: Colors.grey[200], height: 1), // 分割线
            const SizedBox(height: 8), // 分割线和内容之间的间距

            _buildContent(), // 显示评价列表或状态信息

            // 加载更多按钮逻辑不变
            if (_hasMoreReviews && !_isLoading) _buildLoadMoreButton(),
            if (_isLoading && _page > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(child: LoadingWidget.inline(size: 20)),
              ),
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
        // 注意：这里的评论条数显示逻辑移到 _buildAverageRatingDisplay 中，与评分一起显示
        // const SizedBox(width: 8),
        // if (_reviews.isNotEmpty && !(_isLoading && _page == 1))
        //   Text(
        //     '共${_reviews.length} 条',
        //     style: TextStyle(
        //       color: Colors.grey[600],
        //       fontSize: 14,
        //     ),
        //   ),
      ],
    );
  }

  // *** 新增：构建平均评分显示的 Widget ***
  Widget _buildAverageRatingDisplay() {
    final game = widget.game; // 直接用 widget.game 获取最新数据
    final bool hasRating = game.ratingCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 让评分居左，数量居右
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左侧：显示星星和平均分
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded,
                color: Colors.amber, size: 22), // 用圆角的星星图标
            const SizedBox(width: 6),
            if (hasRating)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: game.rating.toStringAsFixed(1), // 显示一位小数
                      style: TextStyle(
                        fontSize: 20, // 突出显示分数
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: ' / 10',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
        // 右侧：显示评分人数和评论总数
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasRating) // 只有有人评分才显示评分人数
              Text(
                '基于 ${game.ratingCount} 份评分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            // 评论总数显示 (如果列表加载完成且不为空)
            if (_reviews.isNotEmpty && !(_isLoading && _page == 1))
              Padding(
                padding:
                    EdgeInsets.only(top: hasRating ? 4.0 : 0), // 如果有评分，稍微加点间距
                child: Text(
                  '${_reviews.length} 条评价', // 显示当前已加载的评价数
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  // *** 平均评分显示区域结束 ***

  Widget _buildContent() {
    // 这里的逻辑不变
    if (_isLoading && _page == 1) {
      return LoadingWidget.inline(message: '正在加载评价...');
    }
    if (_error != null && _page == 1) {
      return InlineErrorWidget(errorMessage: _error!, onRetry: refresh);
    }
    if (_reviews.isEmpty && !_isLoading) {
      return const EmptyStateWidget(message: '暂无玩家评价，快来抢沙发吧！');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey[200], height: 1),
      itemBuilder: (context, index) => _buildReviewItem(_reviews[index]),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    // 这个方法内部逻辑不变
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
          // 单条评价里的星级显示可以保持不变，或者也改成 5 星制
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                  children: List.generate(5, (index) {
                double starValue = rating / 2;
                IconData starIcon;
                Color starColor = Colors.amber;
                if (index < starValue.floor()) {
                  starIcon = Icons.star;
                } else if (index < starValue && (starValue - index) >= 0.25) {
                  starIcon = Icons.star_half;
                } else {
                  starIcon = Icons.star_border;
                  starColor = Colors.grey[400]!;
                }
                return Icon(starIcon, size: 16, color: starColor); // 单条评论里星星小一点
              })),
            ),
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                reviewText,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[800], height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    // 这个方法逻辑不变
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: TextButton(
          onPressed:
              _isLoading ? null : _loadMoreReviews, // 调用 _loadMoreReviews
          child: _isLoading && _page > 1
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('加载中...'),
                ])
              : Text('加载更多评价'), // 文本可以改一下
        ),
      ),
    );
  }
}
