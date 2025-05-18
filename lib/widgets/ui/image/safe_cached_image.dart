// lib/widgets/ui/image/safe_cached_image.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart'; // <--- 导入 Provider
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../utils/network/url_utils.dart';

class SafeCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Function(String url, dynamic error)? onError;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Color? backgroundColor;
  final Duration unloadDelay;
  final double visibleFractionThreshold;
  final Key? visibilityKey;
  // 不再需要 cacheManager 参数，将从 Provider 获取

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
    // cacheManager 参数移除
  });

  @override
  _SafeCachedImageState createState() => _SafeCachedImageState();
}

class _SafeCachedImageState extends State<SafeCachedImage> {
  bool _isVisible = false;
  bool _hasTriedLoading = false;
  Timer? _unloadTimer;
  late final Key _visibilityDetectorKey;
  late final BaseCacheManager _cacheManager;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
    _visibilityDetectorKey =
        widget.visibilityKey ?? ValueKey('${widget.imageUrl}_${UniqueKey()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里通过 Provider 获取 CacheManager
    // 使用 try-catch 确保即使上层没有提供 Provider (理论上不应该发生)，也能回退
    if (!_hasInitializedDependencies) {
      try {
        _cacheManager = Provider.of<BaseCacheManager>(context, listen: false);
      } catch (e) {
        // 如果没有从 Provider 获取到，回退到使用 DefaultCacheManager
        // 这样即使外部没有配置 CacheManagerProviderWidget，组件也能工作（使用默认缓存）
        _cacheManager = DefaultCacheManager();
      }
      _hasInitializedDependencies = true;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final bool nowVisible =
        info.visibleFraction >= widget.visibleFractionThreshold;

    if (!mounted) return; // 在处理任何状态或计时器之前检查

    if (nowVisible != _isVisible) {
      setState(() {
        _isVisible = nowVisible;
        if (_isVisible && !_hasTriedLoading) {
          _hasTriedLoading = true;
        }
      });

      _unloadTimer?.cancel(); // 不论可见性如何变化，先取消旧计时器

      if (!_isVisible) {
        _unloadTimer = Timer(widget.unloadDelay, () {
          if (mounted && !_isVisible) {
            // 再次确认状态
            _tryEvictImage();
          }
        });
      }
    }
  }

  void _tryEvictImage() {
    // 使用获取到的 CacheManager 实例来清除缓存
    _cacheManager.removeFile(widget.imageUrl).then((_) {
      if (mounted) {
        // 可选：清除成功后，如果希望下次可见时重新加载而不是从磁盘（如果还在），可以重置状态
        // setState(() {
        //   _hasTriedLoading = false; // 允许下次因可见性变化重新触发加载
        //   // _isVisible 此时应该是 false，所以会显示占位符
        // });
      }
      //debugPrint("SafeCachedImage: Evicted ${widget.imageUrl} from cache.");
    }).catchError((error) {
      debugPrint(
          "SafeCachedImage: Error evicting ${widget.imageUrl} from cache: $error");
    });
  }

  @override
  void dispose() {
    _unloadTimer?.cancel();
    super.dispose();
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      key: ValueKey('placeholder_${widget.imageUrl}'), // 给占位符也加个Key，辅助测试
      color: widget.backgroundColor ?? Colors.grey[200],
      width: widget.width,
      height: widget.height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor.withSafeOpacity(0.5),
          ),
        ),
      ),
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
          'assets/images/icons/main.png', // 确保这个路径正确
          fit: BoxFit.contain,
          // 可选：给错误图片也指定大小，如果需要的话
          width: widget.width != null ? widget.width! * 0.5 : 32,
          height: widget.height != null ? widget.height! * 0.5 : 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = UrlUtils.getSafeUrl(widget.imageUrl);

    int? finalCacheWidth;
    int? finalCacheHeight;
    final dpr = MediaQuery.of(context).devicePixelRatio; // 在 build 方法中获取 dpr

    if (widget.memCacheWidth != null || widget.memCacheHeight != null) {
      finalCacheWidth = widget.memCacheWidth;
      finalCacheHeight = widget.memCacheHeight;
    } else if (widget.width != null || widget.height != null) {
      finalCacheWidth =
          (widget.width != null) ? (widget.width! * dpr).round() : null;
      finalCacheHeight =
          (widget.height != null) ? (widget.height! * dpr).round() : null;
    }

    // 根据 _isVisible 和 _hasTriedLoading 的状态决定显示什么
    Widget imageContent;
    if (_isVisible || _hasTriedLoading) {
      imageContent = CachedNetworkImage(
        imageUrl: safeUrl,
        cacheManager: _cacheManager, // <--- 使用从 Provider 获取的 CacheManager
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: finalCacheWidth,
        memCacheHeight: finalCacheHeight,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) {
          widget.onError?.call(url, error); // 使用空值感知调用
          return _buildErrorWidget(context);
        },
        fadeInDuration: const Duration(milliseconds: 150), // 平滑淡入
        fadeOutDuration: const Duration(milliseconds: 150), // 平滑淡出 (如果图片变化)
      );
    } else {
      // 如果既不可见，也从未尝试加载过，显示占位符
      imageContent = _buildPlaceholder(context);
    }

    // 添加背景色
    if (widget.backgroundColor != null) {
      imageContent = Container(
        color: widget.backgroundColor,
        width: widget.width,
        height: widget.height,
        child: imageContent,
      );
    }

    // 添加圆角
    if (widget.borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    // 添加点击事件
    if (widget.onTap != null) {
      imageContent = GestureDetector(
        onTap: widget.onTap,
        child: imageContent,
      );
    }

    return VisibilityDetector(
      key: _visibilityDetectorKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: imageContent, // VisibilityDetector 包裹的是最终构建的 imageContent
    );
  }
}
