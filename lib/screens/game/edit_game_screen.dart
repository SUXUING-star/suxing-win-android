// lib/screens/edit_game_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart'; // 引入 GameService
import '../../widgets/form/game_form.dart';
import '../../utils/admin_check.dart';

class EditGameScreen extends StatelessWidget {
  final Game game;
  final GameService _gameService = GameService(); // 使用 GameService

  EditGameScreen({required this.game});

  @override
  Widget build(BuildContext context) {
    return AdminCheck(
      child: Scaffold(
        appBar: AppBar(
          title: Text('编辑游戏'),
        ),
        body: GameForm(
          game: game,
          onSubmit: (Game updatedGame) async {
            try {
              await _gameService.updateGame(updatedGame);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('修改成功')),
              );
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('修改失败：$e')),
              );
            }
          },
        ),
      ),
    );
  }
}