// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';
import 'package:suxingchahui/models/game/game_collection_review_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

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
  List<GameCollectionReview> _reviews = [];
  PaginationData? _paginationData;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = GameCollectionService.gameCollectionReviewsLimit;
  bool _isProcessingPageOne = false;
  bool _hasInitializedDependencies = false;
  late final GameCollectionService _collectionService;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _collectionService = widget.gameCollectionService;
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
      final GameCollectionReviewPagination reviewListResult =
          await _collectionService.getGameCollectionReviews(widget.game.id,
              page: _page, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        if (_page == 1) {
          _reviews = reviewListResult.entries;
        } else {
          _reviews.addAll(reviewListResult.entries);
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
          if (context.mounted) AppSnackBar.showError(context, '加载更多动态失败');
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
        Text('玩家动态',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[850])),
      ],
    );
  }

  Widget _buildAverageRatingDisplay() {
    final game = widget.game;
    final bool hasGameRating = game.ratingCount > 0;
    // 使用 _paginationData?.total 来获取API返回的评论总数
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
                            color: Colors.black87)),
                    TextSpan(
                        text: ' / 10',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              )
            else
              Text('暂无评分',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasGameRating)
              Text('共有 ${game.ratingCount} 份评分',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (hasReviewsToShow &&
                !(_isLoading && _page == 1 && _reviews.isEmpty))
              Padding(
                padding: EdgeInsets.only(top: hasGameRating ? 4.0 : 0),
                // 如果 paginationData 可用，显示 total，否则显示当前已加载的 reviews 数量
                child: Text(
                    '${_paginationData != null ? _paginationData!.total : _reviews.length} 条动态',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _page == 1 && _reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: LoadingWidget.inline(message: '正在加载动态...'),
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
        child: EmptyStateWidget(message: '暂无玩家动态'),
      );
    }
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          return _buildCollectionEntryItem(_reviews[index]);
        });
  }

  Widget _buildCollectionEntryItem(GameCollectionReview entry) {
    final String userId = entry.userId;
    final DateTime updateTime = entry.updateTime;
    final double? rating = entry.rating;
    final String? reviewText = entry.review;
    final String status = entry.status;
    final String? notesText = entry.notes;

    String statusLabel;
    IconData statusIcon;
    Color statusColor;
    switch (status) {
      case GameCollectionStatus.wantToPlay:
        statusLabel = '想玩';
        statusIcon = Icons.bookmark_add_outlined;
        statusColor = Colors.blue;
        break;
      case GameCollectionStatus.playing:
        statusLabel = '在玩';
        statusIcon = Icons.gamepad_outlined;
        statusColor = Colors.orange;
        break;
      case GameCollectionStatus.played:
        statusLabel = '玩过';
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.green;
        break;
      default:
        statusLabel = '未知';
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
    }

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
                      followService: widget.followService,
                      infoProvider: widget.infoProvider,
                      currentUser: widget.currentUser,
                      targetUserId: userId,
                      showFollowButton: false,
                      mini: true)),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(statusIcon, size: 16, color: statusColor),
                label: Text(statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                backgroundColor: statusColor.withSafeOpacity(0.1),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(color: statusColor.withSafeOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 8),
              Text(DateTimeFormatter.formatRelative(updateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          if (status == GameCollectionStatus.played && rating != null)
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
          if (reviewText != null && reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(reviewText,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[800], height: 1.5)),
            ),
          if (notesText != null && notesText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                userId == widget.currentUser?.id
                    ? "我做的笔记: $notesText"
                    : "笔记: $notesText",
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreSection() {
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: LoadingWidget.inline(size: 20, message: "加载中..."));
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
