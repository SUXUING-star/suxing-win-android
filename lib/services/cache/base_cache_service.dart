// lib/services/cache/base_cache_service.dart
abstract class BaseCacheService {
  Future<void> init();
  Future<void> clearCache();

  // 新增: 资源释放方法
  Future<void> dispose() async {
    // 默认实现: 仅打印日志
    print('${runtimeType.toString()} disposing...');
  }
}
