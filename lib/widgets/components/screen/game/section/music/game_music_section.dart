// lib/widgets/components/screen/game/section/music/game_music_section.dart

/// 该文件定义了 [GameMusicSection] 组件，用于显示游戏的音乐播放器。
/// [GameMusicSection] 接收一个处理好的嵌入式URL，并负责展示网页播放器。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

/// [GameMusicSection] 类：显示游戏相关音乐的 StatefulWidget。
///
/// 该组件假定传入的 [embedUrl] 是一个可直接播放的嵌入式URL，
/// 不再进行任何解析。它负责管理播放器的加载和UI展示。
class GameMusicSection extends StatefulWidget {
  final String? embedUrl; // 经过处理的、可直接播放的嵌入式URL

  const GameMusicSection({
    super.key,
    required this.embedUrl,
  });

  @override
  State<GameMusicSection> createState() => _GameMusicSectionState();
}

class _GameMusicSectionState extends State<GameMusicSection> {
  bool _isLoading = false;
  String? _loadingError;
  bool _showWebView = false;

  @override
  void didUpdateWidget(covariant GameMusicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.embedUrl != oldWidget.embedUrl) {
      // 如果 URL 变化，重置所有状态，让用户可以重新点击播放
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingError = null;
          _showWebView = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedUrl == null) {
      return const SizedBox.shrink(); // 没有有效的URL，不显示任何东西
    }

    final isPortrait = DeviceUtils.isPortrait(context);

    return Column(
      key: ValueKey('music_section_${widget.embedUrl}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(context),
        const SizedBox(height: 12),
        if (isPortrait)
          _buildPortraitPrompt()
        else if (_showWebView)
          _buildLandscapeWebViewContainer()
        else
          _buildPlayInitiatorWidget(),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          '相关音乐',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.screen_rotation_rounded,
              size: 32, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            '请旋转至横屏以播放音乐',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayInitiatorWidget() {
    return InkWell(
      onTap: () {
        setState(() {
          _showWebView = true;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: DeviceUtils.isDesktop ? 100 : 86.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline_rounded,
                size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '点击播放音乐',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeWebViewContainer() {
    return SizedBox(
      height: DeviceUtils.isDesktop ? 100 : 86.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            EmbeddedWebView(
              key: ValueKey('music_webview_${widget.embedUrl}'),
              initialUrl: widget.embedUrl!,
              onPageStarted: (url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _loadingError = null;
                  });
                }
              },
              onPageFinished: (url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _loadingError = '播放器加载失败';
                  });
                }
              },
            ),
            if (_isLoading || _loadingError != null)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLowest
                      .withSafeOpacity(0.9),
                  child: _loadingError != null
                      ? _buildErrorOverlay()
                      : const LoadingWidget(message: '播放器加载中', size: 24.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.error, size: 24),
        const SizedBox(height: 4),
        Text(
          _loadingError!,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.error, fontSize: 11),
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () {
            setState(() {
              _loadingError = null;
              _isLoading = true;
            });
          },
          child: const Text("重试", style: TextStyle(fontSize: 11)),
        )
      ],
    );
  }
}
