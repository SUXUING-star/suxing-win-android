// lib/screens/admin/widgets/game_management.dart
import 'package:flutter/material.dart';
import '../../../services/main/game/game_service.dart';
import '../../../models/game/game.dart';
import '../../../widgets/common/image/safe_cached_image.dart';
import '../../game/edit/edit_game_screen.dart';
import '../../game/edit/add_game_screen.dart';

class GameManagement extends StatefulWidget {
  const GameManagement({Key? key}) : super(key: key);

  @override
  State<GameManagement> createState() => _GameManagementState();
}

class _GameManagementState extends State<GameManagement> {
  final GameService _gameService = GameService();
  // 添加状态变量跟踪是否需要刷新
  bool _needRefresh = true;
  // 添加一个key来触发FutureBuilder的重新构建
  final GlobalKey _futureBuilderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // 手动刷新时设置标志并更新状态
          setState(() {
            _needRefresh = true;
          });
        },
        child: _needRefresh
            ? _buildGameList()
            : KeyedSubtree(
          key: _futureBuilderKey,
          child: _buildGameList(),
        ),
      ),
    );
  }

  Widget _buildGameList() {
    return FutureBuilder<List<Game>>(
      future: _gameService.getGamesPaginated(
        page: 1,
        pageSize: 100, // 调整为足够大的数量以显示所有游戏
        sortBy: 'createTime',
        descending: true,
      ),
      builder: (context, snapshot) {
        // 标记未来的查询不需要刷新，除非显式请求
        if (_needRefresh && snapshot.connectionState == ConnectionState.done) {
          _needRefresh = false;
        }

        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddGameScreen()),
                  ).then((_) {
                    // 当从添加游戏页面返回时刷新列表
                    setState(() {
                      _needRefresh = true;
                    });
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('添加游戏'),
              ),
            ),
            Expanded(
              child: games.isEmpty
                  ? Center(child: Text('暂无游戏数据'))
                  : ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: game.coverImage.isNotEmpty
                          ? SizedBox(
                        width: 50,
                        height: 50,
                        child: SafeCachedImage(
                          imageUrl: game.coverImage,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(4),
                          onError: (url, error) {
                            print('管理页游戏封面加载失败: $url, 错误: $error');
                          },
                        ),
                      )
                          : const Icon(Icons.games),
                      title: Text(game.title),
                      subtitle: Text(
                        game.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditGameScreen(game: game),
                                ),
                              ).then((_) {
                                // 当从编辑游戏页面返回时刷新列表
                                setState(() {
                                  _needRefresh = true;
                                });
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(game),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除游戏"${game.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gameService.deleteGame(game.id);
        // 设置需要刷新标志
        setState(() {
          _needRefresh = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('游戏删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }
}