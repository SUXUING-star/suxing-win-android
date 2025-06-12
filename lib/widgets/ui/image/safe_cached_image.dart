// lib/widgets/ui/image/safe_cached_image.dart

/// 该文件定义了 SafeCachedImage 组件，一个用于安全显示网络缓存图片的 StatefulWidget。
/// 该组件支持图片加载、缓存、错误处理和可见性检测。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:cached_network_image/cached_network_image.dart'; // 缓存网络图片库
import 'package:suxingchahui/utils/network/url_utils.dart'; // URL 工具类
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:visibility_detector/visibility_detector.dart'; // 可见性检测库
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // 缓存管理库
import 'package:provider/provider.dart'; // Provider 状态管理库

/// `SafeCachedImage` 类：一个用于安全显示网络缓存图片的 StatefulWidget。
///
/// 该组件支持图片加载、缓存、错误处理和可见性检测。
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
    _visibilityDetectorKey = widget.visibilityKey ??
        ValueKey('${widget.imageUrl}_${UniqueKey()}'); // 初始化可见性检测器的键
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// 初始化依赖。
    if (!_hasInitializedDependencies) {
      try {
        _cacheManager = Provider.of<BaseCacheManager>(context,
            listen: false); // 从 Provider 获取缓存管理器
      } catch (e) {
        _cacheManager = DefaultCacheManager(); // 获取失败时使用默认缓存管理器
      }
      _hasInitializedDependencies = true; // 标记依赖已初始化
    }
  }

  /// 处理可见性变化。
  ///
  /// [info]：可见性信息。
  void _onVisibilityChanged(VisibilityInfo info) {
    final bool nowVisible =
        info.visibleFraction >= widget.visibleFractionThreshold; // 判断当前可见性

    if (!mounted) return; // 组件未挂载时直接返回

    if (nowVisible != _isVisible) {
      setState(() {
        _isVisible = nowVisible; // 更新可见性状态
        if (_isVisible && !_hasTriedLoading) {
          _hasTriedLoading = true; // 更新加载尝试标记
        }
      });

      _unloadTimer?.cancel(); // 取消旧的卸载计时器

      if (!_isVisible) {
        _unloadTimer = Timer(widget.unloadDelay, () {
          if (mounted && !_isVisible) {
            _tryEvictImage(); // 不可见时启动卸载计时器
          }
        });
      }
    }
  }

  /// 尝试从缓存中卸载图片。
  void _tryEvictImage() {
    _cacheManager.removeFile(widget.imageUrl).then((_) {
      if (mounted) {}
    }).catchError((error) {}); // 从缓存中移除图片，捕获错误
  }

  @override
  void dispose() {
    _unloadTimer?.cancel(); // 取消卸载计时器
    super.dispose();
  }

  /// 构建图片占位符。
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      key: ValueKey('placeholder_${widget.imageUrl}'), // 占位符的 Key
      color: widget.backgroundColor ?? Colors.grey[200], // 背景色
      width: widget.width, // 宽度
      height: widget.height, // 高度
      child: const LoadingWidget(),
    );
  }

  /// 构建图片加载错误组件。
  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      key: ValueKey('error_${widget.imageUrl}'), // 错误组件的 Key
      color: widget.backgroundColor ?? Colors.grey[200], // 背景色
      width: widget.width, // 宽度
      height: widget.height, // 高度
      child: Center(
        child: Image.asset(
          'assets/images/icons/main.png', // 错误图片路径
          fit: BoxFit.contain, // 填充模式
          width: widget.width != null ? widget.width! * 0.5 : 32, // 错误图片宽度
          height: widget.height != null ? widget.height! * 0.5 : 32, // 错误图片高度
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = UrlUtils.getSafeUrl(widget.imageUrl); // 获取安全 URL

    int? finalCacheWidth; // 最终缓存宽度
    int? finalCacheHeight; // 最终缓存高度
    final dpr = MediaQuery.of(context).devicePixelRatio; // 获取设备像素比

    if (widget.memCacheWidth != null || widget.memCacheHeight != null) {
      finalCacheWidth = widget.memCacheWidth; // 使用指定的内存缓存宽度
      finalCacheHeight = widget.memCacheHeight; // 使用指定的内存缓存高度
    } else if (widget.width != null || widget.height != null) {
      finalCacheWidth = (widget.width != null)
          ? (widget.width! * dpr).round()
          : null; // 根据宽度计算缓存宽度
      finalCacheHeight = (widget.height != null)
          ? (widget.height! * dpr).round()
          : null; // 根据高度计算缓存高度
    }

    Widget imageContent; // 图片内容组件
    if (_isVisible || _hasTriedLoading) {
      imageContent = CachedNetworkImage(
        imageUrl: safeUrl, // 图片 URL
        cacheManager: _cacheManager, // 缓存管理器
        width: widget.width, // 宽度
        height: widget.height, // 高度
        fit: widget.fit, // 填充模式
        alignment: widget.alignment, // 对齐方式
        memCacheWidth: finalCacheWidth, // 内存缓存宽度
        memCacheHeight: finalCacheHeight, // 内存缓存高度
        placeholder: (context, url) => _buildPlaceholder(context), // 占位符
        errorWidget: (context, url, error) {
          widget.onError?.call(url, error); // 调用错误回调
          return _buildErrorWidget(context); // 错误组件
        },
        fadeInDuration: const Duration(milliseconds: 150), // 淡入时长
        fadeOutDuration: const Duration(milliseconds: 150), // 淡出时长
      );
    } else {
      imageContent = _buildPlaceholder(context); // 不可见或未尝试加载时显示占位符
    }

    if (widget.backgroundColor != null) {
      imageContent = Container(
        color: widget.backgroundColor, // 背景色
        width: widget.width, // 宽度
        height: widget.height, // 高度
        child: imageContent, // 包裹图片内容
      );
    }

    if (widget.borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: widget.borderRadius!, // 圆角
        child: imageContent, // 包裹图片内容
      );
    }

    if (widget.onTap != null) {
      imageContent = GestureDetector(
        onTap: widget.onTap, // 点击回调
        child: imageContent, // 包裹图片内容
      );
    }

    return VisibilityDetector(
      key: _visibilityDetectorKey, // 可见性检测器的 Key
      onVisibilityChanged: _onVisibilityChanged, // 可见性变化回调
      child: imageContent, // 可见性检测器包裹的图片内容
    );
  }
}
