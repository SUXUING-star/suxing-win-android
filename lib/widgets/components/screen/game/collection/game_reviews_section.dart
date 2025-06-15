// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';
import 'package:suxingchahui/models/game/game_collection_review_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/review/game_review_item.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class GameReviewSection extends StatefulWidget {
  final Game game;
  final User? currentUser;
  final GameCollectionService gameCollectionService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  const GameReviewSection({
    super.key,
    required this.game,
    required this.currentUser,
    required this.followService,
    required this.gameCollectionService,
    required this.infoProvider,
  });
  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  List<GameCollectionReviewEntry> _reviews = [];
  PaginationData? _paginationData;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = GameCollectionService.gameCollectionReviewsLimit;
  bool _isProcessingPageOne = false;
  bool _hasInitializedDependencies = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUser = widget.currentUser;
      if (_reviews.isEmpty && mounted) {
        _loadReviews(isInitialLoad: true);
      }
    }
  }

  @override
  void dispose() {
    _reviews = [];
    _paginationData = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool gameIdChanged = oldWidget.game.id != widget.game.id;

    if (gameIdChanged) {
      refresh();
    }

    if (_currentUser != widget.currentUser ||
        widget.currentUser != oldWidget.currentUser) {
      if (mounted) {
        setState(() {
          _currentUser = widget.currentUser;
        });
      }
    }
  }

  void refresh() {
    if (_isProcessingPageOne || !mounted) return;
    if (mounted) {
      setState(() {
        _page = 1;
        _reviews = [];
        _paginationData = null;
        _isLoading = true;
        _error = null;
      });
    }
    _loadReviews(isInitialLoad: true);
  }

  Future<void> _loadReviews({bool isInitialLoad = false}) async {
    final bool forPageOne = isInitialLoad || _page == 1;

    if (forPageOne) {
      if (_isProcessingPageOne) return;
      _isProcessingPageOne = true;
      if (!_isLoading && mounted) {
        setState(() => _isLoading = true);
      } else if (!mounted) {
        _isProcessingPageOne = false;
        return;
      }
    } else {
      if (_isLoading || !(_paginationData?.hasNextPage() ?? false)) return;
      if (mounted) {
        setState(() => _isLoading = true);
      } else {
        return;
      }
    }

    if (!mounted) {
      if (forPageOne && _isProcessingPageOne) _isProcessingPageOne = false;
      return;
    }

    try {
      final GameCollectionReviewPagination reviewListResult = await widget
          .gameCollectionService
          .getGameCollectionReviews(widget.game.id,
              page: _page, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        if (_page == 1) {
          _reviews = reviewListResult.reviews;
        } else {
          _reviews.addAll(reviewListResult.reviews);
        }
        _paginationData = reviewListResult.pagination;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_page == 1) {
          _error = '加载动态失败: ${e.toString().split(':').last.trim()}';
          _reviews = [];
          _paginationData =
              PaginationData(page: _page, limit: _pageSize, total: 0, pages: 0);
        } else {
          AppSnackBar.showError("操作失败,${e.toString()}");
        }
      });
    } finally {
      final bool stillMounted = mounted;
      bool shouldReleaseLock = forPageOne && _isProcessingPageOne;
      if (stillMounted) {
        setState(() {
          if (shouldReleaseLock) _isProcessingPageOne = false;
          _isLoading = false;
        });
      } else {
        if (shouldReleaseLock) _isProcessingPageOne = false;
      }
    }
  }

  void _loadMoreReviews() {
    if (!_isLoading && (_paginationData?.hasNextPage() ?? false)) {
      if (mounted) {
        setState(() => _page++);
      }
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
          '玩家动态',
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
    final bool hasGameRating = game.ratingCount > 0;
    final int totalReviewCount = _paginationData?.total ?? 0;
    final bool hasReviewsToShow = totalReviewCount > 0 ||
        (_reviews.isNotEmpty && _paginationData == null);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 6),
            if (hasGameRating)
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasGameRating)
              Text(
                '共有 ${game.ratingCount} 份评分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (hasReviewsToShow &&
                !(_isLoading && _page == 1 && _reviews.isEmpty))
              Padding(
                padding: EdgeInsets.only(top: hasGameRating ? 4.0 : 0),
                // 如果 paginationData 可用，显示 total，否则显示当前已加载的 reviews 数量
                child: Text(
                  '${_paginationData != null ? _paginationData!.total : _reviews.length} 条动态',
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

  Widget _buildContent() {
    if (_isLoading && _page == 1 && _reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: LoadingWidget(size: 18, message: "正在加载"),
      );
    }
    if (_error != null && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: InlineErrorWidget(errorMessage: _error!, onRetry: refresh),
      );
    }
    if (_reviews.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: EmptyStateWidget(message: '暂无评价'),
      );
    }
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          return GameReviewItemWidget(
            review: _reviews[index],
            currentUser: widget.currentUser,
            followService: widget.followService,
            infoProvider: widget.infoProvider,
          );
        });
  }

  Widget _buildLoadMoreSection() {
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      return const Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: LoadingWidget(size: 20, message: "加载中..."),
      );
    }
    if (!_isLoading &&
        (_paginationData?.hasNextPage() ?? false) &&
        _reviews.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FunctionalButton(
            onPressed: _loadMoreReviews,
            label: '加载更多动态',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
