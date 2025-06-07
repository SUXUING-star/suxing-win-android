// lib/widgets/providers/cache_manager_provider_widget.dart  (或者你喜欢的路径)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheManagerProviderWidget extends StatefulWidget {
  final Widget child;
  final String cacheKey;
  final Duration stalePeriod;
  final int maxNrOfCacheObjects;

  const CacheManagerProviderWidget({
    super.key,
    required this.child,
    this.cacheKey = 'globalAppCache', // 默认的缓存键
    this.stalePeriod = const Duration(days: 7),
    this.maxNrOfCacheObjects = 200, // 默认缓存对象数量
  });

  @override
  _CacheManagerProviderWidgetState createState() =>
      _CacheManagerProviderWidgetState();
}

class _CacheManagerProviderWidgetState
    extends State<CacheManagerProviderWidget> {
  late final BaseCacheManager _cacheManager;

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(
      Config(
        widget.cacheKey,
        stalePeriod: widget.stalePeriod,
        maxNrOfCacheObjects: widget.maxNrOfCacheObjects,
        // 如果需要，这里可以暴露更多 Config 参数给 widget
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<BaseCacheManager>.value(
      value: _cacheManager,
      child: widget.child,
    );
  }
}
