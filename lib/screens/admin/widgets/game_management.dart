// lib/screens/admin/widgets/game_management.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../services/main/game/game_service.dart';
import '../../../models/game/game.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../game/edit/edit_game_screen.dart';
import '../../game/edit/add_game_screen.dart';
import '../../game/list/base_game_list_screen.dart';
import '../../../widgets/ui/dialogs/confirm_dialog.dart'; // 导入 ConfirmDialog

class GameManagement extends StatefulWidget {
  const GameManagement({Key? key}) : super(key: key);

  @override
  State<GameManagement> createState() => _GameManagementState();
}

class _GameManagementState extends State<GameManagement> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  // 添加状态变量跟踪是否需要刷新
  bool _needRefresh = true;
  // 添加一个key来触发FutureBuilder的重新构建
  final GlobalKey _futureBuilderKey = GlobalKey();

  // 添加TabController
  late TabController _tabController;

  // 添加状态变量
  bool _isLoading = false;
  List<Game> _pendingGames = [];
  List<Game> _rejectedGames = [];

  @override
  void initState() {
    super.initState();
    // 初始化标签控制器 - 3个标签：游戏管理、待审核游戏、被拒绝游戏
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // 当标签切换时刷新数据
      if (!_tabController.indexIsChanging) {
        setState(() {
          _needRefresh = true;
          _isLoading = true;
        });
        _loadData();
      }
    });

    // 初始加载数据
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_isLoading) return;

    try {
      switch (_tabController.index) {
        case 0: // 游戏管理标签 - 使用原有方法，不需要额外处理
          break;
        case 1: // 待审核游戏标签
          final result = await _gameService.getPendingGamesWithInfo(
            page: 1,
            pageSize: 100,
          );
          if (mounted) {
            setState(() {
              _pendingGames = result['games'];
              _isLoading = false;
            });
          }
          break;
        case 2: // 被拒绝游戏标签
          final result = await _gameService.getUserRejectedGamesWithInfo(
            page: 1,
            pageSize: 100,
          );
          if (mounted) {
            setState(() {
              _rejectedGames = result['games'];
              _isLoading = false;
            });
          }
          break;
      }
    } catch (e) {
      print('加载数据失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 只保留TabBar，不使用AppBar
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '游戏管理'),
            Tab(text: '待审核游戏'),
            Tab(text: '被拒绝游戏'),
          ],
          // 调整TabBar样式以适应非AppBar环境
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 游戏管理标签内容 - 使用 BaseGameListScreen
              _buildAllGamesTab(),

              // 待审核游戏标签内容
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _loadData();
                },
                child: _buildPendingGamesList(),
              ),

              // 被拒绝游戏标签内容
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _loadData();
                },
                child: _buildRejectedGamesList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Future<List<Game>> _loadGames(String? tag) async {
    final games = await _gameService.getGamesPaginated(
      page: 1,
      pageSize: 100,
      sortBy: 'createTime',
      descending: true,
    );
    return games;
  }
  // 使用 BaseGameListScreen 构建所有游戏标签
  Widget _buildAllGamesTab() {
    return BaseGameListScreen(
      title: '游戏管理',
      useScaffold: false, // 不使用内置的 Scaffold
      loadGamesFunction: _loadGames,
      refreshFunction: () async {
        setState(() {
          _needRefresh = true;
        });
      },
      emptyStateMessage: '暂无游戏数据',
      showAddButton: true,
      onAddPressed: () {
        NavigationUtils.push(
          context,
          MaterialPageRoute(builder: (context) => AddGameScreen()),
        ).then((_) {
          // 当从添加游戏页面返回时刷新列表
          setState(() {
            _needRefresh = true;
          });
        });
      },
      // 自定义卡片构建函数，添加编辑和删除按钮
      customCardBuilder: (game) => _buildGameCard(game),
    );
  }

  // 使用BaseGameCard构建游戏卡片
  Widget _buildGameCard(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        // 右上角添加编辑和删除按钮
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    NavigationUtils.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditGameScreen(game: game),
                      ),
                    ).then((_) {
                      setState(() {
                        _needRefresh = true;
                      });
                    });
                  },
                ),
              ),
              SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(game),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(Game game) async {
    try {
      // 调用可复用的 ConfirmDialog.show 方法
      await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除游戏 "${game.title}" 吗？此操作不可恢复！', // 消息可以更明确
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red, // 保持删除按钮为红色
        cancelButtonText: '取消',
        // 将原本在 if (confirmed == true) 块中的逻辑放到 onConfirm 回调中
        onConfirm: () async {
          // 注意：ConfirmDialog 内部已经处理了 Navigator.pop(context)
          // 这里直接执行删除操作即可

          // 检查 widget 是否仍然挂载，尤其是在异步操作之后
          if (!mounted) return;

          await _gameService.deleteGame(game.id);

          // 再次检查 widget 是否仍然挂载
          if (!mounted) return;
          setState(() {
            _needRefresh = true; // 触发列表刷新
          });

          // 再次检查 widget 是否仍然挂载
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('游戏删除成功')),
          );
        },
        // onCancel 是可选的，如果取消时不需要特殊处理，可以不传
        // onCancel: () {
        //   print('用户取消了删除');
        // },
      );
      // 如果 ConfirmDialog.show 成功完成（即 onConfirm 没有抛出异常），
      // 则删除操作及其后续的 setState 和 SnackBar 已经执行完毕。
    } catch (e) {
      // 捕获 onConfirm 中可能抛出的异常 (例如 _gameService.deleteGame 失败)
      // ConfirmDialog 内部会 rethrow 异常
      if (mounted) { // 检查 widget 是否仍然挂载
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      } else {
        print('删除失败，但 widget 已卸载: $e');
      }
    }
  }

  // 原有的待审核游戏列表构建方法
  Widget _buildPendingGamesList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_pendingGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有待审核的游戏', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('所有游戏都已审核完成', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('共有 ${_pendingGames.length} 个游戏等待审核',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: _pendingGames.length,
            itemBuilder: (context, index) {
              final game = _pendingGames[index];
              return _buildPendingGameCard(game);
            },
          ),
        ),
      ],
    );
  }

  // 构建待审核游戏卡片
  Widget _buildPendingGameCard(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        // 待审核标记
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '待审核',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        // 右上角添加审核按钮
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.7),
            radius: 16,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _showReviewDialog(game),
            ),
          ),
        ),
      ],
    );
  }

  // 原有的被拒绝游戏列表构建方法
  Widget _buildRejectedGamesList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_rejectedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有被拒绝的游戏', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('目前没有被拒绝的游戏', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('共有 ${_rejectedGames.length} 个游戏被拒绝',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: _rejectedGames.length,
            itemBuilder: (context, index) {
              final game = _rejectedGames[index];
              return _buildRejectedGameCard(game);
            },
          ),
        ),
      ],
    );
  }

  // 构建被拒绝游戏卡片
  Widget _buildRejectedGameCard(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        // 被拒绝标记
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '已拒绝',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        // 显示拒绝原因
        if (game.reviewComment != null && game.reviewComment!.isNotEmpty)
          Positioned(
            bottom: 60,
            left: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '拒绝原因:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    game.reviewComment!,
                    style: TextStyle(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 显示审核对话框
  void _showReviewDialog(Game game) {
    bool approveSelected = true;
    String comment = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('审核游戏'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('游戏: ${game.title}'),
                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('通过'),
                            value: true,
                            groupValue: approveSelected,
                            onChanged: (value) {
                              setState(() {
                                approveSelected = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('拒绝'),
                            value: false,
                            groupValue: approveSelected,
                            onChanged: (value) {
                              setState(() {
                                approveSelected = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    TextField(
                      decoration: InputDecoration(
                        labelText: approveSelected ? '审核意见 (可选)' : '拒绝原因 (必填)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        comment = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('提交'),
                  onPressed: () {
                    if (!approveSelected && comment.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('拒绝时必须提供原因')),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    _reviewGame(
                        game,
                        approveSelected ? 'approved' : 'rejected',
                        comment
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 审核游戏方法
  void _reviewGame(Game game, String status, String comment) async {
    try {
      await _gameService.reviewGame(game.id, status, comment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('游戏审核成功')),
      );
      setState(() {
        _isLoading = true;
      });
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('审核失败: $e')),
      );
    }
  }
}