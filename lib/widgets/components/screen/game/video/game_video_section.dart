// lib/widgets/components/screen/game/video/game_video_section.dart

/// 该文件定义了 GameVideoSection 组件，用于显示游戏的相关视频。
/// GameVideoSection 根据 bvid 动态加载并显示 Bilibili 视频播放器。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart'; // 内嵌 WebView 组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载指示器组件

/// `GameVideoSection` 类：游戏相关视频板块组件。
///
/// 该组件根据提供的 Bilibili 视频 ID，先显示一个加载按钮，
/// 用户点击后加载并显示内嵌的视频播放器，并处理加载中和错误状态。
class GameVideoSection extends StatefulWidget {
  final String? bvid; // 视频的 Bilibili bvid

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [bvid]：要加载的视频的 bvid。
  const GameVideoSection({
    super.key,
    required this.bvid,
  });

  @override
  State<GameVideoSection> createState() => _GameVideoSectionState();
}

/// `_GameVideoSectionState` 类：`GameVideoSection` 的状态管理。
class _GameVideoSectionState extends State<GameVideoSection> {
  bool _shouldLoadVideo = false; // 用户是否点击了加载按钮
  bool _isLoadingVideo = false; // WebView 是否正在加载页面
  String? _loadingError; // 记录加载错误信息

  /// 根据 bvid 构建嵌入式播放器 URL。
  ///
  /// 如果 bvid 无效，返回 null。
  String? get _embedUrl {
    if (widget.bvid == null || widget.bvid!.isEmpty) {
      // 检查 bvid 是否有效
      return null;
    }
    return 'https://player.bilibili.com/player.html?bvid=${widget.bvid}'; // 构建 Bilibili 嵌入式播放器 URL
  }

  /// 当 Widget 的配置发生变化时调用。
  ///
  /// 如果 bvid 发生变化，重置视频加载状态。
  @override
  void didUpdateWidget(covariant GameVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bvid != oldWidget.bvid) {
      // 检查 bvid 是否发生变化
      if (mounted) {
        // 检查组件是否已挂载
        setState(() {
          _shouldLoadVideo = false; // 重置加载状态
          _isLoadingVideo = false; // 重置加载中状态
          _loadingError = null; // 清除错误信息
        });
      }
    }
  }

  /// 启动视频加载。
  ///
  /// 设置加载状态为 true，并清除之前的错误信息。
  void _startLoadingVideo() {
    if (_embedUrl != null && mounted) {
      // 检查 URL 有效且组件已挂载
      setState(() {
        _shouldLoadVideo = true; // 设置为需要加载视频
        _isLoadingVideo = true; // 设置为正在加载
        _loadingError = null; // 清除错误信息
      });
    }
  }

  /// 构建 Widget。
  ///
  /// 根据 bvid 和加载状态渲染标题和视频区域。
  @override
  Widget build(BuildContext context) {
    final currentEmbedUrl = _embedUrl; // 获取当前嵌入 URL

    if (currentEmbedUrl == null) {
      // 如果 URL 无效，不显示任何东西
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // 主题色
                borderRadius: BorderRadius.circular(2), // 圆角
              ),
            ),
            SizedBox(width: 8), // 间距
            Text(
              '相关视频', // 标题文本
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        AspectRatio(
          aspectRatio: 16 / 9, // 固定宽高比
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerLowest, // 背景色
              borderRadius: BorderRadius.circular(12), // 圆角
            ),
            clipBehavior: Clip.antiAlias, // 裁剪超出部分
            child: AnimatedSwitcher(
              // 动画切换器
              duration: const Duration(milliseconds: 300), // 动画时长
              child: _buildContent(currentEmbedUrl), // 根据状态构建内容
            ),
          ),
        ),
      ],
    );
  }

  /// 根据状态构建内容的辅助方法。
  ///
  /// [currentEmbedUrl]：当前的嵌入 URL。
  /// 根据错误、加载和初始状态返回不同的 Widget。
  Widget _buildContent(String currentEmbedUrl) {
    if (_loadingError != null) {
      // 显示错误状态
      return _buildErrorState();
    } else if (_shouldLoadVideo) {
      // 显示 WebView 和加载指示器
      return Stack(
        key: ValueKey('video_stack_${widget.bvid}'), // Key
        alignment: Alignment.center, // 居中对齐
        children: [
          EmbeddedWebView(
            key: ValueKey('webview_$currentEmbedUrl'), // Key
            initialUrl: currentEmbedUrl, // 初始 URL
            onPageStarted: (url) {
              if (mounted && !_isLoadingVideo) {
                setState(() {
                  _isLoadingVideo = true; // 页面开始加载时设置加载状态
                  _loadingError = null; // 清除错误信息
                });
              }
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() {
                  _isLoadingVideo = false; // 页面加载完成时取消加载状态
                });
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _isLoadingVideo = false; // 加载出错时取消加载状态
                  _loadingError = '视频加载失败，请稍后重试。'; // 设置错误信息
                });
              }
            },
          ),
          AnimatedOpacity(
            opacity: _isLoadingVideo ? 1.0 : 0.0, // 根据加载状态设置透明度
            duration: const Duration(milliseconds: 200), // 动画时长
            child: _isLoadingVideo
                ? const LoadingWidget(
                    // 加载时显示加载指示器
                    message: '加载中...',
                    size: 32.0,
                  )
                : const SizedBox.shrink(), // 不加载时显示空 Widget
          ),
        ],
      );
    } else {
      return _buildPlaceholderButton(); // 显示初始按钮
    }
  }

  /// 构建占位按钮的辅助方法。
  ///
  /// 返回一个居中的功能按钮。
  Widget _buildPlaceholderButton() {
    return Center(
      key: const ValueKey('placeholder_button'), // Key
      child: FunctionalButton(
        icon: Icons.play_circle_outline_rounded, // 图标
        iconSize: 32,
        fontSize: 20,
        label: '观看视频', // 文本
        hasBorder: true,
        onPressed: _startLoadingVideo, // 点击时触发加载
      ),
    );
  }

  /// 构建错误状态的辅助方法。
  ///
  /// 返回一个包含错误信息和重试按钮的 Widget。
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error_state'), // Key
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 内边距
        child: Column(
          mainAxisSize: MainAxisSize.min, // 最小尺寸
          children: [
            Icon(Icons.error_outline_rounded, // 错误图标
                color: Colors.redAccent,
                size: 40),
            const SizedBox(height: 12), // 间距
            Text(
              _loadingError ?? '加载视频时发生未知错误', // 错误信息
              textAlign: TextAlign.center, // 文本居中
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error), // 文本样式
            ),
            const SizedBox(height: 16), // 间距
            TextButton(
              onPressed: _startLoadingVideo, // 点击时触发加载
              child: const Text('点击重试'), // 重试按钮
            ),
          ],
        ),
      ),
    );
  }
}
