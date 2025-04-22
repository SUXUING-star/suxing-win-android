// lib/widgets/components/screen/game/video/game_video_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 引入你的 LoadingWidget

class GameVideoSection extends StatefulWidget {
  final String? bvid; // 改为 nullable，因为不是所有游戏都有

  const GameVideoSection({
    super.key,
    required this.bvid, // 接收 bvid
  });

  @override
  State<GameVideoSection> createState() => _GameVideoSectionState();
}

class _GameVideoSectionState extends State<GameVideoSection> {
  bool _shouldLoadVideo = false; // 状态：用户是否点击了加载按钮
  bool _isLoadingVideo = false; // 状态：WebView 是否正在加载页面
  String? _loadingError; // 状态：记录加载错误信息


  // 根据 bvid 构建嵌入式播放器 URL
  String? get _embedUrl {
    if (widget.bvid == null || widget.bvid!.isEmpty) {
      return null;
    }
    // 只用 bvid 通常就够了，B站 player 会自己处理
    return 'https://player.bilibili.com/player.html?bvid=${widget.bvid}'; // 加个 autoplay=0 避免自动播放（虽然 WebView 可能不遵守）
  }

  @override
  void didUpdateWidget(covariant GameVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 bvid 变了，重置状态，回到按钮界面
    if (widget.bvid != oldWidget.bvid) {
      if (mounted) {
        // 确保组件还在树上
        setState(() {
          _shouldLoadVideo = false;
          _isLoadingVideo = false;
          _loadingError = null;
        });
      }
    }
  }

  void _startLoadingVideo() {
    if (_embedUrl != null && mounted) {
      // 检查 URL 有效且组件挂载
      setState(() {
        _shouldLoadVideo = true;
        _isLoadingVideo = true; // 开始加载，显示 Loading
        _loadingError = null; // 清除之前的错误
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmbedUrl = _embedUrl; // 先获取当前 URL

    // 如果 bvid 无效，直接不显示任何东西
    if (currentEmbedUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 标题 (保持不变)
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '相关视频',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),

        // 2. 视频区域 (核心变化)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            // 给个背景色，避免加载时是透明的
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLowest, // 用一个柔和的背景色
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias, // 确保子 Widget 不会超出圆角
            child: AnimatedSwitcher(
              // 使用 AnimatedSwitcher 实现平滑过渡
              duration: const Duration(milliseconds: 300),
              child: _buildContent(currentEmbedUrl), // 根据状态构建内容
            ),
          ),
        ),
      ],
    );
  }

  // 根据状态构建内容的辅助方法
  Widget _buildContent(String currentEmbedUrl) {
    // Key 很重要，确保 AnimatedSwitcher 能识别内容变化
    if (_loadingError != null) {
      // --- C. 显示错误状态 ---
      return _buildErrorState();
    } else if (_shouldLoadVideo) {
      // --- B. 显示 WebView 和 Loading ---
      // 使用 Stack 将 Loading 覆盖在 WebView 上
      return Stack(
        key: ValueKey('video_stack_${widget.bvid}'), // 给 Stack 一个 Key
        alignment: Alignment.center, // 让 Loading 居中
        children: [
          // WebView 层 (总是在 Stack 底部)
          EmbeddedWebView(
            // 当 URL 变化时，WebView 需要重建，Key 包含 URL
            key: ValueKey('webview_$currentEmbedUrl'),
            initialUrl: currentEmbedUrl,
            onPageStarted: (url) {
              if (mounted && !_isLoadingVideo) {
                // 避免重复设置
                setState(() {
                  _isLoadingVideo = true; // 页面开始加载时也确保是 loading 状态
                  _loadingError = null; // 清除可能残留的错误
                });
              }
            },
            onPageFinished: (url) {
              // 页面加载完成，取消 Loading 状态
              if (mounted) {
                setState(() {
                  _isLoadingVideo = false;
                });
              }
            },
            onWebResourceError: (error) {
              // 加载出错，取消 Loading 并记录错误
              print("WebView Error in GameVideoSection: $error");
              if (mounted) {
                setState(() {
                  _isLoadingVideo = false;
                  _loadingError =
                      '视频加载失败，请稍后重试。\n错误: ${error.toString().substring(0, 100)}...'; // 显示错误信息
                });
              }
            },
          ),

          // Loading 层 (仅在 _isLoadingVideo 为 true 时显示)
          // 使用 AnimatedOpacity 实现 Loading 的淡入淡出
          AnimatedOpacity(
            opacity: _isLoadingVideo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _isLoadingVideo
                ? LoadingWidget.inline(
                    // 使用你的内联 Loading
                    message: '加载中...',
                    size: 32.0, // 可以调整大小
                  )
                : const SizedBox.shrink(), // 不加载时占位
          ),
        ],
      );
    } else {
      // --- A. 显示初始按钮 ---
      return _buildPlaceholderButton();
    }
  }

  // 构建占位按钮的辅助方法
  Widget _buildPlaceholderButton() {
    return Center(
      // 让按钮在 AspectRatio 区域内居中
      key: const ValueKey('placeholder_button'), // 给按钮一个 Key
      child: FunctionalButton(
        icon: Icons.play_circle_outline_rounded,
        iconSize: 32,
        fontSize: 20,
        label: '观看视频',
        hasBorder: true,

        onPressed: _startLoadingVideo, // 点击时触发加载
      ),
    );
  }

  // 构建错误状态的辅助方法
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error_state'), // 给错误状态一个 Key
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _loadingError ?? '加载视频时发生未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _startLoadingVideo, // 提供重试按钮
              child: const Text('点击重试'),
            ),
          ],
        ),
      ),
    );
  }
}
