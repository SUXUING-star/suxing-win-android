// lib/screens/collection/game_collection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

import '../../../models/game/game_collection.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../services/main/game/collection/game_collection_service.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/ui/common/error_widget.dart';
import '../../../widgets/ui/common/login_prompt_widget.dart';
import '../../../widgets/components/screen/gamecollection/layout/mobile_collection_layout.dart';
import '../../../widgets/components/screen/gamecollection/layout/desktop_collection_layout.dart';

class GameCollectionScreen extends StatefulWidget {
  const GameCollectionScreen({Key? key}) : super(key: key);

  @override
  _GameCollectionScreenState createState() => _GameCollectionScreenState();
}

class _GameCollectionScreenState extends State<GameCollectionScreen>
    with SingleTickerProviderStateMixin {
  final GameCollectionService _collectionService = GameCollectionService();
  late TabController _tabController;

  // --- 状态管理 (不变) ---
  Map<String, List<GameWithCollection>> _gameCollections = {
    GameCollectionStatus.wantToPlay: [],
    GameCollectionStatus.playing: [],
    GameCollectionStatus.played: [],
  };
  bool _isLoading = true;
  String? _error;
  Map<String, int> _tabCounts = {
    GameCollectionStatus.wantToPlay: 0,
    GameCollectionStatus.playing: 0,
    GameCollectionStatus.played: 0,
  };
  bool _isDesktopLayout = false;

  // *** 新增：用于跟踪上一次的登录状态 ***
  bool? _previousIsLoggedIn;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    print("GameCollectionScreen initState");

    // *** initState 中不应直接访问 Provider (如果 listen: true)，但可以 listen: false ***
    // *** 这里改为在 didChangeDependencies 中首次加载 ***
    // _loadDataIfNeeded(); // 不在这里加载，移到 didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("GameCollectionScreen didChangeDependencies");

    // *** 这是监听 Provider 变化和进行初始加载的正确地方 ***
    final authProvider = Provider.of<AuthProvider>(context); // 获取实例，但不监听 build
    final currentIsLoggedIn = authProvider.isLoggedIn;

    print(
        "didChangeDependencies: currentIsLoggedIn=$currentIsLoggedIn, _previousIsLoggedIn=$_previousIsLoggedIn");

    // --- 处理登录状态变化 ---
    // 只有当 _previousIsLoggedIn 不是 null (表示不是第一次运行)
    // 且当前登录状态与上次不同时，才处理变化
    if (_previousIsLoggedIn != null &&
        currentIsLoggedIn != _previousIsLoggedIn) {
      print("登录状态发生变化: $_previousIsLoggedIn -> $currentIsLoggedIn");
      if (currentIsLoggedIn) {
        // 刚登录，触发数据加载
        print("用户已登录，调用 _loadData");
        _loadData(); // 重新加载数据
      } else {
        // 刚登出，清空数据并显示提示
        print("用户已登出，清空数据并设置错误状态");
        if (mounted) {
          // 确保 widget 仍然挂载
          // ** 不直接 setState，而是设置状态变量，让 build 方法去处理 UI **
          // setState(() {
          //   _isLoading = false;
          //   _error = '请先登录后再查看收藏';
          //   _clearData();
          // });
          // 设置状态变量，build 会根据这些变量来渲染
          _isLoading = false;
          _error = '请先登录后再查看收藏';
          _clearData();
          // 调用 setState({}) 只是为了触发一次 build 来反映这些变化
          if (mounted) setState(() {});
        }
      }
    }
    // --- 首次加载逻辑 ---
    // 如果 _previousIsLoggedIn 是 null，表示这是第一次运行 didChangeDependencies
    // 或者是因为其他依赖变化（理论上这里只有 AuthProvider）
    else if (_previousIsLoggedIn == null) {
      print("首次运行 didChangeDependencies 或依赖初始化");
      if (currentIsLoggedIn) {
        print("用户已登录，执行首次数据加载");
        _loadData(); // 首次加载数据
      } else {
        print("用户未登录，设置初始状态");
        _isLoading = false;
        _error = '请先登录后再查看收藏';
        _clearData();
        // 调用 setState({}) 触发 build
        if (mounted) setState(() {});
      }
    }

    // *** 更新上一次的登录状态 ***
    _previousIsLoggedIn = currentIsLoggedIn;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- 数据加载方法 (保持不变，但调用时机改变) ---
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    // 移除 !forceRefresh && _isLoading 的判断，因为调用时机已在外部控制
    // if (!forceRefresh && _isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context,
        listen: false); // listen: false 因为不希望 build 因此重绘
    // ** 再次检查登录状态，因为可能是异步调用 **
    if (!authProvider.isLoggedIn) {
      print("_loadData: 用户未登录，取消加载");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '请先登录后再查看收藏';
          _clearData();
        });
      }
      return;
    }

    print("_loadData: 开始加载数据 (forceRefresh=$forceRefresh)");
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final groupedData = await _collectionService.getAllUserGamesGrouped(
          forceRefresh: forceRefresh);
      if (mounted) {
        if (groupedData != null) {
          setState(() {
            _gameCollections[GameCollectionStatus.wantToPlay] =
                groupedData.wantToPlay;
            _gameCollections[GameCollectionStatus.playing] =
                groupedData.playing;
            _gameCollections[GameCollectionStatus.played] = groupedData.played;
            _tabCounts[GameCollectionStatus.wantToPlay] =
                groupedData.counts.wantToPlay;
            _tabCounts[GameCollectionStatus.playing] =
                groupedData.counts.playing;
            _tabCounts[GameCollectionStatus.played] = groupedData.counts.played;
            _isLoading = false;
            _error = null;
          });
          print("_loadData: 数据加载成功");
        } else {
          setState(() {
            _isLoading = false;
            _error = '加载收藏数据失败 (null response)';
            _clearData();
          });
          print("_loadData: 加载失败 (null response)");
        }
      }
    } catch (e) {
      print('!!! _loadData error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载收藏失败: $e';
          _clearData();
        });
      }
    }
  }

  // 清空数据的辅助方法
  void _clearData() {
    _gameCollections = {
      GameCollectionStatus.wantToPlay: [],
      GameCollectionStatus.playing: [],
      GameCollectionStatus.played: [],
    };
    _tabCounts = {
      GameCollectionStatus.wantToPlay: 0,
      GameCollectionStatus.playing: 0,
      GameCollectionStatus.played: 0,
    };
  }

  // 下拉刷新 (保持不变)
  Future<void> _handleRefresh() async {
    print(">>> 执行下拉刷新...");
    await _loadData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    print("GameCollectionScreen build");
    // *** 不再需要在这里监听 AuthProvider 或处理登录状态变化 ***
    // final authProvider = context.watch<AuthProvider>();
    // WidgetsBinding.instance.addPostFrameCallback((_) { ... }); // *** 移除这整块 ***

    // 直接使用当前状态变量来决定显示什么
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false); // 获取实例用于判断
    final isLoggedIn =
        authProvider.isLoggedIn; // 或者直接使用 _previousIsLoggedIn (理论上此时应该同步了)

    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    _isDesktopLayout = isDesktop && screenSize.width > 900;

    return Scaffold(
      appBar: CustomAppBar(
        title: '我的游戏',
      ),
      // *** 直接调用 _buildBody，依赖当前的状态变量 ***
      body: _buildBody(isLoggedIn), // 传递当前获取的登录状态
    );
  }

  // 构建 Body (逻辑基本不变，依赖状态变量)
  Widget _buildBody(bool isLoggedIn) {
    print(
        "_buildBody: isLoading=$_isLoading, error=$_error, isLoggedIn=$isLoggedIn");
    // 1. 未登录
    if (!isLoggedIn && _error == '请先登录后再查看收藏') {
      // 明确检查错误信息
      print("_buildBody: 显示登录提示");
      return LoginPromptWidget(isDesktop: _isDesktopLayout);
    }

    // 2. 初始加载
    if (_isLoading &&
        _gameCollections.values.every((list) => list.isEmpty) &&
        _error == null) {
      print("_buildBody: 显示初始加载指示器");
      return LoadingWidget.inline(message: "正在加载收藏数据");
    }

    // 3. 加载出错
    if (_error != null && _error != '请先登录后再查看收藏') {
      return InlineErrorWidget(
        errorMessage: _error,
        onRetry: () {
          NavigationUtils.navigateToLogin(context);
        },
      );
    }

    // 4. 显示正常内容 (即使 _isLoading 为 true，只要有旧数据也显示，并允许刷新)
    print("_buildBody: 显示收藏列表");
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _isDesktopLayout ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // 构建 Mobile 布局
  Widget _buildMobileLayout() {
    // *** RefreshIndicator 在 _buildBody 中处理，这里直接返回 Column ***
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              icon: const Icon(Icons.star_border),
              // *** 使用常量作为 key 访问计数 ***
              text:
                  '想玩${_tabCounts[GameCollectionStatus.wantToPlay]! > 0 ? ' ${_tabCounts[GameCollectionStatus.wantToPlay]}' : ''}',
            ),
            Tab(
              icon: const Icon(Icons.videogame_asset),
              text:
                  '在玩${_tabCounts[GameCollectionStatus.playing]! > 0 ? ' ${_tabCounts[GameCollectionStatus.playing]}' : ''}',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text:
                  '玩过${_tabCounts[GameCollectionStatus.played]! > 0 ? ' ${_tabCounts[GameCollectionStatus.played]}' : ''}',
            ),
          ],
        ),
        Expanded(
          // TabBarView 本身不支持直接下拉刷新，需要 RefreshIndicator 包裹在外面
          child: TabBarView(
            controller: _tabController,
            children: [
              // *** 调用简化的 MobileCollectionLayout，不再传递 onRefresh ***
              MobileCollectionLayout(
                games: _gameCollections[GameCollectionStatus.wantToPlay] ?? [],
                collectionType: GameCollectionStatus.wantToPlay,
              ),
              MobileCollectionLayout(
                games: _gameCollections[GameCollectionStatus.playing] ?? [],
                collectionType: GameCollectionStatus.playing,
              ),
              MobileCollectionLayout(
                games: _gameCollections[GameCollectionStatus.played] ?? [],
                collectionType: GameCollectionStatus.played,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建 Desktop 布局
  Widget _buildDesktopLayout() {
    // *** RefreshIndicator 在 _buildBody 中处理 ***
    // 如果希望桌面端也能下拉刷新，需要让 Row 可滚动，例如包在 ListView 中
    // 这里假设桌面端不需要下拉刷新，RefreshIndicator 主要对移动端生效
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // *** 调用简化的 DesktopCollectionLayout，不再传递 onRefresh ***
            child: DesktopCollectionLayout(
              games: _gameCollections[GameCollectionStatus.wantToPlay] ?? [],
              collectionType: GameCollectionStatus.wantToPlay,
              title:
                  '想玩的游戏 (${_tabCounts[GameCollectionStatus.wantToPlay]})', // 标题中直接显示数量
              icon: Icons.star_border,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DesktopCollectionLayout(
              games: _gameCollections[GameCollectionStatus.playing] ?? [],
              collectionType: GameCollectionStatus.playing,
              title: '在玩的游戏 (${_tabCounts[GameCollectionStatus.playing]})',
              icon: Icons.videogame_asset,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DesktopCollectionLayout(
              games: _gameCollections[GameCollectionStatus.played] ?? [],
              collectionType: GameCollectionStatus.played,
              title: '玩过的游戏 (${_tabCounts[GameCollectionStatus.played]})',
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
}
