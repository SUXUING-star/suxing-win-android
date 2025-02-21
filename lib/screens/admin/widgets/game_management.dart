// lib/screens/admin/widgets/game_management.dart
import 'package:flutter/material.dart';
import '../../../services/main/game/game_service.dart';
import '../../../models/game/game.dart';
import '../../game/edit_game_screen.dart';
import '../../game/add_game_screen.dart';

class GameManagement extends StatefulWidget {
  const GameManagement({Key? key}) : super(key: key);

  @override
  State<GameManagement> createState() => _GameManagementState();
}

class _GameManagementState extends State<GameManagement> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Game>>(
        stream: Stream.fromFuture(_gameService.getGamesPaginated(
          page: 1,
          pageSize: 100, // 调整为足够大的数量以显示所有游戏
          sortBy: 'createTime',
          descending: true,
        ).then((games) => games)),
        builder: (context, snapshot) {
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
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加游戏'),
                ),
              ),
              Expanded(
                child: ListView.builder(
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
                            ? Image.network(
                          game.coverImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.games),
                        title: Text(game.title),
                        subtitle: Text(game.summary),
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
                                );
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
      ),
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