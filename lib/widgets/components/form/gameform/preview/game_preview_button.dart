// lib/widgets/form/gameform/preview/game_preview_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import 'game_preview_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class GamePreviewButton extends StatelessWidget {
  // --- 参数保持不变 ---
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController descriptionController;
  final String? coverImageUrl;
  final List<String> gameImages;
  final String? selectedCategory;
  final List<String> selectedTags;
  final double rating;
  final List<DownloadLink> downloadLinks;
  final TextEditingController? musicUrlController;
  final TextEditingController? bvidController;
  final Game? existingGame;

  const GamePreviewButton({
    super.key,
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


  void _handlePreview(BuildContext context){


    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserId;

    final bvid = bvidController!.text.isEmpty ? null : bvidController?.text;
    final musicUrl = musicUrlController!.text.isEmpty ? null : musicUrlController?.text;


    final isValidMusic = bvid == null ? true : _validateBV(bvid);
    final isValidBV = musicUrl == null ? true : _validateMusic(musicUrl);
    final passValid = isValidMusic && isValidBV;
    print(musicUrl);
    print(isValidBV);
    print(isValidMusic);

    if (!isValidMusic){
      return AppSnackBar.showWarning(context, "点我也没用，检查填的有没有问题");
    }
    if (!isValidBV){
      return AppSnackBar.showWarning(context, "点我也没用，检查填的有没有问题");
    }
    final previewGame = Game(
      id: existingGame?.id ?? mongo.ObjectId().oid,
      authorId: existingGame?.authorId ?? currentUserId ?? 'preview_mode',
      title: titleController.text.isEmpty ? "游戏标题预览" : titleController.text,
      summary: summaryController.text.isEmpty ? "游戏简介预览" : summaryController.text,
      description: descriptionController.text.isEmpty ? "游戏详细描述预览" : descriptionController.text,
      category:  selectedCategory == null ? "生肉" : selectedCategory!,
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

    if (passValid){
      NavigationUtils.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePreviewScreen(game: previewGame),
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