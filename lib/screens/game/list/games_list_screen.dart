import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/tag/tag.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/game/game_service.dart'; // Correct path
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // Your Dialog
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // Correct widget
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // Correct widget
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/tag/tag_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_left_panel.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_right_panel.dart';

/// Displays a paginated list of games with in-grid navigation and floating controls.
class GamesListScreen extends StatefulWidget {
  final String? selectedTag;

  const GamesListScreen({super.key, this.selectedTag});

  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen>
    with WidgetsBindingObserver {
  final GameService _gameService = GameService();


  // --- State Variables ---
  bool _isLoadingData = false;
  bool _isInitialized = false;
  bool _isVisible = false;
  bool _needsRefresh = false;
  String? _errorMessage;
  bool _showMobileTagBar = false;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  List<Game> _gamesList = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;
  String? _currentTag;
  GameListFilterProvider? _filterProvider;
  List<Tag> _availableTags = [];
  StreamSubscription<BoxEvent>? _cacheSubscription;
  String _currentWatchIdentifier = '';
  Timer? _refreshDebounceTimer;

  static const int _pageSize = 10;
  static const Duration _cacheDebounceDuration = Duration(milliseconds: 300);
  final Map<String, String> _sortOptions = {
    'createTime': '最新发布',
    'viewCount': '最多浏览',
    'rating': '最高评分'
  };
  static const double _hideRightPanelThreshold = 1000.0;
  static const double _hideLeftPanelThreshold = 800.0;

  // === Lifecycle ===
  @override
  void initState() {
    super.initState();
    //print("GamesListScreen initState: widget.selectedTag = ${widget.selectedTag}");
    // 获取 Provider 实例
    // listen: false 因为我们会在 VisibilityDetector 里主动检查
    _filterProvider = Provider.of<GameListFilterProvider>(context, listen: false);

    // 初始化 _currentTag
    _initializeCurrentTag();

    WidgetsBinding.instance.addObserver(this);
    _loadTags(); // 异步加载可用标签列表
    // 初始数据加载现在主要由 VisibilityDetector 变为可见时触发
  }

  void _initializeCurrentTag() {
    final initialProviderTag = _filterProvider?.selectedTag;
    final tagWasSet = _filterProvider?.tagHasBeenSet ?? false;
    //print("GamesListScreen _initializeCurrentTag: Provider state -> tag='$initialProviderTag', wasSet=$tagWasSet");

    // 规则：如果 Provider 的 tag 被设置过 (wasSet=true)，就用 Provider 的值；否则看 widget.selectedTag
    _currentTag = tagWasSet ? initialProviderTag : widget.selectedTag;
    //print("GamesListScreen _initializeCurrentTag: Initial _currentTag set to '$_currentTag'");

    // 注意：不在 initState 重置 Provider 的 flag，让第一次可见性检查来处理
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 Provider 实例存在
    if (_filterProvider == null) {
      _filterProvider = Provider.of<GameListFilterProvider>(context, listen: false);
      print("GamesListScreen didChangeDependencies: Got provider instance.");
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingCache();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_isVisible) { // 页面当前可见
        print("GamesListScreen: App resumed and visible. Checking provider & refreshing data if needed.");
        _checkProviderAndApplyTagIfNeeded(reason: "App Resumed"); // 检查 Provider
        _refreshDataIfNeeded(reason: "App Resumed"); // 刷新当前页数据
      } else {
        print("GamesListScreen: App resumed but hidden. Marking for refresh.");
        _needsRefresh = true; // 标记，等可见时刷新
      }
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true; // 可选：离开时标记需要刷新
    }
  }

  // === Visibility Handling ===
  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    // 使用一个稍微宽松的阈值，避免快速切换时误判
    final bool nowVisible = visibilityInfo.visibleFraction > 0;
    if (!mounted) return; // 组件已卸载，不处理

    if (nowVisible && !_isVisible) {
      print("GamesListScreen: Became visible.");
      _isVisible = true;
      // 1. 检查 Provider 是否有新的 tag 指令
      _checkProviderAndApplyTagIfNeeded(reason: "Became Visible");

      // 2. 处理加载逻辑
      if (!_isInitialized) {
        print("GamesListScreen: Triggering initial load.");
        // 初始加载使用当前的 _currentTag (可能已被 _checkProvider 更新)
        _loadGames(pageToFetch: 1, isInitialLoad: true);
      } else if (_needsRefresh) {
        print("GamesListScreen: Triggering refresh on visibility.");
        _refreshDataIfNeeded(reason: "Became Visible with NeedsRefresh");
        _needsRefresh = false;
      } else {
        print("GamesListScreen: Already initialized and no refresh needed. Ensuring cache watcher is active.");
        // 确保缓存监听器在监听当前状态
        _startOrUpdateWatchingCache();
      }
    } else if (!nowVisible && _isVisible) {
      print("GamesListScreen: Became hidden.");
      _isVisible = false;
      _stopWatchingCache(); // 页面隐藏时停止监听缓存
      _refreshDebounceTimer?.cancel(); // 取消可能存在的刷新定时器
    }
  }
  // === Provider Check Logic ===
  void _checkProviderAndApplyTagIfNeeded({required String reason}) {
    if (_filterProvider == null) {
      print("GamesListScreen _checkProvider...: Error - Provider instance is null.");
      return;
    }

    final providerTag = _filterProvider!.selectedTag;
    final tagWasSet = _filterProvider!.tagHasBeenSet;

    print("GamesListScreen _checkProvider... (Reason: $reason): "
        "Provider state -> tag='$providerTag', wasSet=$tagWasSet. "
        "Current state -> _currentTag='$_currentTag'");

    // 核心逻辑：只有当 Provider 标记被设置过，并且 Provider 的 tag 和当前页面的 tag 不同时，才需要动作
    if (tagWasSet && providerTag != _currentTag) {
      print("GamesListScreen _checkProvider...: Mismatch detected! Applying tag '$providerTag' from Provider.");
      // 应用新的 tag，这会更新 _currentTag 并触发刷新
      _applyTagAndSort(providerTag, _currentSortBy, _isDescending);
      // !!! 关键：处理完后，重置 Provider 中的标志位 !!!
      _filterProvider!.resetTagFlag();
      print("GamesListScreen _checkProvider...: Provider tag flag has been reset.");
    } else if (tagWasSet && providerTag == _currentTag) {
      // 如果 tag 相同，但标志位是 true (比如重复导航到同一 tag)，我们不刷新，但要重置标志位
      print("GamesListScreen _checkProvider...: Provider tag matches current tag, but flag was set. Resetting flag only.");
      _filterProvider!.resetTagFlag();
    } else {
      // Provider 没被设置过，或者 tag 没变，啥也不用做
      print("GamesListScreen _checkProvider...: No action needed based on provider state.");
    }
  }
  // === Data Loading & Cache ===
  Future<void> _loadTags() async {
    try {
      final tags = await _gameService.getAllTags();
      if (mounted) setState(() => _availableTags = tags);
    } catch (e) {
      if (mounted) {
        print("加载标签失败: $e");
        setState(() => _availableTags = []);
      }
    }
  }

  /// Core data loading function. Handles STRICT pagination logic.
  Future<void> _loadGames({
    int? pageToFetch, // 目标页码
    bool isInitialLoad = false,
    bool isRefresh = false,
  }) async {
    if (!mounted || _isLoadingData) return;

    final int targetPage = pageToFetch ?? 1;

    if (targetPage < 1 ||
        (!isInitialLoad &&
            !isRefresh &&
            _totalPages > 1 &&
            targetPage > _totalPages)) {
      print("请求页码 $targetPage 无效或超出范围 (总页数: $_totalPages)");
      return;
    }

    _isInitialized = true;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      if (isRefresh || isInitialLoad) {
        _gamesList = [];
      }
    });

    print("开始加载 第 $targetPage 页...");

    try {
      Map<String, dynamic> result;
      if (_currentTag != null) {
        result = await _gameService.getGamesByTagWithInfo(
            tag: _currentTag!,
            page: targetPage,
            pageSize: _pageSize,
            sortBy: _currentSortBy,
            descending: _isDescending);
      } else {
        result = await _gameService.getGamesPaginatedWithInfo(
            page: targetPage,
            pageSize: _pageSize,
            sortBy: _currentSortBy,
            descending: _isDescending);
      }

      if (!mounted) return;

      final games = result['games'] as List<Game>? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final int serverPage = pagination['page'] ?? targetPage;
      final int serverTotalPages = pagination['totalPages'] ?? 1;

      print(
          "加载成功 第 $serverPage 页 / 共 $serverTotalPages 页, 获取到 ${games.length} 条数据");

      setState(() {
        _gamesList = games;
        _currentPage = serverPage;
        _totalPages = serverTotalPages;
        _errorMessage = null;
        if (!_isInitialized) _isInitialized = true;
      });

      _startOrUpdateWatchingCache(); // 监听当前页
    } catch (e, s) {
      print("加载第 $targetPage 页失败: $e\n$s");
      if (mounted) {
        setState(() {
          _errorMessage = '加载第 $targetPage 页失败，请稍后重试。';
          if (isRefresh || isInitialLoad) {
            _gamesList = [];
            _currentPage = 1;
            _totalPages = 1;
          }
        });
      }
      _stopWatchingCache();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Starts/Updates cache listener. (监听当前页)
  void _startOrUpdateWatchingCache() {
    final String newWatchIdentifier =
        "${_currentTag ?? 'all'}_${_currentPage}_${_currentSortBy}_$_isDescending";
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      return;
    }
    _stopWatchingCache();
    _currentWatchIdentifier = newWatchIdentifier;
    print("尝试启动缓存监听: $newWatchIdentifier");
    try {
      _cacheSubscription = _gameService
          .watchGameListPageChanges(
        tag: _currentTag,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
        scope: _currentTag != null ? 'tag' : 'all',
      )
          .listen((BoxEvent event) {
        print(
            "缓存事件接收 (监听 $newWatchIdentifier): key=${event.key}, deleted=${event.deleted}");
        if (_isVisible) {
          _refreshDataIfNeeded(reason: "Cache Change on page $_currentPage");
        } else {
          _needsRefresh = true;
        }
      }, onError: (e, s) {
        print("缓存监听错误 ($newWatchIdentifier): $e\n$s");
        _stopWatchingCache();
      }, onDone: () {
        print("缓存监听结束 ($newWatchIdentifier).");
        _stopWatchingCache();
      }, cancelOnError: true);
    } catch (e, s) {
      print("启动缓存监听失败 ($newWatchIdentifier): $e\n$s");
      _currentWatchIdentifier = '';
    }
  }

  /// Stops cache listener.
  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      print("停止缓存监听: $_currentWatchIdentifier");
      _cacheSubscription?.cancel();
      _cacheSubscription = null;
      _currentWatchIdentifier = '';
    }
  }

  /// Debounced refresh trigger. (调用 _loadGames 刷新第一页)
  void _refreshDataIfNeeded({required String reason}) {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      if (mounted && _isVisible && !_isLoadingData) {
        print("触发刷新 (Debounced): $reason");
        _loadGames(pageToFetch: 1, isRefresh: true); // 强制刷新第一页
      } else if (mounted && !_isVisible) {
        print("标记需要刷新 (Debounced): $reason");
        _needsRefresh = true;
      }
    });
  }

  /// Triggers the very first load attempt. (调用 _loadGames 加载第一页)
  void _triggerInitialLoad() {
    if (!_isInitialized && !_isLoadingData) {
      print("触发初始加载");
      _loadGames(pageToFetch: 1, isInitialLoad: true); // 加载第一页并标记为初始加载
    }
  }

  // === User Interactions ===

  /// Handles pull-to-refresh. (调用 _loadGames 刷新第一页)
  Future<void> _refreshData() async {
    if (_isLoadingData) return;
    print("用户触发下拉刷新");
    _stopWatchingCache();
    await _loadGames(pageToFetch: 1, isRefresh: true); // 加载第一页并标记为刷新
  }

  /// Go to Previous Page (Internal - Called by Grid Tile)
  Future<void> _goToPreviousPageInternal() async {
    if (_currentPage > 1 && !_isLoadingData) {
      print("导航到上一页 (目标: ${_currentPage - 1})");
      _stopWatchingCache();
      await _loadGames(pageToFetch: _currentPage - 1); // 加载上一页
    } else {
      print("无法导航到上一页 (当前页: $_currentPage, 加载中: $_isLoadingData)");
    }
  }

  /// Go to Next Page (Internal - Called by Grid Tile)
  Future<void> _goToNextPageInternal() async {
    if (_currentPage < _totalPages && !_isLoadingData) {
      print("导航到下一页 (目标: ${_currentPage + 1})");
      _stopWatchingCache();
      await _loadGames(pageToFetch: _currentPage + 1); // 加载下一页
    } else {
      print(
          "无法导航到下一页 (当前页: $_currentPage, 总页数: $_totalPages, 加载中: $_isLoadingData)");
    }
  }

  /// Go to Specific Page (Internal - Called by Dialog/Controls)
  Future<void> _goToPage(int pageNumber) async {
    print("尝试跳转到指定页 (来自 PaginationControls): $pageNumber");
    if (pageNumber >= 1 &&
        pageNumber <= _totalPages &&
        pageNumber != _currentPage &&
        !_isLoadingData) {
      _stopWatchingCache();
      print("执行跳转到页: $pageNumber");
      await _loadGames(pageToFetch: pageNumber);
    } else if (pageNumber == _currentPage && mounted) {
      print("已经在目标页: $pageNumber");
      // AppSnackBar.showInfo(context, '已在第 $pageNumber 页'); // 可以选择性保留提示
    } else if (!_isLoadingData && mounted) {
      print("跳转页码无效: $pageNumber (总页数: $_totalPages)");
      // AppSnackBar.showWarning(context, '无效的页码: $pageNumber'); // 可以选择性保留提示
    } else if (_isLoadingData) {
      print("正在加载中，无法跳转");
    }
  }

  /// Shows filter/sort dialog.
  void _showFilterDialog(BuildContext context) async {
    // 改为 async
    // 1. 在调用 show 之前定义临时状态变量
    String? tempSelectedTag = _currentTag;
    String tempSortBy = _currentSortBy;
    bool tempDescending = _isDescending;

    // 2. 调用 BaseInputDialog.show<bool> (返回 bool 表示是否确认)
    final confirmed = await BaseInputDialog.show<bool>(
      context: context,
      title: '筛选与排序',
      confirmButtonText: '应用',
      // 3. contentBuilder 包含 StatefulBuilder 来管理临时状态
      contentBuilder: (dialogContext) {
        // 使用 StatefulBuilder 使得对话框内部的内容可以局部刷新
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              // 确保内容可滚动
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('按标签筛选:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: tempSelectedTag, // 使用临时变量
                    hint: const Text('所有标签'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('所有标签')),
                      ..._availableTags.map((tag) => DropdownMenuItem<String?>(
                          value: tag.name,
                          child: Text('${tag.name} (${tag.count})'))),
                    ],
                    onChanged: (String? newValue) => setDialogState(
                        () => tempSelectedTag = newValue), // 更新临时变量
                  ),
                  const SizedBox(height: 16),
                  Text('排序方式:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  // 注意: 这里传递的是临时变量和更新临时变量的回调
                  ..._sortOptions.entries.map((entry) => _buildSortOptionTile(
                        title: entry.value,
                        sortField: entry.key,
                        currentSortBy: tempSortBy, // 传临时变量
                        isDescending: tempDescending, // 传临时变量
                        onChanged: (field, desc) {
                          setDialogState(() {
                            // 更新临时变量
                            tempSortBy = field;
                            tempDescending = desc;
                          });
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
      // 4. onConfirm 确认时返回 true
      onConfirm: () async {
        // 确认按钮按下，表示用户希望应用更改
        // 不需要在这里做复杂的逻辑，直接返回 true 即可关闭对话框
        return true; // 返回非 null 值表示确认成功，对话框将关闭
      },
      // 可选: 添加图标等
      iconData: Icons.filter_list_alt,
    );

    // 5. 对话框关闭后，如果用户点击了 "应用" (confirmed == true)
    if (confirmed == true && mounted) {
      // 使用更新后的临时变量调用应用逻辑
      _handleFilterDialogConfirm(tempSelectedTag, tempSortBy, tempDescending);
    }
  }

  /// Builds sort option tile for the dialog.
  Widget _buildSortOptionTile({
    required String title,
    required String sortField,
    required String currentSortBy,
    required bool isDescending,
    required Function(String, bool) onChanged,
  }) {
    final bool isSelected = currentSortBy == sortField;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      selected: isSelected,
      selectedTileColor: Colors.grey.withOpacity(0.1),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: () {
        // onTap 是 VoidCallback
        if (!isSelected) onChanged(sortField, true);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_upward),
              iconSize: 20,
              color: isSelected && !isDescending
                  ? colorScheme.secondary
                  : Colors.grey,
              tooltip: '升序',
              onPressed: () =>
                  onChanged(sortField, false), // onPressed 是 VoidCallback
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero),
          IconButton(
              icon: const Icon(Icons.arrow_downward),
              iconSize: 20,
              color: isSelected && isDescending
                  ? colorScheme.secondary
                  : Colors.grey,
              tooltip: '降序',
              onPressed: () =>
                  onChanged(sortField, true), // onPressed 是 VoidCallback
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  /// Applies filter/sort and triggers refresh. (调用 _loadGames 刷新第一页)
  void _applyTagAndSort(String? newTag, String newSortBy, bool newDescending) {
    bool tagChanged = _currentTag != newTag;
    bool sortChanged = _currentSortBy != newSortBy || _isDescending != newDescending;

    if (tagChanged || sortChanged) {
      print("GamesListScreen _applyTagAndSort: Applying state -> tag='$newTag', sort='$newSortBy', desc=$newDescending");
      _stopWatchingCache(); // 停止旧状态的监听
      setState(() {
        // 更新内部状态
        _currentTag = newTag;
        _currentSortBy = newSortBy;
        _isDescending = newDescending;
        // 重置分页和错误信息
        _currentPage = 1;
        _totalPages = 1;
        _errorMessage = null;
        _gamesList = []; // 立即清空列表以提供视觉反馈
      });
      // 触发第一页加载
      _loadGames(pageToFetch: 1, isRefresh: true);
    } else {
      print("GamesListScreen _applyTagAndSort: State unchanged.");
    }
  }

  void _clearTagFilter() {
    print("GamesListScreen: Clear tag button pressed.");
    // 1. 调用 apply 函数更新页面状态并触发加载
    _applyTagAndSort(null, _currentSortBy, _isDescending);
    // 2. 同步更新 Provider 状态
    _filterProvider?.clearTag(); // clearTag 会设置 tag=null 并标记
    // 3. 因为是页面内部操作触发，立即重置标志位
    _filterProvider?.resetTagFlag();
  }
  // 筛选对话框确认
  void _handleFilterDialogConfirm(String? newTag, String newSortBy, bool newDescending) {
    print("GamesListScreen: Filter dialog confirmed -> tag='$newTag', sort='$newSortBy', desc=$newDescending");
    // 1. 调用 apply 函数更新页面状态并触发加载
    _applyTagAndSort(newTag, newSortBy, newDescending);
    // 2. 同步更新 Provider 状态
    if (_filterProvider?.selectedTag != newTag) {
      _filterProvider?.setTag(newTag);
    }
    // 3. 因为是页面内部操作触发，立即重置标志位
    _filterProvider?.resetTagFlag();
  }


  // 移动端 TagBar 选择
  void _handleTagBarSelected(String? tag) {
    final newTag = (_currentTag == tag) ? null : tag; // 点击相同 tag 则取消
    print("GamesListScreen: TagBar selected -> newTag='$newTag'");
    // 1. 调用 apply 函数更新页面状态并触发加载
    _applyTagAndSort(newTag, _currentSortBy, _isDescending);
    // 2. 同步更新 Provider 状态
    if (_filterProvider?.selectedTag != newTag) {
      _filterProvider?.setTag(newTag);
    }
    // 3. 因为是页面内部操作触发，立即重置标志位
    _filterProvider?.resetTagFlag();
  }

  /// Handles delete action (using your original onConfirm logic).
  Future<void> _handleDeleteGame(String gameId) async {
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要删除这个游戏吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever,
      iconColor: Colors.red,
      onConfirm: () async {
        // onConfirm 是 AsyncCallback?
        print("尝试删除游戏: $gameId");
        try {
          await _gameService.deleteGame(gameId);
          print("游戏删除成功: $gameId");
          // 刷新由 cache watcher 触发
        } catch (e) {
          print("删除游戏失败: $gameId, Error: $e");
          if (mounted) AppSnackBar.showError(context, '删除失败: $e');
        }
      },
    );
  }

  /// Handles add action. (调用 _refreshDataIfNeeded)
  void _handleAddGame() {
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) {
      if (result == true && mounted) {
        print("添加游戏成功，触发刷新");
        _refreshDataIfNeeded(reason: "Add Game Completed"); // 触发刷新
      }
    });
  }

  /// Toggles Desktop Left Panel.
  void _toggleLeftPanel() => setState(() => _showLeftPanel = !_showLeftPanel);

  /// Toggles Desktop Right Panel.
  void _toggleRightPanel() =>
      setState(() => _showRightPanel = !_showRightPanel);

  // === Build Methods ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // AppBar 不包含跳页按钮
      body: VisibilityDetector(
        key: const ValueKey('games_list_visibility_detector'),
        onVisibilityChanged: _handleVisibilityChange,
        child: _buildBodyContent(),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar:
          _buildFloatingPaginationControlsIfNeeded(), // <--- 构建悬浮分页控件
    );
  }

  /// Builds the AppBar. (移除了跳页按钮)
  PreferredSizeWidget _buildAppBar() {
    final isDesktop = DeviceUtils.isDesktop;
    final title = _currentTag != null ? '标签: $_currentTag' : '游戏列表';
    final theme = Theme.of(context);
    final appBarColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final iconColor =
        ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final secondaryColor = theme.colorScheme.secondary;
    final screenWidth = MediaQuery.of(context).size.width;
    final canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;

    return CustomAppBar(
      title: title,
      actions: [
        if (isDesktop)
          IconButton(
            icon: Icon(Icons.menu_open,
                color: _showLeftPanel && canShowLeftPanelBasedOnWidth
                    ? secondaryColor
                    : iconColor),
            tooltip: _showLeftPanel ? '隐藏左侧面板' : '显示左侧面板',
            onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
          ),
        if (isDesktop)
          IconButton(
            icon: Icon(Icons.bar_chart_outlined,
                color: _showRightPanel && canShowRightPanelBasedOnWidth
                    ? secondaryColor
                    : iconColor),
            tooltip: _showRightPanel ? '隐藏右侧面板' : '显示右侧面板',
            onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
          ),
        // 有审核机制
        // 不需要admincheck
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
          onPressed: _isLoadingData ? null : _handleAddGame,
          tooltip: '添加游戏',
        ),
        IconButton(
          icon: Icon(Icons.history_edu, color: iconColor),
          onPressed: _isLoadingData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.myGames),
          tooltip: '我的提交',
        ),
        IconButton(
          icon: Icon(Icons.search, color: iconColor),
          onPressed: _isLoadingData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.searchGame),
          tooltip: '搜索游戏',
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: iconColor),
          onPressed: _isLoadingData ? null : () => _showFilterDialog(context),
          tooltip: '筛选与排序',
        ),
        if (_currentTag != null)
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _isLoadingData ? null : _clearTagFilter, // 调用新的处理函数
            tooltip: '清除标签筛选',
          ),
        if (!isDesktop)
          IconButton(
            icon: Icon(Icons.tag,
                color: _showMobileTagBar ? secondaryColor : iconColor),
            onPressed: () =>
                setState(() => _showMobileTagBar = !_showMobileTagBar),
            tooltip: _showMobileTagBar ? '隐藏标签栏' : '显示标签栏',
          ),
      ],
      bottom: (!DeviceUtils.isDesktop && _showMobileTagBar && _availableTags.isNotEmpty)
          ? TagBar(
        tags: _availableTags,
        selectedTag: _currentTag, // 使用内部状态
        onTagSelected: _handleTagBarSelected, // 调用新的处理函数
      )
          : null,
    );
  }





  /// Builds the main body content.
  Widget _buildBodyContent() {
    final isDesktop = DeviceUtils.isDesktop;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool shouldShowLeftPanel =
        isDesktop && _showLeftPanel && (screenWidth >= _hideLeftPanelThreshold);
    final bool shouldShowRightPanel = isDesktop &&
        _showRightPanel &&
        (screenWidth >= _hideRightPanelThreshold);
    const Duration panelAnimationDuration = Duration(milliseconds: 300);
    const Duration leftPanelDelay = Duration(milliseconds: 50);
    const Duration rightPanelDelay = Duration(milliseconds: 100);

    return RefreshIndicator(
      onRefresh: _refreshData, // onRefresh 需要 Future<void> Function()
      child: Stack(
        children: [
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shouldShowLeftPanel)
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_left_panel'),
                        slideDirection: SlideDirection.left,
                        duration: panelAnimationDuration,
                        delay: leftPanelDelay,
                        child: GameLeftPanel(
                          tags: _availableTags,
                          selectedTag: _currentTag,
                          onTagSelected: _isLoadingData
                              ? (String? tag) {}
                              : _handleTagBarSelected, // onTagSelected 需要 Function(String?)?
                        ),
                      ),
                    Expanded(
                      child: _buildMainContentArea(
                          isDesktop, shouldShowLeftPanel, shouldShowRightPanel),
                    ),
                    if (shouldShowRightPanel &&
                        (_isInitialized || _gamesList.isNotEmpty))
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_right_panel'),
                        slideDirection: SlideDirection.right,
                        duration: panelAnimationDuration,
                        delay: rightPanelDelay,
                        child: GameRightPanel(
                          currentPageGames: _gamesList,
                          totalGamesCount: _totalPages * _pageSize,
                          selectedTag: _currentTag,
                          onTagSelected: _isLoadingData
                              ? null
                              : _handleTagBarSelected, // onTagSelected 需要 Function(String?)?
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildMainContentArea(isDesktop, false, false),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// Builds the central content area (loading, error, empty, or grid).
  Widget _buildMainContentArea(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    if (!_isInitialized) {
      return FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载游戏...'));
    }

    if (_errorMessage != null && _gamesList.isEmpty && !_isLoadingData) {
      return InlineErrorWidget(
        errorMessage: _errorMessage!,
        // --- 修正: 明确使用函数体 ---
        onRetry: () {
          _loadGames(pageToFetch: 1, isRefresh: true);
        }, // onRetry 是 VoidCallback?
      );
    }

    if (!_isLoadingData && _errorMessage == null && _gamesList.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildGameGridWithNavigation(isDesktop, showLeftPanel, showRightPanel),
        if (_isLoadingData && _gamesList.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: LoadingWidget.inline(message: '加载中...'),
            ),
          ),
        if (_isLoadingData && _gamesList.isEmpty && _errorMessage == null)
          LoadingWidget.inline(message: '正在加载游戏...'),
      ],
    );
  }

  // !!!!!!!!!!!!!!!!!!!
  // 这是判断对于目前用户哪一个游戏能够有删除权限的
  bool _checkPermissionDeleteGame(Game game,BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context,listen: false);
    if (game.authorId == authProvider.currentUserId) {
      return true;
    }
    if (authProvider.isAdmin) {
      return true;
    }
    return false;
  }

  /// Builds the GridView with In-Grid Navigation Tiles.
  Widget _buildGameGridWithNavigation(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    final bool withPanels = isDesktop && (showLeftPanel || showRightPanel);
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context,
        withPanels: withPanels,
        leftPanelVisible: showLeftPanel,
        rightPanelVisible: showRightPanel);
    if (cardsPerRow <= 0) {
      print("错误：计算出的每行卡片数为 $cardsPerRow");
      return InlineErrorWidget(errorMessage: "无法计算布局 (cardsPerRow <= 0)");
    }
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
            context, showLeftPanel, showRightPanel,
            showTags: true)
        : DeviceUtils.calculateSimpleCardRatio(context, showTags: true);
    if (cardRatio <= 0) {
      print("错误：计算出的卡片宽高比为 $cardRatio");
      return InlineErrorWidget(errorMessage: "无法计算布局 (cardRatio <= 0)");
    }

    int totalItemCount = _gamesList.length;
    final bool showPrevTile = _currentPage > 1 && _totalPages > 1;
    final bool showNextTile = _currentPage < _totalPages;

    if (_gamesList.isNotEmpty ||
        (_isLoadingData && (_isInitialized || _currentPage == 1))) {
      if (showPrevTile) totalItemCount++;
      if (showNextTile) totalItemCount++;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        key: ValueKey(
            'game_grid_page_${_currentPage}_count_${_gamesList.length}_total_$totalItemCount'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0), // 底部留白
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
        ),
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          int gameIndex = index;
          bool isPrevTileRender = false;
          bool isNextTileRender = false;

          if (showPrevTile && index == 0) {
            isPrevTileRender = true;
          } else if (showPrevTile) {
            gameIndex = index - 1;
          }
          if (showNextTile && index == totalItemCount - 1) {
            isNextTileRender = true;
          }

          if (isPrevTileRender) {
            return _buildNavigationTile(isPrevious: true, cardRatio: cardRatio);
          } else if (isNextTileRender) {
            return _buildNavigationTile(
                isPrevious: false, cardRatio: cardRatio);
          } else {
            if (gameIndex < 0 || gameIndex >= _gamesList.length) {
              print(
                  "警告: 计算出的 gameIndex ($gameIndex) 超出列表范围 (0-${_gamesList.length - 1}) at Grid index $index");
              return const SizedBox.shrink();
            }
            final game = _gamesList[gameIndex];
            final animationDelayIndex = gameIndex % _pageSize;

            return FadeInSlideUpItem(
              key: ValueKey(game.id),
              delay: Duration(milliseconds: animationDelayIndex * 50),
              child: BaseGameCard(
                game: game,
                isGridItem: true,
                adaptForPanels: withPanels,
                showTags: true,
                showCollectionStats: true,
                forceCompact: useCompactMode,
                maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
                // 当加载中传递空回调，即使加载成功(加载成功后是false)如果没有权限也传递空回调
                onDeleteAction: _isLoadingData && !_checkPermissionDeleteGame(game,context)
                    ? null
                    : () {
                        _handleDeleteGame(game.id);
                      }, // onDeleteAction 是 VoidCallback?
              ),
            );
          }
        },
      );
    });
  }

  /// Builds a navigation tile (Previous or Next).
  Widget _buildNavigationTile(
      {required bool isPrevious, required double cardRatio}) {
    final bool canNavigate =
        isPrevious ? (_currentPage > 1) : (_currentPage < _totalPages);
    final IconData icon =
        isPrevious ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios;
    final String label = isPrevious ? '上一页' : '下一页';
    final String pageInfo = isPrevious
        ? '(${_currentPage - 1}/$_totalPages)'
        : '(${_currentPage + 1}/$_totalPages)';
    // --- 修正: 定义 action 为 VoidCallback? 并使用函数体 ---
    final VoidCallback? action = (_isLoadingData || !canNavigate)
        ? null
        : (isPrevious
            ? () {
                _goToPreviousPageInternal();
              }
            : () {
                _goToNextPageInternal();
              });

    return AspectRatio(
      aspectRatio: cardRatio,
      child: Opacity(
        opacity: action != null ? 1.0 : 0.5,
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: action, // onTap 是 VoidCallback?
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 24, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  pageInfo,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state widget. (Corrected onPressed)
  Widget _buildEmptyState() {
    String message =
        _currentTag != null ? '没有找到标签为 “$_currentTag” 的游戏' : '这里还没有游戏呢';
    return EmptyStateWidget(
      iconData: Icons.videogame_asset_off_outlined,
      message: message,
      action: _currentTag != null
          ? FunctionalButton(
              onPressed: _isLoadingData
                  ? () {}
                  : () =>
                      // 使用明确的函数体
                      _applyTagAndSort(null, _currentSortBy, _isDescending),
              label: '查看全部游戏',
              icon: Icons.list_alt,
            )
          : FunctionalButton(
              onPressed: _isLoadingData ? () {} : _handleAddGame, // 直接传递引用，签名匹配
              label: '添加一个游戏',
              icon: Icons.add,
            ),
    );
  }

  /// Builds the Floating Action Button.
  Widget? _buildFab() {
    if (_isLoadingData) return null; // 加载时不显示

    return GenericFloatingActionButton(
      onPressed: _handleAddGame, // onPressed 是 VoidCallback?
      icon: Icons.add,
      tooltip: '添加游戏',
      heroTag: 'games_list_fab',
    );
  }

  /// Builds the floating pagination controls if needed.
  Widget? _buildFloatingPaginationControlsIfNeeded() {
    // 关键逻辑：只有在初始化完成并且总页数大于1时才需要显示分页控件
    // PaginationControls 组件内部会处理 totalPages <= 1 的情况，所以这里主要判断是否初始化
    if (!_isInitialized) {
      return null; // 初始化完成前不显示任何东西
    }

    // 直接使用你提供的 PaginationControls 组件
    return PaginationControls(
      currentPage: _currentPage,
      totalPages: _totalPages,
      isLoading: _isLoadingData,
      onPreviousPage: _goToPreviousPageInternal,
      onNextPage: _goToNextPageInternal,
      onPageSelected: _goToPage, // 当用户在下拉框选择页码时，调用 _goToPage
    );
  }
} // End of _GamesListScreenState
