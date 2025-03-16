// lib/widgets/game/collection/game_collection_section.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../models/game/game_collection.dart';
import '../../../../../../services/main/game/collection/game_collection_service.dart';
import 'game_collection_button.dart';

class GameCollectionSection extends StatefulWidget {
  final Game game;

  const GameCollectionSection({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  _GameCollectionSectionState createState() => _GameCollectionSectionState();
}

class _GameCollectionSectionState extends State<GameCollectionSection> {
  final GameCollectionService _collectionService = GameCollectionService();
  bool _isLoading = true;
  GameCollectionStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(GameCollectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _collectionService.getGameCollectionStats(widget.game.id);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load collection stats error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: 0.95,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '收藏此游戏',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                // 重新设计的收藏按钮，使用自定义按钮而不是调用其他组件
                _buildCollectionButton(context),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (_stats != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatContainer(
                    context,
                    Icons.star_border,
                    '想玩',
                    _stats!.wantToPlayCount,
                    Color(0xFF3D8BFF), // 更亮的蓝色
                    Color(0xFFE6F0FF), // 非常浅的蓝色背景
                  ),
                  _buildStatContainer(
                    context,
                    Icons.sports_esports,
                    '在玩',
                    _stats!.playingCount,
                    Color(0xFF4CAF50), // 鲜明的绿色
                    Color(0xFFE8F5E9), // 非常浅的绿色背景
                  ),
                  _buildStatContainer(
                    context,
                    Icons.check_circle_outline,
                    '玩过',
                    _stats!.playedCount,
                    Color(0xFF9C27B0), // 鲜明的紫色
                    Color(0xFFF3E5F5), // 非常浅的紫色背景
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(color: Colors.grey[200]),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: theme.primaryColor.withOpacity(0.7)
                  ),
                  SizedBox(width: 8),
                  Text(
                    '总收藏人数: ${_stats!.totalCount}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.primaryColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ] else
              Center(
                child: Text(
                  '暂无收藏数据',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionButton(BuildContext context) {
    return GameCollectionButton(
      game: widget.game,
      onCollectionChanged: _loadStats,
    );
  }

  Widget _buildStatContainer(
      BuildContext context,
      IconData icon,
      String label,
      int count,
      Color iconColor,
      Color backgroundColor,
      ) {
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}