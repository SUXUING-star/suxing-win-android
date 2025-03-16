// lib/screens/add_game_screen.dart
import 'package:flutter/material.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart'; // 引入 GameService
import '../../widgets/components/form/gameform/game_form.dart';
import '../../utils/check/admin_check.dart';

class AddGameScreen extends StatelessWidget {
  final GameService _gameService = GameService(); // 使用 GameService

  @override
  Widget build(BuildContext context) {
    return AdminCheck(
      child: Scaffold(
        appBar: AppBar(
          title: Text('添加游戏'),
        ),
        body: GameForm(
          onSubmit: (Game game) async {
            try {
              await _gameService.addGame(game);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('游戏添加成功')),
              );
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('添加失败：$e')),
              );
            }
          },
        ),
      ),
    );
  }
}