// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../services/main/game/collection/game_collection_service.dart';
import '../../../../../utils/datetime/date_time_formatter.dart';
import '../../../badge/info/user_info_badge.dart';

class GameReviewSection extends StatefulWidget {
  final Game game;

  const GameReviewSection({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

// 将状态类改为公开，以便外部可以访问刷新方法
class GameReviewSectionState extends State<GameReviewSection> {
  final GameCollectionService _collectionService = GameCollectionService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _page = 1;
  final int _pageSize = 5;
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _loadReviews();
    }
  }

  // 添加公开的刷新方法
  void refresh() {
    setState(() {
      _page = 1;
    });
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!_hasMoreReviews && _page > 1) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final reviews = await _collectionService.getGameReviews(widget.game.id);
      print('游戏评价API响应: $reviews'); // 调试输出

      setState(() {
        if (_page == 1) {
          _reviews = List<Map<String, dynamic>>.from(reviews);
        } else {
          _reviews.addAll(List<Map<String, dynamic>>.from(reviews));
        }

        _hasMoreReviews = reviews.length >= _pageSize;
        _isLoading = false;
        _page++;
      });
    } catch (e) {
      print('加载评价失败: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
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
            const SizedBox(height: 16),
            _buildContent(),
            if (_hasMoreReviews && !_isLoading && _reviews.isNotEmpty)
              _buildLoadMoreButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '玩家评价',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_reviews.isNotEmpty)
          Text(
            '${_reviews.length} 条评价',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _page == 1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError && _reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text('加载评价时出错'),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                onPressed: () {
                  setState(() {
                    _page = 1;
                  });
                  _loadReviews();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('暂无玩家评价'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => _buildReviewItem(_reviews[index]),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>;
    final userId = user['userId'];
    final DateTime updateTime = DateTime.parse(review['updateTime']);
    final dynamic rating = review['rating'];
    final String reviewText = review['review'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UserInfoBadge(
                userId: userId,
                showFollowButton: false,
                mini: true,
              ),
              Text(
                DateTimeFormatter.formatRelative(updateTime),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 18,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(rating as num).toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                reviewText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: TextButton(
          onPressed: _isLoading ? null : _loadReviews,
          child: _isLoading
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text('加载中...'),
            ],
          )
              : Text('加载更多'),
        ),
      ),
    );
  }
}