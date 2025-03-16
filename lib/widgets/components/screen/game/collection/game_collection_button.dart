// lib/widgets/components/screen/game/collection/game_collection_button.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game_collection.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/collection/game_collection_service.dart';
import '../../../../../providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../routes/app_routes.dart';
import '../dialog/collection_dialog.dart';

class GameCollectionButton extends StatefulWidget {
  final Game game;
  final bool compact;
  final Function()? onCollectionChanged;

  const GameCollectionButton({
    Key? key,
    required this.game,
    this.compact = false,
    this.onCollectionChanged,
  }) : super(key: key);

  @override
  _GameCollectionButtonState createState() => _GameCollectionButtonState();
}

class _GameCollectionButtonState extends State<GameCollectionButton> {
  final GameCollectionService _collectionService = GameCollectionService();
  bool _isLoading = false;
  GameCollectionItem? _collectionStatus;

  @override
  void initState() {
    super.initState();
    _loadCollectionStatus();
  }

  @override
  void didUpdateWidget(GameCollectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _loadCollectionStatus();
    }
  }

  Future<void> _loadCollectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _collectionService.getGameCollectionStatus(widget.game.id);

      if (mounted) {
        setState(() {
          _collectionStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load collection status error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCollectionDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 检查用户是否已登录
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先登录后再添加收藏'),
          action: SnackBarAction(
            label: '去登录',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }

    // 打开收藏对话框
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CollectionDialog(
        gameId: widget.game.id,
        gameName: widget.game.title,
        currentStatus: _collectionStatus?.status,
        currentNotes: _collectionStatus?.notes,
        currentReview: _collectionStatus?.review,
        currentRating: _collectionStatus?.rating,
      ),
    );

// 处理对话框结果
    if (result != null) {
      final action = result['action'] as String;

      if (action == 'set') {
        final status = result['status'] as String;
        final notes = result['notes'] as String?;
        final review = result['review'] as String?; // 添加review
        final rating = result['rating'] as double?;

        setState(() {
          _isLoading = true;
        });

        try {
          await _collectionService.setGameCollection(
            widget.game.id,
            status,
            notes: notes,
            review: review, // 传递review参数
            rating: rating,
          );

          // 重新加载收藏状态
          await _loadCollectionStatus();

          // 通知父组件收藏状态已更改
          if (widget.onCollectionChanged != null) {
            widget.onCollectionChanged!();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('游戏收藏状态已更新')),
          );
        } catch (e) {
          print('Set collection error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新收藏状态失败：$e')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else if (action == 'remove') {
        setState(() {
          _isLoading = true;
        });

        try {
          await _collectionService.removeGameCollection(widget.game.id);

          setState(() {
            _collectionStatus = null;
          });

          // 通知父组件收藏状态已更改
          if (widget.onCollectionChanged != null) {
            widget.onCollectionChanged!();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('游戏已从收藏中移除')),
          );
        } catch (e) {
          print('Remove collection error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移除收藏失败：$e')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 36,
        width: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
        ),
      );
    }

    final hasStatus = _collectionStatus != null;

    if (hasStatus) {
      final status = _collectionStatus!.status;
      return _buildCollectionStatusButton(context, status);
    } else {
      return _buildAddCollectionButton(context);
    }
  }

  Widget _buildAddCollectionButton(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
        tooltip: '添加收藏',
        onPressed: _showCollectionDialog,
      );
    }

    return ElevatedButton.icon(
      icon: Icon(Icons.add_circle_outline, size: 18),
      label: Text('添加收藏'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: _showCollectionDialog,
    );
  }

  Widget _buildCollectionStatusButton(BuildContext context, String status) {
    // 根据状态设置不同的视觉样式
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String statusText;

    switch (status) {
      case GameCollectionStatus.wantToPlay:
        backgroundColor = Color(0xFFE6F0FF);
        textColor = Color(0xFF3D8BFF);
        iconData = Icons.star_border;
        statusText = '想玩';
        break;
      case GameCollectionStatus.playing:
        backgroundColor = Color(0xFFE8F5E9);
        textColor = Color(0xFF4CAF50);
        iconData = Icons.sports_esports;
        statusText = '在玩';
        break;
      case GameCollectionStatus.played:
        backgroundColor = Color(0xFFF3E5F5);
        textColor = Color(0xFF9C27B0);
        iconData = Icons.check_circle_outline;
        statusText = '玩过';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        iconData = Icons.bookmark_border;
        statusText = '已收藏';
    }

    if (widget.compact) {
      return IconButton(
        icon: Icon(iconData, color: textColor),
        tooltip: statusText,
        onPressed: _showCollectionDialog,
      );
    }

    return OutlinedButton.icon(
      icon: Icon(iconData, size: 18),
      label: Text(statusText),
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: textColor.withOpacity(0.5), width: 1),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: _showCollectionDialog,
    );
  }
}