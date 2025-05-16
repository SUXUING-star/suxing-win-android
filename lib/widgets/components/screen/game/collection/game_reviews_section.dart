// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/game/game_review.dart'; // 使用这个模型
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
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
  const GameReviewSection({super.key, required this.game});
  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  List<GameReview> _entries = []; // *** 修改变量名 ***
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 15;
  bool _hasMoreEntries = true; // *** 修改变量名 ***
  bool _isProcessingPageOne = false;
  int _loadReviewsCallCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews(isInitialLoad: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool gameIdChanged = oldWidget.game.id != widget.game.id;
    bool ratingDataChanged = widget.game.rating != oldWidget.game.rating ||
        widget.game.ratingCount != oldWidget.game.ratingCount;

    if (gameIdChanged) {
      refresh();
    } else if (ratingDataChanged && mounted) {
      setState(() {});
    }
  }

  void refresh() {
    if (_isProcessingPageOne || !mounted) return;
    setState(() {
      _page = 1;
      _entries = []; // *** 修改变量名 ***
      _isLoading = true;
      _error = null;
      _hasMoreEntries = true; // *** 修改变量名 ***
    });
    _loadReviews(isInitialLoad: true);
  }

  Future<void> _loadReviews({bool isInitialLoad = false}) async {
    _loadReviewsCallCount++;
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
      if (_isLoading || !_hasMoreEntries) return; // *** 修改变量名 ***
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
      final collectionService = context.read<GameCollectionService>();
      final List<GameReview> fetchedEntries =
          await collectionService // *** 修改变量名 ***
              .getGameReviews(widget.game.id, page: _page, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        if (_page == 1) {
          _entries = fetchedEntries; // *** 修改变量名 ***
        } else {
          _entries.addAll(fetchedEntries); // *** 修改变量名 ***
        }
        _hasMoreEntries = fetchedEntries.length >= _pageSize; // *** 修改变量名 ***
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_page == 1) {
          _error = '加载条目失败: ${e.toString().split(':').last.trim()}';
          _entries = []; // *** 修改变量名 ***
        } else {
          if (context.mounted) AppSnackBar.showError(context, '加载更多条目失败');
          _hasMoreEntries = false; // *** 修改变量名 ***
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
    if (!_isLoading && _hasMoreEntries) {
      // *** 修改变量名 ***
      setState(() => _page++);
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
                color: Colors.grey[850])), // *** 修改标题 ***
      ],
    );
  }

  Widget _buildAverageRatingDisplay() {
    final game = widget.game;
    final bool hasRating = game.ratingCount > 0;
    final int currentLoadedEntries = _entries.length; // *** 修改变量名 ***

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
            if (hasRating)
              Text('共有 ${game.ratingCount} 份评分',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            // *** 修改条件和文本 ***
            if (currentLoadedEntries > 0 && !(_isLoading && _page == 1))
              Padding(
                padding: EdgeInsets.only(top: hasRating ? 4.0 : 0),
                child: Text('$currentLoadedEntries 条动态',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: LoadingWidget.inline(message: '正在加载动态...'), // *** 修改文本 ***
      );
    }
    if (_error != null && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: InlineErrorWidget(errorMessage: _error!, onRetry: refresh),
      );
    }
    // *** 修改空状态文本和条件 ***
    if (_entries.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: EmptyStateWidget(message: '暂无玩家动态'),
      );
    }
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _entries.length, // *** 修改变量名 ***
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          return _buildCollectionEntryItem(
              _entries[index]); // *** 修改方法名和变量名 ***
        });
  }

  // *** 方法重命名 ***
  Widget _buildCollectionEntryItem(GameReview entry) {
    final String userId = entry.userId;
    final DateTime updateTime = entry.updateTime;
    final double? rating = entry.rating;
    final String? reviewText = entry.review;
    final String status = entry.status;
    final String? notesText = entry.notes;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String statusLabel;
    IconData statusIcon;
    Color statusColor;
    // print(status);
    // print(userId);
    // print(updateTime);
    // print("↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑");
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
                      userId: userId, showFollowButton: false, mini: true)),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(statusIcon, size: 16, color: statusColor),
                label: Text(statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor)),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
          if (status == 'played' && rating != null)
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
                userId == authProvider.currentUserId
                    ? "我做的笔记: $notesText"
                    : "笔记: $notesText", // 区分本人笔记
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ),
          // if (status != 'played' &&
          //     (reviewText == null || reviewText.isEmpty) &&
          //     (notesText == null || notesText.isEmpty))
          //   // Padding(
          //   //   padding: const EdgeInsets.only(top: 8.0),
          //   //   child: Text(
          //   //     status == 'want_to_play' ? '(标记为想玩)' : '(标记为在玩)',
          //   //     style: TextStyle(
          //   //         fontSize: 12,
          //   //         color: Colors.grey[500],
          //   //         fontStyle: FontStyle.italic),
          //   //   ),
          //   // ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreSection() {
    // *** 修改加载中文本 ***
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: LoadingWidget.inline(size: 20, message: "加载中..."));
    }
    // *** 修改条件和按钮文本 ***
    if (!_isLoading && _hasMoreEntries && _entries.isNotEmpty) {
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
