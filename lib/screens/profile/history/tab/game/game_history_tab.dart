// lib/screens/profile/tab/game_history_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'card/game_history_grid_card.dart'; // 导入网格布局卡片
import './card/game_history_list_card.dart'; // 导入列表布局卡片

// 游戏历史标签页 - 优化UI显示
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
  List<Map<String, dynamic>>? _gameHistoryWithDetails;
  Map<String, dynamic>? _gameHistoryPagination;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasInitializedDependencies = false;
  late final GameService _gameService;
  late int _page;
  final int _pageSize = 15;
  User? _currentUser;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免切换标签页时重建

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
      if (widget.isLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadHistory();
        });
      } else {
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
        _gameHistoryWithDetails = null;
        _isInitialLoading = true;
      });
      _loadHistory();
    }
    if (_currentUser != widget.currentUser ||
        oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      if (_page > 1) {
        // 加载更多时不清空
      } else if (!_isInitialLoading && _gameHistoryWithDetails != null) {
        _gameHistoryWithDetails = null; // 下拉刷新时清空
      }
    });

    try {
      final results =
          await _gameService.getGameHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      List<Map<String, dynamic>> currentItems = _gameHistoryWithDetails ?? [];
      List<Map<String, dynamic>> newItems = [];
      Map<String, dynamic>? paginationData;

      // 安全处理
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{})
            .toList();
      }
      if (results.containsKey('pagination') && results['pagination'] is Map) {
        paginationData =
            Map<String, dynamic>.from(results['pagination'] as Map);
      } else {
        paginationData = {
          'page': _page,
          'limit': _pageSize,
          'total': 0,
          'totalPages': 0
        };
      }

      setState(() {
        if (_page == 1) {
          _gameHistoryWithDetails = newItems;
        } else {
          _gameHistoryWithDetails = [...currentItems, ...newItems];
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
    if (_gameHistoryPagination == null) return;

    final int totalPages = _gameHistoryPagination!['totalPages'] as int? ?? 1;
    if (_page >= totalPages) return;

    _page++;

    try {
      final results =
          await _gameService.getGameHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      List<Map<String, dynamic>> currentItems = _gameHistoryWithDetails ?? [];
      List<Map<String, dynamic>> newItems = [];
      Map<String, dynamic>? paginationData;

      // 安全处理
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{})
            .toList();
      }
      if (results.containsKey('pagination') && results['pagination'] is Map) {
        paginationData =
            Map<String, dynamic>.from(results['pagination'] as Map);
      } else {
        paginationData = {
          'page': _page,
          'limit': _pageSize,
          'total': 0,
          'totalPages': 0
        };
      }

      setState(() {
        if (newItems.isNotEmpty) {
          _gameHistoryWithDetails = [...currentItems, ...newItems];
        }
        _gameHistoryPagination = paginationData;
        // _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _page--;
      // setState(() { _isLoading = false; });
      // 显示错误提示...
    }
  }

  Widget _buildInitialLoadButton() {
    return Center(
      child: FunctionalTextButton(onPressed: widget.onLoad, label: '加载浏览记录'),
    );
  }

  Widget _buildLoadingIndicator() {
    return LoadingWidget.inline();
  }

  Widget _buildEmptyState() {
    return FadeInSlideUpItem(
      // 添加动画
      child: EmptyStateWidget(
        message: '暂无游戏浏览记录',
        iconData: Icons.history,
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
      // 给加载更多加点边距
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: FadeInItem(
          // 添加动画
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
        (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty) {
      return _buildEmptyState();
    }

    // 根据设备类型选择不同的布局
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  // 列表布局 - 适用于移动设备
  Widget _buildListLayout(BuildContext context) {
    // 添加 Key
    final listKey = ValueKey<int>(_gameHistoryWithDetails?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _isInitialLoading = true;
          await _loadHistory();
        },
        child: ListView.builder(
          key: listKey, // 应用 Key
          padding: EdgeInsets.all(16),
          itemCount: (_gameHistoryWithDetails?.length ?? 0) + 1,
          itemBuilder: (context, index) {
            if (index == (_gameHistoryWithDetails?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                return _buildLoadMoreIndicator();
              } else if (!_isLoading &&
                  _gameHistoryPagination != null &&
                  _page <
                      (_gameHistoryPagination!['totalPages'] as int? ?? 1)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink();
              }
            }

            final historyItem = _gameHistoryWithDetails![index];
            return FadeInSlideUpItem(
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: Duration(milliseconds: 350),
              child: Padding(
                // 加间距
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GameHistoryListCard(historyItem: historyItem),
              ),
            );
          },
        ),
      ),
    );
  }

  // 网格布局 - 适用于桌面和平板
  Widget _buildGridLayout(BuildContext context) {
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);
    // 添加 Key
    final gridKey = ValueKey<int>(_gameHistoryWithDetails?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _isInitialLoading = true;
          await _loadHistory();
        },
        child: GridView.builder(
          key: gridKey, // 应用 Key
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: (_gameHistoryWithDetails?.length ?? 0) + 1,
          itemBuilder: (context, index) {
            if (index == (_gameHistoryWithDetails?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                return _buildLoadMoreIndicator();
              } else if (!_isLoading &&
                  _gameHistoryPagination != null &&
                  _page <
                      (_gameHistoryPagination!['totalPages'] as int? ?? 1)) {
                // 网格布局的加载更多按钮可能需要特殊处理，或者只显示指示器
                // 这里暂时和列表保持一致
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink();
              }
            }

            final historyItem = _gameHistoryWithDetails![index];
            return FadeInSlideUpItem(
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: Duration(milliseconds: 350),
              child: GameHistoryGridCard(historyItem: historyItem),
            );
          },
        ),
      ),
    );
  }
}
