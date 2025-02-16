// lib/widgets/game/button/like_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game.dart';
import '../../../services/game_service.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/common/toaster.dart';

class LikeButton extends StatelessWidget {
  final Game game;
  final GameService gameService;

  const LikeButton({
    Key? key,
    required this.game,
    required this.gameService,
  }) : super(key: key);

  void _toggleLike(BuildContext context, bool isLiked) async {
    try {
      await gameService.toggleLike(game.id);
      Toaster.show(
        context,
        message: isLiked ? '已取消点赞' : '点赞成功',
      );
    } catch (e) {
      Toaster.show(
        context,
        message: '操作失败，请稍后重试',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: IconButton(
              onPressed: () {
                Toaster.show(
                  context,
                  message: '请先登录后再操作',
                  isError: true,
                );
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.white,
              ),
            ),
          );
        }

        return StreamBuilder<List<String>>(
          stream: gameService.getUserFavorites(),
          initialData: const [],
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final isFavorite = snapshot.data!.contains(game.id);

            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFavorite ? Colors.red : Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _toggleLike(context, isFavorite),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
