// lib/screens/collection/game_collection_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game_with_collection.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/widgets/components/screen/gamecollection/game_collection_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class GameCollectionScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameCollectionService gameCollectionService;
  final SidebarProvider sidebarProvider;
  final WindowStateProvider windowStateProvider;

  const GameCollectionScreen({
    super.key,
    required this.authProvider,
    required this.gameCollectionService,
    required this.sidebarProvider,
    required this.windowStateProvider,
  });

  @override
  _GameCollectionScreenState createState() => _GameCollectionScreenState();
}

class _GameCollectionScreenState extends State<GameCollectionScreen> {
  List<GameWithCollection> _allCollections = [];
  PaginationData? _globalPaginationData;
  GameCollectionCounts? _collectionCounts;

  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;

  User? _currentUser;
  bool? _previousIsLoggedIn;
  bool _hasInitializedDependencies = false;
  bool _isRefreshing = false;
  DateTime? _lastForcedRefreshTime;
  static const Duration _minForcedRefreshInterval = Duration(seconds: 15);

  final ScrollController _scrollController = ScrollController();

  // 新增：用于在桌面端显示 Review 的状态
  GameWithCollection? _selectedGameForReview;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      _currentUser = widget.authProvider.currentUser;
      _checkUserHasChanged();
    } else {
      final newCurrentUser = widget.authProvider.currentUser;
      if (_currentUser != newCurrentUser) {
        _currentUser = newCurrentUser;
        _checkUserHasChanged();
      }
    }
  }

  @override
  void didUpdateWidget(covariant GameCollectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authProvider != oldWidget.authProvider ||
        _currentUser != widget.authProvider.currentUser) {
      if (mounted) {
        setState(() {
          _currentUser = widget.authProvider.currentUser;
        });
      }
      _checkUserHasChanged();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        (_globalPaginationData?.hasNextPage() ?? false)) {
      _loadMoreData();
    }
  }

  void _checkUserHasChanged() {
    final currentIsLoggedIn = widget.authProvider.isLoggedIn;
    if (_previousIsLoggedIn != null &&
        currentIsLoggedIn != _previousIsLoggedIn) {
      if (currentIsLoggedIn) {
        _refreshData(); // 登录后刷新数据
      } else {
        // 用户登出
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = '请先登录后再查看收藏';
            _clearDataOnLogout();
            _selectedGameForReview = null; // 用户登出，清除选中的游戏
          });
        }
      }
    } else if (_previousIsLoggedIn == null && currentIsLoggedIn) {
      // 首次加载且用户已登录
      _loadData(isInitialLoad: true);
      _lastForcedRefreshTime = DateTime.now();
    } else if (_previousIsLoggedIn == null && !currentIsLoggedIn) {
      // 首次加载且用户未登录
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '请先登录后再查看收藏';
          _clearDataOnLogout();
          _selectedGameForReview = null; // 用户未登录，清除选中的游戏
        });
      }
    }
    _previousIsLoggedIn = currentIsLoggedIn;
  }

  Future<void> _loadData(
      {bool forceRefresh = false, bool isInitialLoad = false}) async {
    if (!mounted) return;
    if (_isLoading && !isInitialLoad && _currentPage > 1) return;

    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '请先登录后再查看收藏';
          if (isInitialLoad) _clearDataOnLogout();
          _selectedGameForReview = null; // 未登录，清除选中的游戏
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        if (_currentPage == 1) {
          _error = null;
          if (isInitialLoad || forceRefresh) {
            _allCollections.clear();
            // _collectionCounts = null; // 会在下面被重新赋值
            if (forceRefresh) {
              _selectedGameForReview = null; // 强制刷新时，清除选中的游戏Review
            }
          }
        }
      });
    }

    try {
      final groupedData = await widget.gameCollectionService
          .getAllUserGameCollectionsGrouped(
              page: _currentPage, forceRefresh: forceRefresh);

      if (mounted) {
        if (groupedData != null) {
          List<GameWithCollection> newlyFetchedItems = [];
          newlyFetchedItems.addAll(groupedData.wantToPlay);
          newlyFetchedItems.addAll(groupedData.playing);
          newlyFetchedItems.addAll(groupedData.played);

          setState(() {
            if (_currentPage == 1) {
              _allCollections = newlyFetchedItems;
            } else {
              final existingIds =
                  _allCollections.map((e) => e.collection.gameId).toSet();
              newlyFetchedItems.removeWhere(
                  (newItem) => existingIds.contains(newItem.collection.gameId));
              _allCollections.addAll(newlyFetchedItems);
            }
            _globalPaginationData = groupedData.pagination;
            _collectionCounts = groupedData.counts;
            _error = null;
          });
        } else {
          if (_currentPage == 1) {
            _error = '加载收藏数据失败';
            _collectionCounts = null;
            _allCollections.clear();
            _selectedGameForReview = null; // 加载失败，清除选中的游戏
          } else {
            AppSnackBar.showError("操作失败");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (_currentPage == 1) {
          _error = '加载收藏失败: ${e.toString().split(':').last.trim()}';
          _allCollections.clear();
          _collectionCounts = null;
          _selectedGameForReview = null; // 异常，清除选中的游戏
        } else {
          AppSnackBar.showError("操作失败,${e.toString()}");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_isRefreshing) _isRefreshing = false;
        });
      }
    }
  }

  void _clearDataOnLogout() {
    _allCollections.clear();
    _globalPaginationData = null;
    _collectionCounts = null;
    _currentPage = 1;
    // _selectedGameForReview 已在 _checkUserHasChanged 中处理
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || _isLoading && _currentPage == 1) return;
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        // _selectedGameForReview = null; // 刷新时清除选中的 Review，由_loadData中的forceRefresh处理
      });
    }
    await _loadData(forceRefresh: true, isInitialLoad: true);
  }

  Future<void> _handleRefreshFromIndicator() async {
    final now = DateTime.now();
    if (_isRefreshing) return;

    if (_lastForcedRefreshTime != null &&
        now.difference(_lastForcedRefreshTime!) < _minForcedRefreshInterval) {
      if (context.mounted) AppSnackBar.showWarning('操作太快了，请稍后再试');
      return;
    }

    _lastForcedRefreshTime = now;
    await _refreshData();
  }

  void _loadMoreData() {
    if (!_isLoading && (_globalPaginationData?.hasNextPage() ?? false)) {
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoading = true;
        });
      }
      _loadData();
    }
  }

  // 新增：处理游戏卡片点击事件（用于桌面端显示Review）
  void _handleGameTapForReview(GameWithCollection gameWithCollection) {
    if (!mounted) return;
    setState(() {
      // 如果再次点击同一个游戏，则关闭 Review 面板，否则显示新的
      if (_selectedGameForReview?.collection.gameId ==
          gameWithCollection.collection.gameId) {
        _selectedGameForReview = null;
      } else {
        _selectedGameForReview = gameWithCollection;
      }
    });
  }

  // 新增：关闭 Review 面板的方法
  void _closeReviewPanel() {
    if (!mounted) return;
    setState(() {
      _selectedGameForReview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '我的游戏收藏',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!widget.authProvider.isLoggedIn) {
      return const LoginPromptWidget();
    }

    if (_isLoading &&
        _currentPage == 1 &&
        _allCollections.isEmpty &&
        _collectionCounts == null &&
        _error == null) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //// 全屏加载组件
    }

    if (_error != null && _allCollections.isEmpty) {
      return CustomErrorWidget(
        errorMessage: _error,
        onRetry: _refreshData,
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefreshFromIndicator,
      child: GameCollectionLayout(
        windowStateProvider: widget.windowStateProvider,
        collectionCounts: _collectionCounts,
        collectedGames: _allCollections,
        isLoadingMore: _isLoading && _currentPage > 1,
        hasMore: _globalPaginationData?.hasNextPage() ?? false,
        scrollController: _scrollController,
        onLoadMore: _loadMoreData,
        onGoToDiscover: () => NavigationUtils.navigateToHome(
          widget.sidebarProvider,
          context,
          tabIndex: 1,
        ),
        // 新增参数传递
        selectedGameForReview: _selectedGameForReview,
        onGameTapForReview: _handleGameTapForReview,
        onCloseReviewPanel: _closeReviewPanel,
      ),
    );
  }
}
