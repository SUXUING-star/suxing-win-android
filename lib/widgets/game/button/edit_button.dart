import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../screens/game/edit_game_screen.dart';
import '../../../utils/device/device_utils.dart'; // 引入 DeviceUtils

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

        final double leftPadding = DeviceUtils.isAndroidLandscape(context) ? 4.0 : (DeviceUtils.isAndroid ? 8.0 : 16.0); // 根据不同情况设置padding
        final double iconSize = DeviceUtils.getIconSize(context);

        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: leftPadding),
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
              child: Icon(Icons.edit, size: iconSize,),
              backgroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}