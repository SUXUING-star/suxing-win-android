// lib/widgets/components/screen/game/button/like_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../../../../../providers/auth/auth_provider.dart';
import '../../../../common/toaster/toaster.dart';

class LikeButton extends StatefulWidget {
  final Game game;
  final GameService gameService;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    Key? key,
    required this.game,
    required this.gameService,
    this.onLikeChanged,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isProcessing = false;
  bool? _isFavorite;
  bool _isInitialized = false;

  // 添加时间戳记录，防止频繁刷新
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  // 加载初始状态
  Future<void> _loadInitialState() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      setState(() {
        _isFavorite = false;
        _isInitialized = true;
      });
      return;
    }

    try {
      // 使用优化后的 getUserFavoriteGames 方法
      final favorites = await widget.gameService.getUserFavoriteGames();
      final isFavorite = favorites.any((game) => game.id == widget.game.id);

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isInitialized = true;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = false;
          _isInitialized = true;
        });
      }
    }
  }

  // 刷新收藏状态 - 带防抖
  Future<void> _refreshFavoriteStatus() async {
    // 如果10秒内刚刷新过，跳过
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 10) {
      return;
    }

    await _loadInitialState();
  }

  Future<void> _toggleLike(BuildContext context, bool isLiked) async {
    // Prevent multiple clicks while processing
    if (_isProcessing) return;

    // Update local state first
    setState(() {
      _isProcessing = true;
      // 立即更新UI状态，提高响应性
      _isFavorite = !isLiked;
    });

    try {
      // Call the service method
      await widget.gameService.toggleLike(widget.game.id);

      // Notify parent about the change
      if (widget.onLikeChanged != null) {
        widget.onLikeChanged!();
      }

      // Show success message if widget is still mounted
      if (mounted) {
        // Toaster.show(
        //   context,
        //   message: isLiked ? '已取消点赞' : '点赞成功',
        // );
      }
    } catch (e) {
      // 操作失败，恢复原状态
      if (mounted) {
        setState(() {
          _isFavorite = isLiked;
        });

        // Toaster.show(
        //   context,
        //   message: '操作失败，请稍后重试',
        //   isError: true,
        // );
      }
    } finally {
      // Reset processing state if widget is still mounted
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 页面成为活跃时刷新状态 - 带防抖
    _refreshFavoriteStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Handle not logged in state
        if (!authProvider.isLoggedIn) {
          return _buildLikeButtonUI(
            context: context,
            isFavorite: false,
            isLoggedIn: false,
          );
        }

        // 使用本地状态而不是流
        if (!_isInitialized) {
          return const SizedBox(
            width: 50,
            height: 50,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return _buildLikeButtonUI(
          context: context,
          isFavorite: _isFavorite ?? false,
          isLoggedIn: true,
        );
      },
    );
  }

  // Extracted UI building to a separate method for better organization
  Widget _buildLikeButtonUI({
    required BuildContext context,
    required bool isFavorite,
    required bool isLoggedIn,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLoggedIn && isFavorite
            ? Colors.red
            : Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: !isLoggedIn
              ? () {
            Toaster.show(
              context,
              message: '请先登录后再操作',
              isError: true,
            );
            Navigator.pushNamed(context, '/login');
          }
              : _isProcessing
              ? null
              : () => _toggleLike(context, isFavorite),
          child: Center(
            child: _isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(
              isLoggedIn && isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}