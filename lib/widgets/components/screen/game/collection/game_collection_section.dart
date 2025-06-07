// lib/widgets/components/screen/game/collection/game_collection_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameCollectionSection extends StatelessWidget {
  final Game game;
  final InputStateService inputStateService;
  final GameCollectionService gameCollectionService;
  final User? currentUser;
  final GameCollectionItem? initialCollectionStatus;
  final bool isPreviewMode;
  final Function(CollectionChangeResult)? onCollectionChanged;

  const GameCollectionSection({
    super.key,
    required this.game,
    required this.inputStateService,
    required this.gameCollectionService,
    required this.currentUser,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.isPreviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final wantToPlayCount = game.wantToPlayCount;
    final playingCount = game.playingCount;
    final playedCount = game.playedCount;
    final totalCollections = game.totalCollections;
    final rating = game.rating;
    final ratingCount = game.ratingCount;

    final formattedRating = rating > 0
        ? NumberFormat('0.0').format(rating)
        : (ratingCount > 0 ? '0.0' : '暂无');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.95),
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
              if (!isPreviewMode)
                GameCollectionButton(
                  gameCollectionService: gameCollectionService,
                  inputStateService: inputStateService,
                  game: game,
                  currentUser: currentUser,
                  initialCollectionStatus: initialCollectionStatus,
                  onCollectionChanged: onCollectionChanged,
                  compact: false,
                  isPreview: isPreviewMode,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatContainer(
                  context,
                  GameCollectionStatusUtils.wantToPlayTheme,
                  wantToPlayCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  GameCollectionStatusUtils.playingTheme,
                  playingCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  GameCollectionStatusUtils.playedTheme,
                  playedCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  GameCollectionStatusUtils.ratingDisplayTheme,
                  formattedRating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_alt_outlined,
                  size: 18, color: theme.primaryColor.withSafeOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                '总收藏 $totalCollections 人${ratingCount > 0 ? ' / $ratingCount 人评分' : ''}',
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
    );
  }

  // 构建单个统计信息展示块，使用传入的主题和数值
  Widget _buildStatContainer(
    BuildContext context,
    GameCollectionStatusTheme theme,
    dynamic value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
          color: theme.backgroundColor, borderRadius: BorderRadius.circular(8)),
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
                      color: theme.textColor.withSafeOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]),
            child: Icon(theme.icon, color: theme.textColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(theme.text,
              style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
