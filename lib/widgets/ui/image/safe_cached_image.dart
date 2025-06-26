// lib/widgets/ui/image/safe_cached_image.dart

/// 该文件定义了 SafeCachedImage 组件，一个用于安全显示网络缓存图片的 StatefulWidget。
/// 该组件支持图片加载、缓存、错误处理、可见性检测，并可选择性地开启点击预览功能。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:cached_network_image/cached_network_image.dart'; // 缓存网络图片库
import 'package:suxingchahui/utils/network/url_utils.dart'; // URL 工具类
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/image/images_preview_screen.dart'; // 引入图片预览屏幕
import 'package:visibility_detector/visibility_detector.dart'; // 可见性检测库
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // 缓存管理库
import 'package:provider/provider.dart'; // Provider 状态管理库

/// `SafeCachedImage` 类：一个用于安全显示网络缓存图片的 StatefulWidget。
///
/// 该组件支持图片加载、缓存、错误处理、可见性检测，并可选择性地开启点击预览功能。
class SafeCachedImage extends StatefulWidget {
  final String imageUrl; // 图片的网络 URL
  final double? width; // 图片宽度
  final double? height; // 图片高度
  final BoxFit fit; // 图片填充模式
  final BorderRadius? borderRadius; // 图片圆角
  final VoidCallback? onTap; // 图片点击回调
  final Function(String url, dynamic error)? onError; // 图片加载错误回调
  final int? memCacheWidth; // 内存缓存宽度
  final int? memCacheHeight; // 内存缓存高度
  final Color? backgroundColor; // 占位符背景色
  final Duration unloadDelay; // 图片不可见时从缓存卸载的延迟
  final double visibleFractionThreshold; // 触发可见性改变的最小可见比例
  final Key? visibilityKey; // 可见性检测器的键
  final Alignment alignment; // 图片对齐方式
  final bool allowPreview; // 是否允许点击打开图片预览
  final bool allowDownloadInPreview; // 在预览中是否允许下载

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
    this.onError,
    this.memCacheWidth,
    this.memCacheHeight,
    this.backgroundColor,
    this.unloadDelay = const Duration(seconds: 15),
    this.visibleFractionThreshold = 0.01,
    this.visibilityKey,
    this.alignment = Alignment.center,
    this.allowPreview = false, // 默认不允许预览
    this.allowDownloadInPreview = true, // 预览时默认允许下载
  });

  @override
  _SafeCachedImageState createState() => _SafeCachedImageState();
}

/// `_SafeCachedImageState` 类：`SafeCachedImage` 的状态管理。
///
/// 管理图片加载状态、可见性检测和缓存清理逻辑。
class _SafeCachedImageState extends State<SafeCachedImage> {
  bool _isVisible = false; // 图片是否可见标记
  bool _hasTriedLoading = false; // 是否已尝试加载图片标记
  Timer? _unloadTimer; // 卸载计时器
  late final Key _visibilityDetectorKey; // 可见性检测器的唯一键
  late final BaseCacheManager _cacheManager; // 缓存管理器实例
  bool _hasInitializedDependencies = false; // 依赖初始化标记

  @override
  void initState() {
    super.initState();
    _visibilityDetectorKey =
        widget.visibilityKey ?? ValueKey('${widget.imageUrl}_${UniqueKey()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      try {
        _cacheManager = Provider.of<BaseCacheManager>(context, listen: false);
      } catch (e) {
        _cacheManager = DefaultCacheManager();
      }
      _hasInitializedDependencies = true;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final bool nowVisible =
        info.visibleFraction >= widget.visibleFractionThreshold;

    if (nowVisible != _isVisible) {
      setState(() {
        _isVisible = nowVisible;
        if (_isVisible && !_hasTriedLoading) {
          _hasTriedLoading = true;
        }
      });
      _unloadTimer?.cancel();
      if (!_isVisible) {
        _unloadTimer = Timer(widget.unloadDelay, () {
          if (mounted && !_isVisible) {
            _tryEvictImage();
          }
        });
      }
    }
  }

  void _tryEvictImage() {
    _cacheManager.removeFile(widget.imageUrl).catchError((_) {});
  }

  @override
  void dispose() {
    _unloadTimer?.cancel();
    super.dispose();
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      key: ValueKey('placeholder_${widget.imageUrl}'),
      color: widget.backgroundColor ?? Colors.grey[200],
      width: widget.width,
      height: widget.height,
      child: const LoadingWidget(),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      key: ValueKey('error_${widget.imageUrl}'),
      color: widget.backgroundColor ?? Colors.grey[200],
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Image.asset(
          'assets/images/icons/main.png',
          fit: BoxFit.contain,
          width: widget.width != null ? widget.width! * 0.5 : 32,
          height: widget.height != null ? widget.height! * 0.5 : 32,
        ),
      ),
    );
  }

  /// 处理点击事件，根据配置决定是执行自定义 onTap 还是打开预览
  void _handleTap() {
    // 如果允许预览，则优先处理预览逻辑
    if (widget.allowPreview) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ImagesPreviewScreen(
          images: [widget.imageUrl], // 预览单张图片，所以放在列表里
          initialIndex: 0,
          allowDownload: widget.allowDownloadInPreview, // 传递是否允许下载的配置
        ),
      ));
    }
    // 即使打开了预览，也执行外部传入的 onTap 回调（如果存在）
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = UrlUtils.getSafeUrl(widget.imageUrl);

    int? finalCacheWidth;
    int? finalCacheHeight;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    if (widget.memCacheWidth != null || widget.memCacheHeight != null) {
      finalCacheWidth = widget.memCacheWidth;
      finalCacheHeight = widget.memCacheHeight;
    } else if (widget.width != null || widget.height != null) {
      finalCacheWidth =
          (widget.width != null) ? (widget.width! * dpr).round() : null;
      finalCacheHeight =
          (widget.height != null) ? (widget.height! * dpr).round() : null;
    }

    Widget imageContent;
    if (_isVisible || _hasTriedLoading) {
      imageContent = CachedNetworkImage(
        imageUrl: safeUrl,
        cacheManager: _cacheManager,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        memCacheWidth: finalCacheWidth,
        memCacheHeight: finalCacheHeight,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) {
          widget.onError?.call(url, error);
          return _buildErrorWidget(context);
        },
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 150),
      );
    } else {
      imageContent = _buildPlaceholder(context);
    }

    if (widget.backgroundColor != null) {
      imageContent = Container(
        color: widget.backgroundColor,
        width: widget.width,
        height: widget.height,
        child: imageContent,
      );
    }

    // 始终应用 ClipRRect，如果 borderRadius 不为 null
    if (widget.borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    // NEW: 根据 allowPreview 或外部 onTap 来决定是否添加 GestureDetector
    if (widget.allowPreview || widget.onTap != null) {
      imageContent = GestureDetector(
        onTap: _handleTap,
        child: imageContent,
      );
    }

    return VisibilityDetector(
      key: _visibilityDetectorKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: imageContent,
    );
  }
}
