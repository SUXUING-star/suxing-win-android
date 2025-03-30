// lib/screens/collection/game_collection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // Tab控制器
  late TabController _tabController;

  // 存储游戏数据和加载状态
  Map<String, List<GameWithCollection>> _gameCollections = {
    'wantToPlay': [],
    'playing': [],
    'played': [],
  };

  Map<String, bool> _isLoading = {
    'wantToPlay': true,
    'playing': true,
    'played': true,
  };

  Map<String, String?> _errors = {
    'wantToPlay': null,
    'playing': null,
    'played': null,
  };

  // 记录每列游戏数量
  final Map<String, int> _tabCounts = {
    'wantToPlay': 0,
    'playing': 0,
    'played': 0,
  };

  // 存储是否为桌面布局
  bool _isDesktopLayout = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 初始加载所有数据
    _loadAllCollections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 加载所有收藏数据
  Future<void> _loadAllCollections() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 检查用户是否登录
    if (!authProvider.isLoggedIn) {
      _setErrorForAll('请先登录后再查看收藏');
      return;
    }

    // 加载三种类型的收藏
    await Future.wait([
      _loadCollection('wantToPlay'),
      _loadCollection('playing'),
      _loadCollection('played'),
    ]);

    // 更新计数
    if (mounted) {
      setState(() {
        for (var key in _gameCollections.keys) {
          _tabCounts[key] = _gameCollections[key]?.length ?? 0;
        }
      });
    }
  }

  // 加载特定类型的收藏
  Future<void> _loadCollection(String collectionType) async {
    if (!mounted) return;

    setState(() {
      _isLoading[collectionType] = true;
      _errors[collectionType] = null;
    });

    try {
      // 获取状态对应的值
      String status;
      switch (collectionType) {
        case 'wantToPlay':
          status = GameCollectionStatus.wantToPlay;
          break;
        case 'playing':
          status = GameCollectionStatus.playing;
          break;
        case 'played':
          status = GameCollectionStatus.played;
          break;
        default:
          status = collectionType;
      }

      // 加载游戏数据
      final games = await _collectionService.getUserGamesByStatus(status);

      if (mounted) {
        setState(() {
          _gameCollections[collectionType] = games;
          _isLoading[collectionType] = false;
          _tabCounts[collectionType] = games.length;
        });
      }
    } catch (e) {
      print('Load collection games error: $e');
      if (mounted) {
        setState(() {
          _errors[collectionType] = '加载收藏游戏失败：$e';
          _isLoading[collectionType] = false;
        });
      }
    }
  }

  // 为所有收藏类型设置错误信息
  void _setErrorForAll(String error) {
    setState(() {
      for (var key in _errors.keys) {
        _errors[key] = error;
        _isLoading[key] = false;
      }
    });
  }

  // 刷新指定类型的收藏
  Future<void> _refreshCollection(String collectionType) async {
    await _loadCollection(collectionType);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;

    // 确定布局类型
    _isDesktopLayout = isDesktop && screenSize.width > 900;

    // 先检查用户是否登录
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: CustomAppBar(title: '我的游戏'),
        body: LoginPromptWidget(isDesktop: _isDesktopLayout),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: '我的游戏',
      ),
      body: _isDesktopLayout ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 顶部标签栏
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              icon: Icon(Icons.star_border),
              text: '想玩${_tabCounts['wantToPlay']! > 0 ? ' ${_tabCounts['wantToPlay']}' : ''}',
            ),
            Tab(
              icon: Icon(Icons.videogame_asset),
              text: '在玩${_tabCounts['playing']! > 0 ? ' ${_tabCounts['playing']}' : ''}',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: '玩过${_tabCounts['played']! > 0 ? ' ${_tabCounts['played']}' : ''}',
            ),
          ],
        ),

        // 内容区域 - 使用Expanded确保TabBarView填充剩余空间
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent('wantToPlay'),
              _buildTabContent('playing'),
              _buildTabContent('played'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String collectionType) {
    // 加载中状态
    if (_isLoading[collectionType] == true) {
      return Center(child: CircularProgressIndicator());
    }

    // 错误状态
    if (_errors[collectionType] != null) {
      return _buildErrorWidget(
        _errors[collectionType]!,
            () => _refreshCollection(collectionType),
      );
    }

    // 正常显示游戏列表
    return MobileCollectionLayout(
      games: _gameCollections[collectionType] ?? [],
      onRefresh: () => _refreshCollection(collectionType),
      collectionType: collectionType,
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 想玩的游戏
          Expanded(
            child: _buildDesktopColumn(
              'wantToPlay',
              '想玩的游戏',
              Icons.star_border,
            ),
          ),
          const SizedBox(width: 16),

          // 在玩的游戏
          Expanded(
            child: _buildDesktopColumn(
              'playing',
              '在玩的游戏',
              Icons.videogame_asset,
            ),
          ),
          const SizedBox(width: 16),

          // 玩过的游戏
          Expanded(
            child: _buildDesktopColumn(
              'played',
              '玩过的游戏',
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopColumn(String collectionType, String title, IconData icon) {
    // 加载中状态
    if (_isLoading[collectionType] == true) {
      return _buildLoadingColumn(title, icon);
    }

    // 错误状态
    if (_errors[collectionType] != null) {
      return _buildErrorColumn(collectionType, title, icon);
    }

    // 正常显示游戏列表
    return DesktopCollectionLayout(
      games: _gameCollections[collectionType] ?? [],
      onRefresh: () => _refreshCollection(collectionType),
      collectionType: collectionType,
      title: title,
      icon: icon,
    );
  }

  // 桌面布局的加载中列
  Widget _buildLoadingColumn(String title, IconData icon) {
    return Column(
      children: [
        // 列标题
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12),

        // 加载指示器
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('加载中...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 桌面布局的错误列
  Widget _buildErrorColumn(String collectionType, String title, IconData icon) {
    return Column(
      children: [
        // 列标题
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12),

        // 错误信息
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  _errors[collectionType] ?? '未知错误',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _refreshCollection(collectionType),
                  child: Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建错误状态
  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('重试'),
          ),
        ],
      ),
    );
  }
}