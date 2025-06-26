// lib/widgets/components/screen/game/music/game_music_section.dart

/// 该文件定义了 GameMusicSection 组件，用于显示游戏的音乐播放器。
/// GameMusicSection 负责解析音乐链接并嵌入网页播放器。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart'; // 嵌入式 WebView 组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需

/// [GameMusicSection] 类：显示游戏相关音乐的 StatefulWidget。
///
/// 该组件处理音乐 URL 的解析、嵌入式 WebView 的显示和加载状态。
class GameMusicSection extends StatefulWidget {
  final String? musicUrl; // 音乐链接

  /// 构造函数。
  ///
  /// [musicUrl]：音乐链接。
  const GameMusicSection({
    super.key,
    required this.musicUrl,
  });

  @override
  State<GameMusicSection> createState() => _GameMusicSectionState();
}

class _GameMusicSectionState extends State<GameMusicSection> {
  String? _embedUrl; // 嵌入式播放器 URL
  bool _isLoading = true; // 加载状态，用于URL解析和WebView加载
  String? _loadingError; // 加载错误信息
  bool _showWebView = false; // 控制 WebView 的显示状态

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    _parseAndSetEmbedUrl(); // 解析并设置嵌入式 URL
  }

  @override
  void didUpdateWidget(covariant GameMusicSection oldWidget) {
    super.didUpdateWidget(oldWidget); // 调用父类 didUpdateWidget
    if (widget.musicUrl != oldWidget.musicUrl) {
      // 音乐 URL 变化时
      _parseAndSetEmbedUrl(); // 重新解析并设置嵌入式 URL
    }
  }

  /// 解析原始音乐 URL 并设置嵌入式 URL。
  ///
  /// 该方法更新加载状态，并根据解析结果设置嵌入式 URL 和错误信息。
  void _parseAndSetEmbedUrl() {
    setState(() {
      _isLoading = true; // 设置为加载中状态
      _loadingError = null; // 清除错误信息
      _embedUrl = null; // 清空嵌入式 URL
      _showWebView = false; // 重置 WebView 显示状态，要求用户重新点击播放
    });

    final newEmbedUrl = _buildEmbedUrl(widget.musicUrl); // 构建新的嵌入式 URL

    // 延迟更新，以显示加载状态
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return; // 组件未挂载时退出
      setState(() {
        _embedUrl = newEmbedUrl; // 设置嵌入式 URL
        if (_embedUrl == null &&
            widget.musicUrl != null &&
            widget.musicUrl!.isNotEmpty) {
          _loadingError = '无法解析有效的网易云音乐 ID 或链接格式不受支持'; // 设置错误信息
        }
        _isLoading = false; // 清除加载中状态
      });
    });
  }

  /// 从原始 URL 构建网易云音乐嵌入式 URL。
  ///
  /// [originalUrl]：原始音乐 URL。
  /// 返回解析后的嵌入式 URL，或 null 表示解析失败。
  String? _buildEmbedUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty)
      return null; // 原始 URL 无效时返回 null
    try {
      final uri = Uri.parse(originalUrl); // 解析 URL
      if (uri.host.contains('music.163.com')) {
        // 检查是否为网易云音乐域名
        String? songId;
        if (uri.queryParameters.containsKey('id')) {
          // 从查询参数中提取歌曲 ID
          songId = uri.queryParameters['id'];
        } else if (uri.fragment.contains('song?id=')) {
          // 从片段中提取歌曲 ID
          final fragmentUri = Uri.parse('dummy://dummy${uri.fragment}');
          songId = fragmentUri.queryParameters['id'];
        } else if (uri.pathSegments.length >= 2 &&
            uri.pathSegments.first == 'song') {
          // 从路径段中提取歌曲 ID
          final potentialId = uri.pathSegments[1];
          if (RegExp(r'^\d+$').hasMatch(potentialId)) {
            songId = potentialId;
          }
        }

        if (songId != null && songId.isNotEmpty) {
          // 歌曲 ID 有效时构建嵌入式 URL
          return 'https://music.163.com/outchain/player?type=2&id=$songId&auto=0&height=86';
        }
      }
    } catch (e) {
      // 捕获 URL 解析异常
      return null;
    }
    return null; // 未能提取歌曲 ID 时返回 null
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = DeviceUtils.isPortrait(context); // 判断是否为竖屏

    if (_isLoading && _embedUrl == null && !_showWebView) {
      // URL 正在解析或解析失败时显示加载
      return Column(
        key: const ValueKey('music_initial_loading'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context), // 构建标题行
          const SizedBox(height: 12), // 垂直间距
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: LoadingWidget(
              message: '解析乐谱链接中',
              size: 24.0,
            ),
          ),
        ],
      );
    }

    if (_embedUrl == null) {
      // URL 解析完成但嵌入式 URL 为空
      if (_loadingError != null) {
        // 存在错误信息时显示错误
        return Column(
            key: const ValueKey('music_url_error'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context), // 构建标题行
              const SizedBox(height: 12), // 垂直间距
              _buildErrorWidget(_loadingError!) // 构建错误信息 Widget
            ]);
      } else if (widget.musicUrl != null && widget.musicUrl!.isNotEmpty) {
        // 有原始 URL 但无法解析
        return Column(
            key: const ValueKey('music_url_invalid_format'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context), // 构建标题行
              const SizedBox(height: 12), // 垂直间距
              _buildErrorWidget('无法识别的音乐链接格式，请检查链接是否正确。') // 构建错误信息 Widget
            ]);
      } else {
        return const SizedBox.shrink(); // 原始 URL 为空时隐藏组件
      }
    }

    if (isPortrait) {
      // 竖屏模式
      return Column(
        key: const ValueKey('music_portrait_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context), // 构建标题行
          const SizedBox(height: 12), // 垂直间距
          _buildPortraitPrompt(), // 构建竖屏提示
        ],
      );
    } else {
      // 横屏模式
      return Column(
        key: const ValueKey('music_landscape_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context), // 构建标题行
          const SizedBox(height: 12), // 垂直间距
          if (_showWebView) // 显示 WebView
            _buildLandscapeWebViewContainer()
          else // 显示“点击播放”提示
            _buildPlayInitiatorWidget(),
        ],
      );
    }
  }

  /// 构建标题行。
  ///
  /// [context]：Build 上下文。
  /// 返回包含标题和装饰的 Row Widget。
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
        const SizedBox(width: 8), // 间距
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

  /// 构建竖屏提示 Widget。
  ///
  /// 返回一个提示用户旋转屏幕以播放音乐的容器。
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
          Icon(
            Icons.screen_rotation_rounded,
            size: 32,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12), // 垂直间距
          Text(
            '请旋转至横屏以播放音乐',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建“点击播放”的占位符或按钮 Widget。
  ///
  /// 返回一个用户点击后显示 WebView 的交互式 Widget。
  Widget _buildPlayInitiatorWidget() {
    return InkWell(
      key: const ValueKey('play_initiator_widget'),
      onTap: () {
        setState(() {
          _showWebView = true; // 点击后显示 WebView
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
            const SizedBox(height: 8), // 垂直间距
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

  /// 构建横屏模式下的 WebView 容器。
  ///
  /// 该方法构建 WebView 及其容器，仅当 `_showWebView` 为 true 时有效。
  Widget _buildLandscapeWebViewContainer() {
    if (_embedUrl == null)
      return _buildErrorWidget("内部错误：无法加载音乐播放器"); // 嵌入式 URL 无效时显示错误

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
            EmbeddedWebView(
              key: ValueKey(
                  'music_webview_$_embedUrl'), // 使用唯一键确保 URL 变化时 WebView 重建
              initialUrl: _embedUrl!, // 初始加载 URL
              onPageStarted: (url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true; // WebView 开始加载页面
                    _loadingError = null; // 清除错误信息
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
                    _isLoading = false; // 清除加载状态
                    _loadingError = '音乐播放器加载失败: ${error.description}'; // 设置错误信息
                  });
                }
              },
            ),
            if (_isLoading) // WebView 正在加载页面时显示加载指示器
              Positioned.fill(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLowest
                      .withSafeOpacity(0.8),
                  child: const LoadingWidget(message: '播放器加载中', size: 24.0),
                ),
              ),
            if (!_isLoading &&
                _loadingError != null &&
                _showWebView) // WebView 加载完成但有错误时显示错误信息
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
                      const SizedBox(height: 4), // 垂直间距
                      Text(
                        _loadingError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // 垂直间距
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _loadingError = null; // 清除错误信息
                            _isLoading = true; // 触发 WebView 重新加载
                            _embedUrl = _embedUrl!; // 强制更新 URL 以触发 WebView 重建
                          });
                        },
                        child: const Text("重试"), // 重试按钮
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

  /// 构建错误信息 Widget。
  ///
  /// [errorMessage]：要显示的错误消息。
  /// 返回一个显示错误信息和重试按钮的容器。
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
          const SizedBox(height: 6), // 垂直间距
          Text(
            errorMessage, // 错误消息
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
          const SizedBox(height: 8), // 垂直间距
          TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            onPressed: _parseAndSetEmbedUrl, // 点击重试解析 URL
            child: const Text('重试解析', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
