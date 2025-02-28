// lib/widgets/components/screen/game/button/like_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../../../../../providers/auth/auth_provider.dart';
import '../../../../../widgets/common/toaster.dart';

class LikeButton extends StatefulWidget {
  final Game game;
  final GameService gameService;
  final VoidCallback? onLikeChanged; // 添加回调函数

  const LikeButton({
    Key? key,
    required this.game,
    required this.gameService,
    this.onLikeChanged, // 初始化回调
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isProcessing = false;

  void _toggleLike(BuildContext context, bool isLiked) async {
    if (_isProcessing) return; // 防止重复点击

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.gameService.toggleLike(widget.game.id);

      // 调用回调函数刷新父组件
      if (widget.onLikeChanged != null) {
        widget.onLikeChanged!();
      }

      if (mounted) {
        Toaster.show(
          context,
          message: isLiked ? '已取消点赞' : '点赞成功',
        );
      }
    } catch (e) {
      if (mounted) {
        Toaster.show(
          context,
          message: '操作失败，请稍后重试',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
          stream: widget.gameService.getUserFavorites(),
          initialData: const [],
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final isFavorite = snapshot.data!.contains(widget.game.id);

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
                onPressed: _isProcessing
                    ? null // 如果正在处理则禁用按钮
                    : () => _toggleLike(context, isFavorite),
                icon: _isProcessing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
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