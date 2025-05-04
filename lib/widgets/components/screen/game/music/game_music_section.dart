// lib/widgets/components/screen/game/music/game_music_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart'; // 确保导入
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

class GameMusicSection extends StatefulWidget {
  final String? musicUrl;

  const GameMusicSection({
    super.key,
    required this.musicUrl,
  });

  @override
  State<GameMusicSection> createState() => _GameMusicSectionState();
}

class _GameMusicSectionState extends State<GameMusicSection> {
  String? _embedUrl;
  bool _isLoading = true;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _parseAndSetEmbedUrl();
  }

  @override
  void didUpdateWidget(covariant GameMusicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.musicUrl != oldWidget.musicUrl) {
      _parseAndSetEmbedUrl();
    }
  }

  void _parseAndSetEmbedUrl() {
    setState(() {
      _isLoading = true;
      _loadingError = null;
      _embedUrl = _buildEmbedUrl(widget.musicUrl);
      if (_embedUrl == null && widget.musicUrl != null && widget.musicUrl!.isNotEmpty) {
        _loadingError = '无法解析有效的网易云音乐 ID';
      }
      if (_embedUrl == null) {
        _isLoading = false;
      }
    });
  }

  String? _buildEmbedUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(originalUrl);
      if (uri.host.contains('music.163.com') && (uri.pathSegments.contains('song') || uri.path.contains("/#"))) {
        String? songId = uri.queryParameters['id'];
        if (songId == null && uri.fragment.contains('song?id=')) {
          final fragmentUri = Uri.parse('dummy://dummy${uri.fragment}');
          songId = fragmentUri.queryParameters['id'];
        }
        if (songId != null && songId.isNotEmpty) {
          return 'https://music.163.com/outchain/player?type=2&id=$songId&auto=0&height=86'; // 统一用 86
        }
      }
    } catch (e) { print("Error parsing music URL '$originalUrl': $e"); return null; }
    print("Could not extract song ID from music URL: $originalUrl");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // --- [核心改动] 直接在 build 里判断屏幕方向 ---
    final isPortrait = DeviceUtils.isPortrait(context);

    // 如果 URL 解析失败或为空，显示错误或不显示
    if (_embedUrl == null) {
      if (_loadingError != null) {
        // 只显示错误信息，包含在一个简单的 Column 里
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ _buildTitleRow(context), const SizedBox(height: 12), _buildErrorWidget() ]
        );
      } else {
        // URL 无效且无错误，不显示
        return const SizedBox.shrink();
      }
    }

    // --- 根据方向构建不同的 Widget 树 ---
    if (isPortrait) {
      // **** 竖屏：只显示标题和提示 ****
      return Column(
        key: const ValueKey('music_portrait_layout'), // 给竖屏布局一个 Key
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context), // 显示标题
          const SizedBox(height: 12),
          _buildPortraitPrompt(), // 显示提示语
        ],
      );
    } else {
      // **** 横屏：显示标题和带固定高度的 WebView ****
      return Column(
        key: const ValueKey('music_landscape_layout'), // 给横屏布局一个 Key
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context), // 显示标题
          const SizedBox(height: 12),
          _buildLandscapeWebView(), // 显示 WebView
        ],
      );
    }
  }

  // --- 辅助方法：构建标题行 ---
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration( color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text('相关音乐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
      ],
    );
  }

  // --- 辅助方法：构建竖屏提示语 ---
  Widget _buildPortraitPrompt() {
    return Container( // 用 Container 包裹，可以设置背景和内边距
      key: const ValueKey('portrait_prompt_widget'),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration( // 可以给个背景色和圆角，让它像个卡片
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.screen_rotation_rounded, size: 32, color: Colors.grey[600]),
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

  // --- 辅助方法：构建横屏 WebView ---
  Widget _buildLandscapeWebView() {
    return SizedBox(
      key: const ValueKey('landscape_webview_container'),
      height: 86.0, // 固定高度
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
              key: ValueKey('music_webview_$_embedUrl'),
              initialUrl: _embedUrl!,
              onPageStarted: (url) { if (mounted) setState(() { _isLoading = true; _loadingError = null; }); },
              onPageFinished: (url) { if (mounted) setState(() { _isLoading = false; }); },
              onWebResourceError: (error) { if (mounted) setState(() { _isLoading = false; _loadingError = '音乐播放器加载失败'; }); },
            ),
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isLoading ? LoadingWidget.inline(message: '加载中...', size: 24.0) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // --- 辅助方法：构建错误 Widget (用于 URL 解析错误或 WebView 加载错误) ---
  Widget _buildErrorWidget() {
    return Container(
      key: const ValueKey('music_error_widget'),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1), // 给个错误背景
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 24),
          const SizedBox(height: 6),
          Text(
            _loadingError ?? '加载音乐时发生未知错误',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            onPressed: _parseAndSetEmbedUrl, // 点击重试
            child: const Text('重试', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

// 不再需要 _buildErrorState 和 _buildContent 方法
}