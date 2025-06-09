// lib/widgets/components/screen/game/music/game_music_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart'; // 确保导入
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
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
  bool _isLoading = true; // true: 初始解析URL时 / WebView加载页面时
  String? _loadingError;
  bool _showWebView = false; // 新增：控制是否显示 WebView

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
      _isLoading = true; // 开始解析，显示加载
      _loadingError = null;
      _embedUrl = null; // 先清空，避免旧的URL残留
      _showWebView = false; // 重要：URL变化时，重置WebView的显示状态，需要用户重新点击播放
    });

    final newEmbedUrl = _buildEmbedUrl(widget.musicUrl);

    // 延迟一点更新，让Loading有机会显示
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _embedUrl = newEmbedUrl;
        if (_embedUrl == null &&
            widget.musicUrl != null &&
            widget.musicUrl!.isNotEmpty) {
          _loadingError = '无法解析有效的网易云音乐 ID 或链接格式不受支持';
        }
        _isLoading = false; // URL解析完成（无论成功与否）
      });
    });
  }

  String? _buildEmbedUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(originalUrl);
      if (uri.host.contains('music.163.com')) {
        String? songId;
        // 匹配 https://music.163.com/#/song?id=xxxx
        // 匹配 https://music.163.com/song?id=xxxx
        // 匹配 https://music.163.com/song/xxxx/
        // 匹配 https://y.music.163.com/m/song?id=xxxx (移动版分享)
        if (uri.queryParameters.containsKey('id')) {
          songId = uri.queryParameters['id'];
        } else if (uri.fragment.contains('song?id=')) {
          final fragmentUri = Uri.parse('dummy://dummy${uri.fragment}');
          songId = fragmentUri.queryParameters['id'];
        } else if (uri.pathSegments.length >= 2 &&
            uri.pathSegments.first == 'song') {
          // 尝试从路径中提取ID，例如 /song/12345/
          final potentialId = uri.pathSegments[1];
          if (RegExp(r'^\d+$').hasMatch(potentialId)) {
            songId = potentialId;
          }
        }

        if (songId != null && songId.isNotEmpty) {
          return 'https://music.163.com/outchain/player?type=2&id=$songId&auto=0&height=86';
        }
      }
    } catch (e) {
      // print("Error parsing music URL '$originalUrl': $e");
      return null;
    }
    // print("Could not extract song ID from music URL: $originalUrl");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = DeviceUtils.isPortrait(context);

    // 阶段1: URL 正在解析或解析失败
    if (_isLoading && _embedUrl == null && !_showWebView) {
      // _isLoading 为true表示正在解析URL
      return Column(
        key: const ValueKey('music_initial_loading'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: LoadingWidget(
              message: '解析乐谱链接中...',
              size: 24.0,
            ),
          ),
        ],
      );
    }

    // 阶段2: URL 解析完成，但 embedUrl 为空 (无效URL或解析错误)
    if (_embedUrl == null) {
      if (_loadingError != null) {
        return Column(
            key: const ValueKey('music_url_error'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context),
              const SizedBox(height: 12),
              _buildErrorWidget(_loadingError!) // 传入具体的错误信息
            ]);
      } else if (widget.musicUrl != null && widget.musicUrl!.isNotEmpty) {
        // 有 musicUrl 但解析不出 embedUrl，且没有特定错误（可能是不支持的格式）
        return Column(
            key: const ValueKey('music_url_invalid_format'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context),
              const SizedBox(height: 12),
              _buildErrorWidget('无法识别的音乐链接格式，请检查链接是否正确。')
            ]);
      } else {
        return const SizedBox.shrink(); // musicUrl 为空，不显示任何东西
      }
    }

    // 阶段3: URL 解析成功，embedUrl 有效
    if (isPortrait) {
      return Column(
        key: const ValueKey('music_portrait_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context),
          const SizedBox(height: 12),
          _buildPortraitPrompt(),
        ],
      );
    } else {
      // 横屏模式
      return Column(
        key: const ValueKey('music_landscape_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context),
          const SizedBox(height: 12),
          if (_showWebView) // 如果用户点击了播放，则显示WebView
            _buildLandscapeWebViewContainer()
          else // 否则显示“点击播放”的提示
            _buildPlayInitiatorWidget(),
        ],
      );
    }
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
        Text('相关音乐',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildPortraitPrompt() {
    return Container(
      key: const ValueKey('portrait_prompt_widget'),
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

  // 新增：构建“点击播放”的占位符/按钮
  Widget _buildPlayInitiatorWidget() {
    return InkWell(
      key: const ValueKey('play_initiator_widget'),
      onTap: () {
        setState(() {
          _showWebView = true;
          // _isLoading = true; // WebView即将开始加载，它的onPageStarted会处理
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: DeviceUtils.isDesktop ? 100 : 86.0,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded,
                size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '点击播放音乐',
              textAlign: TextAlign.center,
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

  // 修改：原 _buildLandscapeWebView 改名为 _buildLandscapeWebViewContainer
  // 它现在只负责构建 WebView 及其容器，前提是 _showWebView 为 true
  Widget _buildLandscapeWebViewContainer() {
    // 如果 _embedUrl 在这里仍然是 null (理论上不应该，因为外层已经判断过)
    // 但作为防御性编程，可以再检查一下
    if (_embedUrl == null) return _buildErrorWidget("内部错误：无法加载音乐播放器");

    return SizedBox(
      key: const ValueKey('landscape_webview_container'),
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
            // WebView现在只有在_showWebView为true时才会被构建
            EmbeddedWebView(
              key: ValueKey(
                  'music_webview_$_embedUrl'), // 使用ValueKey确保URL变化时WebView重建
              initialUrl: _embedUrl!,
              onPageStarted: (url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true; // WebView 开始加载页面
                    _loadingError = null;
                  });
                }
              },
              onPageFinished: (url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false; // WebView 页面加载完成
                  });
                }
              },
              onWebResourceError: (error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    // 这里不直接隐藏 WebView，而是显示错误信息在 WebView 区域内
                    // 或者也可以考虑设置 _showWebView = false 并显示一个通用的错误提示
                    _loadingError = '音乐播放器加载失败: ${error.description}';
                    // 如果遇到错误，可以考虑让用户能重试，比如显示一个重试按钮
                    // 或者简单地提示错误，用户可能需要刷新整个页面或检查网络
                  });
                }
              },
            ),
            // 这个 LoadingWidget 和错误提示是针对 WebView 加载过程的
            if (_isLoading) // WebView 正在加载页面时显示
              Positioned.fill(
                child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLowest
                        .withSafeOpacity(0.8),
                    child:
                        const LoadingWidget(message: '播放器加载中...', size: 24.0)),
              ),
            if (!_isLoading &&
                _loadingError != null &&
                _showWebView) // WebView 加载完成但有错误
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        _loadingError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          // 简单的重试：重新加载WebView
                          setState(() {
                            _loadingError = null;
                            _isLoading = true; // 触发WebView重新加载的loading
                            // Key的改变会强制WebView重建并重新加载initialUrl
                            // 为了更明确的重载，理想情况下EmbeddedWebView应有reload方法
                            // 这里通过改变key来强制重建
                            // 或者，如果WebView支持，调用其reload方法
                            // _showWebView = false; // 先隐藏
                            // Future.delayed(Duration(milliseconds: 50), () => setState(()=> _showWebView = true));
                            _embedUrl =
                                _embedUrl!; // 技巧：稍微改变URL（如加个空串）或改变Key来强制刷新
                          });
                        },
                        child: const Text("重试"),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      key: const ValueKey('music_error_widget'),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.errorContainer.withSafeOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error, size: 24),
          const SizedBox(height: 6),
          Text(
            errorMessage, // 使用传入的错误信息
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            onPressed: _parseAndSetEmbedUrl, // 点击重试解析URL
            child: const Text('重试解析', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
