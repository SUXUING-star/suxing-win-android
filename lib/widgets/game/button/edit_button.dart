// lib/widgets/game/button/edit_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../screens/game/edit_game_screen.dart';

class EditButton extends StatelessWidget {
  final Game game;
  final VoidCallback onEditComplete;

  const EditButton({
    Key? key,
    required this.game,
    required this.onEditComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAdmin) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FloatingActionButton(
              heroTag: 'editButton',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGameScreen(game: game),
                  ),
                ).then((_) => onEditComplete());
              },
              child: const Icon(Icons.edit),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}