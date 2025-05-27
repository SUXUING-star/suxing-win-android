// lib/screens/profile/history/tab/game_history_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';

class GameHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;
  final User? currentUser;
  final GameService gameService;

  const GameHistoryTab({
    super.key,
    required this.isLoaded,
    required this.onLoad,
    required this.currentUser,
    required this.gameService,
  });

  @override
  _GameHistoryTabState createState() => _GameHistoryTabState();
}

class _GameHistoryTabState extends State<GameHistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<Game>? _gameHistoryItems;
  PaginationData? _gameHistoryPagination;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasInitializedDependencies = false;
  late final GameService _gameService;
  late int _page;
  final int _pageSize = 15;
  User? _currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _page = 1;
    _currentUser = widget.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _gameService = widget.gameService;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      if (widget.isLoaded && _gameHistoryItems == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadHistory();
        });
      } else if (!widget.isLoaded) {
        _isInitialLoading = false;
      }
    }
  }

  @override
  void didUpdateWidget(GameHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoaded && !oldWidget.isLoaded) {
      setState(() {
        _page = 1;
        _gameHistoryItems = null;
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
        if (!_isInitialLoading) _gameHistoryItems = null;
      }
    });

    try {
      final GameListPagination gameListResult =
          await _gameService.getGameHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      final List<Game> newItems = gameListResult.games;
      final PaginationData paginationData = gameListResult.pagination;

      setState(() {
        if (_page == 1) {
          _gameHistoryItems = newItems;
        } else {
          _gameHistoryItems = [...(_gameHistoryItems ?? []), ...newItems];
        }
        _gameHistoryPagination = paginationData;
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
    if (_gameHistoryPagination == null ||
        !_gameHistoryPagination!.hasNextPage()) {
      return;
    }

    _page++;

    try {
      final GameListPagination gameListResult =
          await _gameService.getGameHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      final List<Game> newItems = gameListResult.games;
      final PaginationData paginationData = gameListResult.pagination;

      setState(() {
        if (newItems.isNotEmpty) {
          _gameHistoryItems = [...(_gameHistoryItems ?? []), ...newItems];
        }
        _gameHistoryPagination = paginationData;
      });
    } catch (e) {
      if (!mounted) return;
      _page--;
    }
  }

  Widget _buildInitialLoadButton() {
    return Center(
      child: FunctionalTextButton(onPressed: widget.onLoad, label: '加载游戏浏览记录'),
    );
  }

  Widget _buildLoadingIndicator() {
    return LoadingWidget.inline();
  }

  Widget _buildEmptyState() {
    return FadeInSlideUpItem(
      child: EmptyStateWidget(
        message: '暂无游戏浏览记录',
        iconData: Icons.history_edu_outlined,
        iconColor: Colors.grey[400],
        iconSize: 64,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return LoadingWidget.inline(message: "正在加载记录");
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: FadeInItem(
          child:
              FunctionalTextButton(onPressed: _loadMoreHistory, label: '加载更多'),
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
        (_gameHistoryItems == null || _gameHistoryItems!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_gameHistoryItems == null || _gameHistoryItems!.isEmpty) {
      return _buildEmptyState();
    }

    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  Widget _buildListLayout(BuildContext context) {
    final listKey = ValueKey<int>(_gameHistoryItems?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoading &&
            (_gameHistoryPagination?.hasNextPage() ?? false)) {
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
          itemCount: (_gameHistoryItems?.length ?? 0) + 1,
          itemBuilder: (context, index) {
            if (index == (_gameHistoryItems?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                return _buildLoadMoreIndicator();
              } else if (!_isLoading &&
                  (_gameHistoryPagination?.hasNextPage() ?? false)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink();
              }
            }

            final Game gameItem = _gameHistoryItems![index];
            return FadeInSlideUpItem(
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: const Duration(milliseconds: 350),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CommonGameCard(
                  game: gameItem,
                  isGridItem: false,
                  showTags: true,
                  maxTags: 3,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    // ***** 使用你提供的 DeviceUtils.calculateSimpleCardRatio *****
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);
    // ***** 结束修改 *****
    final gridKey = ValueKey<int>(_gameHistoryItems?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoading &&
            (_gameHistoryPagination?.hasNextPage() ?? false)) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await _loadHistory();
        },
        child: GridView.builder(
          key: gridKey,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            // ***** 使用你提供的 DeviceUtils.calculateSimpleCardRatio *****
            childAspectRatio: cardRatio,
            // ***** 结束修改 *****
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: (_gameHistoryItems?.length ?? 0) + 1,
          itemBuilder: (context, index) {
            if (index == (_gameHistoryItems?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                return _buildLoadMoreIndicator();
              } else if (!_isLoading &&
                  (_gameHistoryPagination?.hasNextPage() ?? false)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink();
              }
            }

            final Game gameItem = _gameHistoryItems![index];
            return FadeInSlideUpItem(
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: const Duration(milliseconds: 350),
              child: CommonGameCard(
                game: gameItem,
                isGridItem: true,
                showTags: true,
                maxTags: 2,
              ),
            );
          },
        ),
      ),
    );
  }
}
