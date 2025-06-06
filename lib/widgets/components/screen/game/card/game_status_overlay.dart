// lib/widgets/components/screen/game/card/game_status_overlay.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameStatusOverlay extends StatelessWidget {
  final Game game;
  final VoidCallback onResubmit; // 用于处理重新提交的回调
  final Function(String) onShowReviewComment; // 用于显示拒绝原因的回调

  const GameStatusOverlay({
    super.key,
    required this.game,
    required this.onResubmit,
    required this.onShowReviewComment,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = GameConstants.getStatusDisplay(game.approvalStatus);
    final bool isRejected =
        game.approvalStatus?.toLowerCase() == GameStatus.rejected;
    final bool showComment = isRejected &&
        game.reviewComment != null &&
        game.reviewComment!.isNotEmpty;

    // 使用 Stack 来叠加状态信息到卡片上
    // 注意：这里不再包含 BaseGameCard，而是期望被用在 BaseGameCard 外层的 Stack 中
    return Stack(
      children: [
        // Status Badge
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: (statusInfo['color'] as Color).withSafeOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.2),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ]),
            child: Text(
              statusInfo['text'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),

        // Resubmit Button (Only for rejected)
        if (isRejected)
          Positioned(
            bottom: 8,
            right: 8,
            child: Tooltip(
              message: '重新提交审核',
              child: FloatingActionButton.small(
                heroTag: 'resubmit_overlay_${game.id}', // Ensure unique heroTag
                // 调用传入的回调
                onPressed: onResubmit,
                backgroundColor: Colors.blue.shade600,
                child: Icon(Icons.refresh, size: 18),
              ),
            ),
          ),

        // Review Comment Overlay (Only for rejected with comment)
        if (showComment)
          Positioned(
            bottom: isRejected ? 55 : 8, // Adjust based on resubmit button
            left: 8,
            right: 8,
            child: GestureDetector(
              // 调用传入的回调
              onTap: () => onShowReviewComment(game.reviewComment!),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withSafeOpacity(0.95),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withSafeOpacity(0.1),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      )
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '拒绝原因:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      game.reviewComment!,
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
