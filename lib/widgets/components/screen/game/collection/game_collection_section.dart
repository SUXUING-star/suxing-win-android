// lib/widgets/components/screen/game/collection/game_collection_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

// *** 改成 StatefulWidget ***
class GameCollectionSection extends StatefulWidget {
  final Game game;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged;
  final bool isPreviewMode;

  const GameCollectionSection({
    super.key,
    required this.game,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.isPreviewMode = false,
  });

  @override
  // *** 创建 State ***
  _GameCollectionSectionState createState() => _GameCollectionSectionState();
}

class _GameCollectionSectionState extends State<GameCollectionSection> {
  late int _wantToPlayCount;
  late int _playingCount;
  late int _playedCount;
  late int _totalCollections;
  late double _rating;
  late int _ratingCount;

  @override
  void initState() {
    super.initState();
    _updateCountsFromWidget();
  }

  @override
  void didUpdateWidget(GameCollectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game != oldWidget.game) {
      // 只有在外部 game 对象确实变化时才用 setState 更新内部状态
      // 避免按钮回调触发的 setState 和这里的 setState 冲突
      if (widget.game.wantToPlayCount != _wantToPlayCount ||
          widget.game.playingCount != _playingCount ||
          widget.game.playedCount != _playedCount ||
          widget.game.totalCollections != _totalCollections ||
          widget.game.rating != _rating ||
          widget.game.ratingCount != _ratingCount) {
        setState(() {
          _updateCountsFromWidget();
        });
      }
    }
  }

  // 辅助方法：从 widget.game 更新 state 变量
  void _updateCountsFromWidget() {
    _wantToPlayCount = widget.game.wantToPlayCount;
    _playingCount = widget.game.playingCount;
    _playedCount = widget.game.playedCount;
    _totalCollections = widget.game.totalCollections;
    _rating = widget.game.rating;
    _ratingCount = widget.game.ratingCount;
  }

  // *** 修改内部回调处理函数 ***
  void _handleButtonCollectionChanged(CollectionChangeResult result) {
    // *** 1. 前端补偿：直接更新本组件 State 中的计数值 ***
    final deltas = result.countDeltas;
    setState(() {
      _wantToPlayCount += (deltas['want'] ?? 0);
      _playingCount += (deltas['playing'] ?? 0);
      _playedCount += (deltas['played'] ?? 0);
      _totalCollections += (deltas['total'] ?? 0);
      // 确保计数不为负
      if (_wantToPlayCount < 0) _wantToPlayCount = 0;
      if (_playingCount < 0) _playingCount = 0;
      if (_playedCount < 0) _playedCount = 0;
      if (_totalCollections < 0) _totalCollections = 0;
      print(
          'GameCollectionSection (${widget.game.id}): State counts updated (frontend compensation) - Want: $_wantToPlayCount, Playing: $_playingCount, Played: $_playedCount, Total: $_totalCollections');
    });

    // *** 2. 调用 widget 的回调，通知父级（或其他监听者）状态已改变 ***
    //    父级（GameDetailContent）会用这个结果来判断是否需要刷新 ReviewSection
    widget.onCollectionChanged?.call(result);
  }

  // 构建 UI 的主方法 (build)
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // *** 使用 State 中的计数值来显示 ***
    // 格式化评分，显示一位小数，如果评分为0则显示 "N/A" 或 "0.0"
    final formattedRating = _rating > 0
        ? NumberFormat('0.0').format(_rating)
        : (_ratingCount > 0 ? '0.0' : '暂无');

    return Opacity(
      opacity: 0.95,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                const SizedBox(width: 8),
                Text(
                  '收藏与评分',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                // *** 传递 game 对象 和 回调 ***
                if (!widget.isPreviewMode)
                  GameCollectionButton(
                    game: widget.game, // 按钮仍然需要原始 game 对象来获取 ID 等信息
                    initialCollectionStatus: widget.initialCollectionStatus,
                    onCollectionChanged:
                        _handleButtonCollectionChanged, // 传递内部处理函数
                    compact: false,
                    isPreview: widget.isPreviewMode,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 统计数字行 (使用 State 中的计数值) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildStatContainer(
                    context, Icons.star_border, '想玩',
                    _wantToPlayCount, // 使用 State 变量
                    const Color(0xFF3D8BFF), const Color(0xFFE6F0FF),
                  ),
                ),
                const SizedBox(width: 12), // **** 添加间距 **** (可以调整 8, 12, 16)

                Expanded(
                  child: _buildStatContainer(
                    context, Icons.sports_esports, '在玩',
                    _playingCount, // 使用 State 变量
                    const Color(0xFF4CAF50), const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 12), // **** 添加间距 ****

                Expanded(
                  child: _buildStatContainer(
                    context, Icons.check_circle_outline, '玩过',
                    _playedCount, // 使用 State 变量
                    const Color(0xFF9C27B0), const Color(0xFFF3E5F5),
                  ),
                ),
                const SizedBox(width: 12), // **** 添加间距 ****

                Expanded(
                  child: _buildStatContainer(
                    context, Icons.star, '评分',
                    formattedRating, // 使用格式化评分
                    Colors.orange.shade700, Colors.orange.shade50,
                  ),
                ),
              ],
            ),
            // --- 统计数字行结束 ---

            const SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 12),

            // 总收藏人数行 (使用 State 中的计数值)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 18, color: theme.primaryColor.withSafeOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  // 使用 State 变量
                  '总收藏 $_totalCollections 人${_ratingCount > 0 ? ' / $_ratingCount 人评分' : ''}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor.withSafeOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _buildStatContainer 方法不变，接收 dynamic value
  Widget _buildStatContainer(
    BuildContext context,
    IconData icon,
    String label,
    dynamic value,
    Color iconColor,
    Color backgroundColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 4), // 内边距可以保留或微调
      decoration: BoxDecoration(
          // 背景和圆角不变
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: iconColor.withSafeOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: iconColor, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis), // ellipsis 防止文本换行
          const SizedBox(height: 4),
          Text(value.toString(), // 将值转为 String 显示
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis), // ellipsis 防止文本换行
        ],
      ),
    );
  }
}
