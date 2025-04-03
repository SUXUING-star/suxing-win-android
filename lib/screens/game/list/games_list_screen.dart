// lib/screens/game/games_list_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'base_game_list_screen.dart';
import '../../../widgets/ui/components/pagination_controls.dart'; // <--- 引入分页 UI 组件


class GamesListScreen extends StatefulWidget {
  final String? selectedTag;

  const GamesListScreen({
    Key? key,
    this.selectedTag,
  }) : super(key: key);

  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  final GameService _gameService = GameService();

  // --- 分页、加载、错误状态 ---
  bool _isLoading = false; // 添加加载状态
  bool _isPaginating = false;
  String? _errorMessage; // 添加错误消息状态
  int _currentPage = 1;

  int _totalPages = 1;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;
  String? _currentTag; // 当前选中的标签
  ValueKey<String> _loadTriggerKey = ValueKey('initial');


  @override
  void initState() {
    super.initState();
    _currentTag = widget.selectedTag;
  }

  // --- 修改 _loadGames 方法，增加 Loading 和 Error 状态处理 ---
  Future<List<Game>> _loadGames(String? tag) async {
    final bool isManualPagination = _loadTriggerKey.value.toString().contains('_manual');
    print(">>> _loadGames START - isManual: $isManualPagination, current loading: $_isLoading, current paginating: $_isPaginating, currentPage: $_currentPage");

    // --- 设置加载状态 (修改！) ---
    bool actuallySetLoading = false; // 标记本次调用是否设置了 loading
    if (!_isLoading) {
      // 直接在 setState 中设置，或者如果担心在 build 中调用 setState，用 microtask
      // 为了安全起见，用 microtask 包裹 setState 调用
      if(mounted) {
        Future.microtask(() { // 使用微任务，比 addPostFrameCallback 更快执行
          if (mounted && !_isLoading) { // 在微任务内部再次检查，防止状态变化
            setState(() {
              print(">>> Setting _isLoading = true (via microtask)");
              _isLoading = true;
              actuallySetLoading = true; // 标记一下
              if (isManualPagination && !_isPaginating) { // 如果是手动分页，也立即设置 isPaginating
                print(">>> Setting _isPaginating = true (via microtask)");
                _isPaginating = true;
              }
            });
          }
        });
      } else {
        // 组件卸载了，理论上不应该到这里，但也处理下
        print(">>> Warning: Attempting to set loading but not mounted.");
        // _isLoading = true; // 直接改内部状态可能导致不一致，最好避免
      }

    } else if (isManualPagination && !_isPaginating) {
      // 如果已经在 loading，但这次是手动分页触发，仍然需要确保 _isPaginating 被设置
      if(mounted) {
        Future.microtask(() {
          if (mounted && !_isPaginating) {
            setState(() {
              print(">>> Setting _isPaginating = true (while already loading, via microtask)");
              _isPaginating = true;
            });
          }
        });
      }
    }

    try {
      print(">>> Calling gameService for page: $_currentPage, tag: $tag");
      Map<String, dynamic> result;
      if (tag != null) {
        result = await _gameService.getGamesByTagWithInfo(
          tag: tag, page: _currentPage, sortBy: _currentSortBy, descending: _isDescending,
        );
      } else {
        result = await _gameService.getGamesPaginatedWithInfo(
          page: _currentPage, sortBy: _currentSortBy, descending: _isDescending,
        );
      }
      print(">>> gameService returned successfully.");

      final games = result['games'] as List<Game>? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final newTotalPages = pagination['totalPages'] as int? ?? 1;

      // --- 更新状态 (成功) ---
      if (mounted) {
        print(">>> SUCCESS: Updating state. New TotalPages: $newTotalPages");
        setState(() {
          _totalPages = newTotalPages; // 更新总页数
          _currentTag = tag;
          _errorMessage = null;
          print(">>> SUCCESS: Setting _isLoading = false, _isPaginating = false");
          _isLoading = false;       // *** 必须重置 ***
          _isPaginating = false;    // *** 必须重置 ***
        });
      } else {
        print(">>> SUCCESS but component unmounted.");
        _totalPages = newTotalPages; // Update internal value if needed
      }

      print(">>> _loadGames SUCCESS END");
      return games;

    } catch (e, s) { // 加上 StackTrace 好排查
      print(">>> ERROR in _loadGames: $e");
      print(">>> Stack Trace: $s"); // 打印堆栈信息！

      // --- 更新状态 (失败) ---
      if (mounted) {
        print(">>> ERROR: Updating state.");
        setState(() {
          _errorMessage = '加载失败: $e';
          print(">>> ERROR: Setting _isLoading = false, _isPaginating = false");
          _isLoading = false;       // *** 必须重置 ***
          _isPaginating = false;    // *** 必须重置 ***
          // 考虑错误时是否重置页码或总页数
          // _totalPages = 1; // 或者保持旧值？根据你的逻辑定
        });
      } else {
        print(">>> ERROR but component unmounted.");
      }
      print(">>> _loadGames ERROR END");
      // 抛出异常让 BaseGameListScreen 处理 UI 显示（如果它需要的话）
      throw e;
    }
  }
  // --- 刷新数据 ---
  Future<void> _refreshData() async {
    print("Refresh triggered. Resetting to page 1 and forcing reload.");
    if (_isLoading) return; // 防止重复触发

    setState(() {
      _currentPage = 1;
      // --- 改变 Key 来强制 BaseGameListScreen 重建并重新加载 ---
      _loadTriggerKey = ValueKey('refresh_${DateTime.now().millisecondsSinceEpoch}');
    });
  }

  // --- 翻页逻辑 ---
  Future<void> _goToPreviousPage() async {
    // 打印检查条件
    print("Attempting Previous Page: currentPage=$_currentPage, totalPages=$_totalPages, isLoading=$_isLoading, isPaginating=$_isPaginating");
    if (_currentPage > 1 && !_isLoading && !_isPaginating) { // 严格检查 isLoading 和 isPaginating
      print(">>> Condition met for Previous Page. CurrentPage before: $_currentPage");
      setState(() {
        // _isPaginating = true; // 在 _loadGames 里根据 key 判断设置更稳妥，这里可以不设
        _currentPage--;
        // 确保 key 真的改变了，加个时间戳
        _loadTriggerKey = ValueKey('page_${_currentPage}_manual_${DateTime.now().millisecondsSinceEpoch}');
        print(">>> Set new key: ${_loadTriggerKey.value}. CurrentPage after: $_currentPage");
      });
    } else {
      print(">>> Condition NOT met for Previous Page.");
    }
  }
  // 排序对话框
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('排序方式'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [ /* ... _buildSortOption ... */ ]),
          actions: [ TextButton(onPressed: () => NavigationUtils.pop(context), child: Text('取消')),],
        );
      },
    );
  }

  Widget _buildSortOption(String title, String sortField) {
    final isSelected = _currentSortBy == sortField;
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_upward,
              color: isSelected && !_isDescending ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              NavigationUtils.pop(context);
              setState(() { _currentSortBy = sortField; _isDescending = false; _currentPage = 1; }); // 重置页码
              _forceReload(); // 强制重新加载
            },
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_downward,
              color: isSelected && _isDescending ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              NavigationUtils.pop(context);
              setState(() { _currentSortBy = sortField; _isDescending = true; _currentPage = 1; }); // 重置页码
              _forceReload(); // 强制重新加载
            },
          ),
        ],
      ),
      onTap: () {
        NavigationUtils.pop(context);
        setState(() { _currentSortBy = sortField; _isDescending = true; _currentPage = 1; }); // 重置页码
        _forceReload(); // 强制重新加载
      },
    );
  }
  Future<void> _goToNextPage() async {
    print("Attempting Next Page: currentPage=$_currentPage, totalPages=$_totalPages, isLoading=$_isLoading, isPaginating=$_isPaginating");
    if (_currentPage < _totalPages && !_isLoading && !_isPaginating) { // 严格检查
      print(">>> Condition met for Next Page. CurrentPage before: $_currentPage");
      setState(() {
        // _isPaginating = true; // 同上
        _currentPage++;
        _loadTriggerKey = ValueKey('page_${_currentPage}_manual_${DateTime.now().millisecondsSinceEpoch}');
        print(">>> Set new key: ${_loadTriggerKey.value}. CurrentPage after: $_currentPage");
      });
    } else {
      print(">>> Condition NOT met for Next Page.");
      if (_currentPage >= _totalPages) print("Reason: Already on last page or totalPages incorrect?");
      if (_isLoading) print("Reason: isLoading is true.");
      if (_isPaginating) print("Reason: isPaginating is true.");
    }
  }

  // 标签选择回调 - BaseGameListScreen 的 onTagSelected 会调用这个
  void _handleTagSelected(String? tag) {
    if (_currentTag != tag) {
      print("Tag selected via Base: $tag");
      setState(() {
        _currentTag = tag;
        _currentPage = 1; // 重置页码
      });
      _forceReload(); // 强制重新加载
    }
  }

  void _handleGameTap(Game game) {
    // Assemble context HERE, because this state knows the list parameters
    final Map<String, dynamic> listContext = {
      'page': _currentPage,
      // 'pageSize' is handled by GameService internally now
      'sortBy': _currentSortBy,
      'descending': _isDescending,
      'tag': _currentTag, // Use the current tag from this state
      'listType': _currentTag != null ? 'tag' : 'all',
      // Add 'authorId' if applicable
    };

    print("Navigate from GamesListScreen for ${game.id}. Context: $listContext");

    NavigationUtils.pushNamed(
      context,
      AppRoutes.gameDetail,
      arguments: {
        'gameId': game.id,
        'listContext': listContext, // Pass the context
      },
    );
  }

  // 强制重新加载的辅助方法
  void _forceReload() {
    if (_isLoading) return;
    setState(() {
      _loadTriggerKey = ValueKey('force_reload_${DateTime.now().millisecondsSinceEpoch}');
    });
  }


  @override
  Widget build(BuildContext context) {
    // --- 返回 BaseGameListScreen，并覆盖 PaginationControls ---
    return Stack( // 使用 Stack 来覆盖
      children: [
        // --- BaseGameListScreen 作为底层 ---
        BaseGameListScreen(
          key: _loadTriggerKey, // <--- 使用变化的 Key 来强制刷新
          title: '游戏',
          loadGamesFunction: (tag) => _loadGames(tag),
          refreshFunction: _refreshData,

          // --- 其他参数保持不变 ---
          showTagSelection: true,
          selectedTag: _currentTag,
          showSortOptions: true, // 控制 Base AppBar 是否显示排序按钮
          onFilterPressed: (context) => _showFilterDialog(context), // 排序按钮的回调

          onItemTap: _handleGameTap,

          showAddButton: true, // FAB按钮
          onAddPressed: () { NavigationUtils.pushNamed(context, AppRoutes.addGame); },

          emptyStateMessage: '暂无游戏数据',
          showPanelToggles: true,

          // --- 让 Base 创建 Scaffold 和 AppBar ---
          useScaffold: true, // Base 创建 Scaffold
          showAddButtonInAppBar: true,
          showMySubmissionsButton: true,
          onMySubmissionsPressed: () { NavigationUtils.pushNamed(context, AppRoutes.myGames); },

        ),

        // --- PaginationControls 覆盖在底部 ---
        // 使用 Align 或 Positioned 将其固定在底部
        Align(
          alignment: Alignment.bottomCenter,
          child: Container( // 加个背景挡住下面的内容
            child: PaginationControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              isLoading: _isPaginating, // 使用 GamesListScreen 的加载状态
              onPreviousPage: _goToPreviousPage,
              onNextPage: _goToNextPage,
            ),
          ),
        ),
      ],
    );
  }
}