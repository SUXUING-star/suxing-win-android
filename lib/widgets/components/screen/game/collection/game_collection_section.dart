import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_button.dart';


class GameCollectionSection extends StatefulWidget {
  final Game game; // 父组件传递的游戏对象，包含统计数字
  final GameCollectionItem? initialCollectionStatus;
  // *** 修改回调签名 ***
  final Function(CollectionChangeResult)? onCollectionChanged;

  const GameCollectionSection({
    Key? key,
    required this.game,
    this.initialCollectionStatus,
    this.onCollectionChanged, // *** 新签名 ***
  }) : super(key: key);

  @override
  _GameCollectionSectionState createState() => _GameCollectionSectionState();
}

class _GameCollectionSectionState extends State<GameCollectionSection> {

  // *** 修改内部回调处理函数以接收新的结果类型 ***
  void _handleButtonCollectionChanged(CollectionChangeResult result) {
    // 直接调用 widget 的回调，将结果对象向上传递
    widget.onCollectionChanged?.call(result); // <--- 传递结果对象
    print('GameCollectionSection (${widget.game.id}): Relayed CollectionChangeResult upwards.');
  }

  @override
  void initState() {
    super.initState();
    print('GameCollectionSection (${widget.game.id}): Initialized with game counts - Want: ${widget.game.wantToPlayCount}, Playing: ${widget.game.playingCount}, Played: ${widget.game.playedCount}, Total: ${widget.game.totalCollections}');
  }

  @override
  void didUpdateWidget(GameCollectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 观察父组件传递的数据变化
    if (widget.game.id != oldWidget.game.id) {
      print('GameCollectionSection (${widget.game.id}): Game ID changed.');
    }
    if (widget.initialCollectionStatus != oldWidget.initialCollectionStatus) {
      print('GameCollectionSection (${widget.game.id}): Received new initialCollectionStatus from parent: ${widget.initialCollectionStatus?.status}');
    }
    // 观察 Game 对象中的计数值是否变化
    if (widget.game.wantToPlayCount != oldWidget.game.wantToPlayCount ||
        widget.game.playingCount != oldWidget.game.playingCount ||
        widget.game.playedCount != oldWidget.game.playedCount ||
        widget.game.totalCollections != oldWidget.game.totalCollections) {
      print('GameCollectionSection (${widget.game.id}): Received new game counts from parent - Want: ${widget.game.wantToPlayCount}, Playing: ${widget.game.playingCount}, Played: ${widget.game.playedCount}, Total: ${widget.game.totalCollections}');
    }
  }

  // 构建 UI 的主方法 (build)
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 使用传递进来的 widget.game 对象来显示统计数字
    final currentGame = widget.game;

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
            // 标题行
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
                // *** 传递更新后的回调签名给按钮 ***
                GameCollectionButton(
                  game: currentGame, // 总是使用最新的 game 对象
                  initialCollectionStatus: widget.initialCollectionStatus,
                  onCollectionChanged: _handleButtonCollectionChanged, // 传递内部处理函数
                  compact: false,
                ),
              ],
            ),
            SizedBox(height: 20),

            // 统计数字行 (直接使用 currentGame 的计数值)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatContainer(
                  context, Icons.star_border, '想玩',
                  currentGame.wantToPlayCount, // *** 使用 game 对象的计数值 ***
                  Color(0xFF3D8BFF), Color(0xFFE6F0FF),
                ),
                _buildStatContainer(
                  context, Icons.sports_esports, '在玩',
                  currentGame.playingCount, // *** 使用 game 对象的计数值 ***
                  Color(0xFF4CAF50), Color(0xFFE8F5E9),
                ),
                _buildStatContainer(
                  context, Icons.check_circle_outline, '玩过',
                  currentGame.playedCount, // *** 使用 game 对象的计数值 ***
                  Color(0xFF9C27B0), Color(0xFFF3E5F5),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 12),

            // 总收藏人数行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 18, color: theme.primaryColor.withOpacity(0.7)),
                SizedBox(width: 8),
                Text(
                  '总收藏人数: ${currentGame.totalCollections}', // *** 使用 game 对象的计数值 ***
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建单个统计块的辅助方法 (_buildStatContainer) - 无变化
  Widget _buildStatContainer(
      BuildContext context,
      IconData icon,
      String label,
      int count, // 接收计数值
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
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 4),
          Text(
            count.toString(), // 显示传入的计数值
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}