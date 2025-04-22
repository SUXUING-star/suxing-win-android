// lib/widgets/components/screen/game/music/game_music_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
// 使用通用错误 Widget

class GameMusicSection extends StatefulWidget {
  final String? musicUrl; // 接收原始 musicUrl

  const GameMusicSection({
    super.key,
    required this.musicUrl,
  });

  @override
  State<GameMusicSection> createState() => _GameMusicSectionState();
}

class _GameMusicSectionState extends State<GameMusicSection> {
  String? _embedUrl; // 存储解析后的嵌入 URL
  bool _isLoading = true; // 初始状态为加载中
  String? _loadingError; // 记录加载错误

  @override
  void initState() {
    super.initState();
    _parseAndSetEmbedUrl();
  }

  @override
  void didUpdateWidget(covariant GameMusicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 musicUrl 变了，重新解析
    if (widget.musicUrl != oldWidget.musicUrl) {
      _parseAndSetEmbedUrl();
    }
  }

  void _parseAndSetEmbedUrl() {
    setState(() {
      _isLoading = true; // 开始处理或重新处理，显示 Loading
      _loadingError = null; // 清除旧错误
      _embedUrl = _buildEmbedUrl(widget.musicUrl);
      // 如果 URL 无效，直接标记为非加载状态（因为没什么可加载的）
      if (_embedUrl == null &&
          widget.musicUrl != null &&
          widget.musicUrl!.isNotEmpty) {
        _loadingError = '无法解析有效的网易云音乐 ID';
      }
      // URL有效才需要等待 WebView 加载，WebView 的回调会设置 isLoading = false
      // 如果 URL 本身就无效，这里就不应该保持 isLoading = true 了
      if (_embedUrl == null) {
        _isLoading = false;
      }
    });
  }

  // 解析原始 musicUrl 并构建嵌入式播放器 URL
  String? _buildEmbedUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(originalUrl);
      // 检查是否是 music.163.com 的域名，并且路径包含 'song'
      if (uri.host.contains('music.163.com') &&
          (uri.pathSegments.contains('song') || uri.path.contains("/#"))) {
        // 尝试从 queryParameters 获取 'id'
        String? songId = uri.queryParameters['id'];

        // 特殊处理 /#/song?id=xxx 的情况
        if (songId == null && uri.fragment.contains('song?id=')) {
          final fragmentUri =
              Uri.parse('dummy://dummy${uri.fragment}'); // 构造虚拟URI解析fragment
          songId = fragmentUri.queryParameters['id'];
        }

        if (songId != null && songId.isNotEmpty) {
          // 构建标准的网易云外链播放器 URL
          // height=66 是比较小的播放器，可以根据需要调整 86 等
          // auto=0 禁止自动播放
          return 'https://music.163.com/outchain/player?type=2&id=$songId&auto=0&height=66';
        }
      }
    } catch (e) {
      print("Error parsing music URL '$originalUrl': $e");
      // 解析失败，返回 null
      return null;
    }

    // 如果上面都没匹配到，返回 null
    print("Could not extract song ID from music URL: $originalUrl");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 如果解析后的 embedUrl 是 null，就不显示这个 Section
    if (_embedUrl == null && _loadingError == null) {
      // 如果 URL 为空或无效但没有解析错误，则不显示
      if (widget.musicUrl == null || widget.musicUrl!.isEmpty) {
        return const SizedBox.shrink();
      }
      // 如果 URL 有值但解析失败（在 _parseAndSetEmbedUrl 中设置了 _loadingError），则显示错误
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 标题
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // 换个颜色区分
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '相关音乐', // 标题改成音乐
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // 标题和播放器之间的间距

        // 2. 音乐播放器区域
        SizedBox(
          // 网易云小播放器推荐高度是 86，我们给多一点空间 100-120
          height: 110, // 固定高度，避免 WebView 高度变化影响布局
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8), // 给个圆角
            ),
            clipBehavior: Clip.antiAlias, // 裁切内容
            child: _buildContent(), // 根据状态构建内容
          ),
        ),
      ],
    );
  }

  // 构建播放器或加载/错误状态
  Widget _buildContent() {
    if (_loadingError != null) {
      // --- 显示错误状态 ---
      return _buildErrorState();
    } else if (_embedUrl == null) {
      // 虽然理论上在 build 方法开头处理了，但为了安全再检查一次
      return const SizedBox.shrink();
    } else {
      // --- 显示 WebView 和可能的 Loading ---
      // 使用 Stack 将 Loading 覆盖在 WebView 上
      return Stack(
        key: ValueKey('music_stack_${widget.musicUrl}'), // Key 基于原始 URL
        alignment: Alignment.center,
        children: [
          // WebView 层
          EmbeddedWebView(
            // Key 基于 embedUrl，确保 URL 变化时重建
            key: ValueKey('music_webview_$_embedUrl'),
            initialUrl: _embedUrl!,
            onPageStarted: (url) {
              if (mounted && !_isLoading) {
                // 只有在非加载状态下收到 page started 才重置为 loading
                setState(() {
                  _isLoading = true;
                  _loadingError = null;
                });
              } else if (mounted && _loadingError != null) {
                // 如果之前有错误，开始加载时清除错误
                setState(() {
                  _loadingError = null;
                  _isLoading = true; // 确保是加载状态
                });
              }
            },
            onPageFinished: (url) {
              // 页面加载完成，取消 Loading 状态
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              // 加载出错，取消 Loading 并记录错误
              print("WebView Error in GameMusicSection: $error");
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingError =
                      '音乐播放器加载失败: ${error.toString().substring(0, 50)}...'; // 显示错误信息
                });
              }
            },
          ),

          // Loading 层 (仅在 _isLoading 为 true 时显示)
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? LoadingWidget.inline(
                    message: '加载中...',
                    size: 24.0, // 可以小一点
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }
  }

  // 构建错误状态的辅助方法
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('music_error_state'),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // 内部留白小一点
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.orangeAccent, size: 24), // 图标小一点
            const SizedBox(height: 6),
            Text(
              _loadingError ?? '加载音乐时发生未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12), // 字号小一点
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact, // 更紧凑
              ),
              onPressed: _parseAndSetEmbedUrl, // 点击重试重新解析和加载
              child: const Text('重试', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
