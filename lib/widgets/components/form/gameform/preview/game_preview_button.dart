// lib/widgets/form/gameform/preview/game_preview_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../providers/auth/auth_provider.dart';
// *** Import AppButton ***
import '../../../../ui/buttons/app_button.dart'; // 确认路径正确
import 'game_preview_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class GamePreviewButton extends StatelessWidget {
  // --- 参数保持不变 ---
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController descriptionController;
  final String? coverImageUrl;
  final List<String> gameImages;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final double rating;
  final List<DownloadLink> downloadLinks;
  final String? musicUrl;
  final Game? existingGame;

  const GamePreviewButton({
    Key? key,
    required this.titleController,
    required this.summaryController,
    required this.descriptionController,
    required this.coverImageUrl,
    required this.gameImages,
    required this.selectedCategories,
    required this.selectedTags,
    required this.rating,
    required this.downloadLinks,
    this.musicUrl,
    this.existingGame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // *** 使用 AppButton 替换 ElevatedButton.icon ***
    return AppButton(
      // --- 传递参数给 AppButton ---
      text: '预览游戏详情',
      icon: const Icon(Icons.visibility_outlined), // 使用 AppButton 的 icon 参数
      // onPressed 逻辑保持不变
      onPressed: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUserId;

        final previewGame = Game(
          id: existingGame?.id ?? mongo.ObjectId().toHexString(),
          authorId: existingGame?.authorId ?? currentUserId ?? 'preview_mode',
          title: titleController.text.isEmpty ? "游戏标题预览" : titleController.text,
          summary: summaryController.text.isEmpty ? "游戏简介预览" : summaryController.text,
          description: descriptionController.text.isEmpty ? "游戏详细描述预览" : descriptionController.text,
          category: selectedCategories.isEmpty ? "预览分类" : selectedCategories.join(', '),
          coverImage: coverImageUrl ?? '',
          images: gameImages,
          tags: selectedTags,
          rating: rating,
          viewCount: existingGame?.viewCount ?? 0,
          createTime: existingGame?.createTime ?? DateTime.now(),
          updateTime: DateTime.now(),
          likeCount: existingGame?.likeCount ?? 0,
          likedBy: existingGame?.likedBy ?? [],
          downloadLinks: downloadLinks,
          musicUrl: musicUrl != null && musicUrl!.isNotEmpty ? musicUrl : null,
          lastViewedAt: existingGame?.lastViewedAt,
        );

        NavigationUtils.of(context).push(
          MaterialPageRoute(
            builder: (context) => GamePreviewScreen(game: previewGame),
            fullscreenDialog: true,
          ),
        );
      },
      // 可以根据需要设置 isMini 或 isPrimaryAction (预览按钮通常不是 Primary)
      isMini: false,
      isPrimaryAction: true,
    );
  }
}