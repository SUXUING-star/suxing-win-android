import 'package:suxingchahui/models/game/game_collection.dart';

/// 用于在收藏状态改变时，封装新状态和计数变化的回调结果。
class CollectionChangeResult {
  /// 更新后的收藏状态。如果移除了收藏，则为 null。
  final GameCollectionItem? newStatus;

  /// 各个收藏状态计数的增量变化。
  /// Map 包含键 'want', 'playing', 'played', 'total'。
  /// 值表示相对于操作前的变化量 (例如 +1, -1, 0)。
  final Map<String, int> countDeltas;

  CollectionChangeResult({
    required this.newStatus,
    required this.countDeltas,
  });

  @override
  String toString() {
    return 'CollectionChangeResult(newStatus: ${newStatus?.status}, deltas: $countDeltas)';
  }
}