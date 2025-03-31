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
  final GameCollectionItem? initialCollectionStatus;

  const GameCollectionButton({
    Key? key,
    required this.game,
    this.compact = false,
    this.onCollectionChanged,
    this.initialCollectionStatus,
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
    _collectionStatus = widget.initialCollectionStatus;
    _isLoading = false;
    print('GameCollectionButton (${widget.game.id}): Initialized with status: ${_collectionStatus?.status}');
  }

  @override
  void didUpdateWidget(GameCollectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCollectionStatus != oldWidget.initialCollectionStatus) {
      if (!_isLoading) {
        setState(() {
          _collectionStatus = widget.initialCollectionStatus;
          print('GameCollectionButton (${widget.game.id}): Updated status from parent: ${_collectionStatus?.status}');
        });
      }
    }
    if (widget.game.id != oldWidget.game.id && !_isLoading) {
      setState(() {
        _collectionStatus = widget.initialCollectionStatus;
        print('GameCollectionButton (${widget.game.id}): Game changed, updated status: ${_collectionStatus?.status}');
      });
    }
  }

  Future<void> _showCollectionDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先登录'),
          action: SnackBarAction(label: '去登录', onPressed: () => Navigator.pushNamed(context, AppRoutes.login)),
        ),
      );
      return;
    }

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

    if (result != null) {
      final action = result['action'] as String;
      if (!mounted) return;
      setState(() { _isLoading = true; });

      try {
        if (action == 'set') {
          final status = result['status'] as String;
          final notes = result['notes'] as String?;
          final review = result['review'] as String?;
          final rating = result['rating'] as double?;
          await _collectionService.setGameCollection(
              widget.game.id, status, notes: notes, review: review, rating: rating);
          widget.onCollectionChanged?.call(); // 触发回调
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('收藏状态已更新')));
        } else if (action == 'remove') {
          await _collectionService.removeGameCollection(widget.game.id);
          if(mounted) setState(() { _collectionStatus = null; }); // 更新本地状态
          widget.onCollectionChanged?.call(); // 触发回调
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已从收藏中移除')));
        }
      } catch (e) {
        print('Collection operation error: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      } finally {
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStatus = _collectionStatus != null;
    final theme = Theme.of(context);

    Widget addCollectionButton() {
      if (widget.compact) {
        return IconButton(
          icon: _isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor)) : Icon(Icons.add_circle_outline, color: theme.primaryColor),
          tooltip: _isLoading ? '处理中...' : '添加收藏',
          onPressed: _isLoading ? null : _showCollectionDialog,
        );
      } else {
        return ElevatedButton.icon(
          icon: _isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
          label: Text(_isLoading ? '处理中...' : '添加收藏'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: theme.primaryColor, elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _isLoading ? null : _showCollectionDialog,
        );
      }
    }

    Widget collectionStatusButton(String status) {
      Color backgroundColor; Color textColor; IconData iconData; String statusText;
      switch (status) {
        case GameCollectionStatus.wantToPlay: backgroundColor = Color(0xFFE6F0FF); textColor = Color(0xFF3D8BFF); iconData = Icons.star_border; statusText = '想玩'; break;
        case GameCollectionStatus.playing: backgroundColor = Color(0xFFE8F5E9); textColor = Color(0xFF4CAF50); iconData = Icons.sports_esports; statusText = '在玩'; break;
        case GameCollectionStatus.played: backgroundColor = Color(0xFFF3E5F5); textColor = Color(0xFF9C27B0); iconData = Icons.check_circle_outline; statusText = '玩过'; break;
        default: backgroundColor = Colors.grey[100]!; textColor = Colors.grey[700]!; iconData = Icons.bookmark_border; statusText = '状态未知';
      }
      if (widget.compact) {
        return IconButton(
          icon: _isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: textColor)) : Icon(iconData, color: textColor),
          tooltip: _isLoading ? '处理中...' : statusText,
          onPressed: _isLoading ? null : _showCollectionDialog,
        );
      } else {
        return OutlinedButton.icon(
          icon: _isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(textColor))) : Icon(iconData, size: 18),
          label: Text(_isLoading ? '处理中...' : statusText),
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor, backgroundColor: backgroundColor,
            side: BorderSide(color: textColor.withOpacity(0.5), width: 1),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _isLoading ? null : _showCollectionDialog,
        );
      }
    }

    if (hasStatus) {
      return collectionStatusButton(_collectionStatus!.status);
    } else {
      return addCollectionButton();
    }
  }
}