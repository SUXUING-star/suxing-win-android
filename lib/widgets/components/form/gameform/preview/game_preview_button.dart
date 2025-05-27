// lib/widgets/components/form/gameform/preview/game_preview_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'game_preview_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class GamePreviewButton extends StatelessWidget {
  final GameService gameService;
  final GameCollectionService gameCollectionService;
  final UserInfoProvider infoProvider;
  final GameListFilterProvider gameListFilterProvider;
  final SidebarProvider sidebarProvider;
  final AuthProvider authProvider;
  final InputStateService inputStateService;
  final UserFollowService followService;
  final User? currentUser;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController descriptionController;
  final String? coverImageUrl;
  final List<String> gameImages;
  final String? selectedCategory;
  final List<String> selectedTags;
  final double rating;
  final List<GameDownloadLink> downloadLinks;
  final TextEditingController? musicUrlController;
  final TextEditingController? bvidController;
  final Game? existingGame;

  const GamePreviewButton({
    super.key,
    required this.followService,
    required this.sidebarProvider,
    required this.gameListFilterProvider,
    required this.infoProvider,
    required this.authProvider,
    required this.inputStateService,
    required this.gameService,
    required this.gameCollectionService,
    required this.currentUser,
    required this.titleController,
    required this.summaryController,
    required this.descriptionController,
    required this.coverImageUrl,
    required this.gameImages,
    required this.selectedCategory,
    required this.selectedTags,
    required this.rating,
    required this.downloadLinks,
    this.musicUrlController,
    this.bvidController,
    this.existingGame,
  });

  // --- 辅助验证函数 ---
  bool _validateBV(String text) {
    // 简单检查 BV 号格式 (以 BV 开头，后面跟数字和字母组合)
    final bvPattern = RegExp(r'^BV[1-9A-HJ-NP-Za-km-z]+$');
    // 还需要检查长度，一般是 10 位字符 + BV 前缀 = 12 位
    return text.startsWith('BV') &&
        text.length > 10 &&
        bvPattern.hasMatch(text);
  }

  bool _validateMusic(String text) {
    // 检查是否是 music.163.com 的链接
    return text.startsWith('http://music.163.com') ||
        text.startsWith('https://music.163.com');
  }

  void _handlePreview(BuildContext context) {
    final bvid = bvidController!.text.isEmpty ? null : bvidController?.text;
    final musicUrl =
        musicUrlController!.text.isEmpty ? null : musicUrlController?.text;

    final isValidMusic = bvid == null ? true : _validateBV(bvid);
    final isValidBV = musicUrl == null ? true : _validateMusic(musicUrl);
    final passValid = isValidMusic && isValidBV;

    if (!isValidMusic) {
      return AppSnackBar.showWarning(context, "点我也没用，检查填的有没有问题");
    }
    if (!isValidBV) {
      return AppSnackBar.showWarning(context, "点我也没用，检查填的有没有问题");
    }
    final previewGame = Game(
      id: existingGame?.id ?? mongo.ObjectId().oid,
      authorId: existingGame?.authorId ?? currentUser?.id ?? 'preview_mode',
      title: titleController.text.isEmpty ? "游戏标题预览" : titleController.text,
      summary:
          summaryController.text.isEmpty ? "游戏简介预览" : summaryController.text,
      description: descriptionController.text.isEmpty
          ? "游戏详细描述预览"
          : descriptionController.text,
      category: selectedCategory == null ? "生肉" : selectedCategory!,
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
      bvid: bvid,

      musicUrl: musicUrl, // musicUrl 的判断保持原样
      lastViewedAt: existingGame?.lastViewedAt,
    );

    if (passValid) {
      NavigationUtils.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePreviewScreen(
            sidebarProvider: sidebarProvider,
            gameListFilterProvider: gameListFilterProvider,
            gameCollectionService: gameCollectionService,
            authProvider: authProvider,
            inputStateService: inputStateService,
            infoProvider: infoProvider,
            followService: followService,
            gameService: gameService,
            game: previewGame,
            currentUser: currentUser,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // *** 使用 AppButton 替换 ElevatedButton.icon ***
    return FunctionalButton(
      // --- 传递参数给 AppButton ---
      label: '预览游戏详情',
      icon: Icons.visibility_outlined, // 使用 AppButton 的 icon 参数
      // onPressed 逻辑保持不变
      onPressed: () {
        _handlePreview(context);
      },
    );
  }
}
