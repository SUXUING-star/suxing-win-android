// lib/widgets/components/screen/game/section/download/game_download_links_section.dart

/// 该文件定义了 [GameDownloadLinksSection] 组件，一个用于显示游戏下载链接的 StatelessWidget。
///
/// [GameDownloadLinksSection] 根据用户登录状态展示下载链接列表或登录提示，并提供添加新链接的入口。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game/game_download_link.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/download/add_game_download_actions.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/download/game_download_link_card.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/download/game_download_login_prompt.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';

/// [GameDownloadLinksSection] 类：显示游戏下载链接及相关操作的组件。
class GameDownloadLinksSection extends StatelessWidget {
  /// 游戏下载链接列表。
  final List<GameDownloadLink> downloadLinks;

  /// 当前登录用户。
  final User? currentUser;

  /// 添加新链接的【异步】回调函数。
  final Future<void> Function(GameDownloadLink)? onAddLink;

  /// 指示当前是否正在执行添加操作的标志。
  final bool isAdd;

  /// 是否为预览模式。
  final bool isPreviewMode;

  /// 用于管理输入框状态的服务。
  final InputStateService inputStateService;

  /// 构造函数。
  const GameDownloadLinksSection({
    super.key,
    required this.currentUser,
    required this.downloadLinks,
    this.onAddLink,
    required this.isAdd,
    required this.isPreviewMode,
    required this.inputStateService,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const GameDownloadLoginPrompt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '下载资源',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              // 如果 onAddLink 回调不为 null，才显示操作按钮组
              if (onAddLink != null)
                AddGameDownloadActions(
                  onAddLink: onAddLink,
                  isAdding: isAdd,
                  currentUserId: currentUser?.id,
                  isPreviewMode: isPreviewMode,
                  inputStateService: inputStateService,
                ),
            ],
          ),
        ),
        if (downloadLinks.isEmpty)
          const EmptyStateWidget(
            message: '暂无下载链接，快来补充第一个吧！',
            iconData: Icons.link_off,
          ),
        ...downloadLinks.map(
          (link) => GameDownLoadLinkCard(
            link: link,
          ),
        ),
      ],
    );
  }
}
