/// lib/models/game/game_detail_param.dart

/// 该文件定义了 GameDetailParam 模型，用于在导航到游戏详情页时传递参数。
library;

import 'package:suxingchahui/models/common/query_param_data.dart';
import 'package:suxingchahui/models/util_json.dart'; // --- 操，必须引进来 ---

/// `GameDetailParam` 类：游戏详情页导航参数模型。
///
/// 封装了进入游戏详情页所需的游戏ID和可选的筛选数据。
class GameDetailParam {
  /// 目标游戏的唯一标识符。
  final String gameId;

  /// 关联的筛选和分页数据（可选）。
  final QueryParamData? filterData;

  /// 构造函数。
  const GameDetailParam({
    required this.gameId,
    this.filterData,
  });

  // --- 操，看这里，我他妈给你加上了 ---

  /// 从 JSON 对象创建 `GameDetailParam` 实例。
  factory GameDetailParam.fromJson(Map<String, dynamic> json) {
    return GameDetailParam(
      gameId: UtilJson.parseId(json['gameId']),
      // 安全地处理可空的 filterData
      filterData: json['filterData'] != null
          ? QueryParamData.fromJson(json['filterData'])
          : null,
    );
  }

  /// 将 `GameDetailParam` 实例转换为 JSON 对象。
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gameId': gameId,
    };
    // 只有在 filterData 不为 null 时才将其添加到 JSON 中
    if (filterData != null) {
      data['filterData'] = filterData!.toJson();
    }
    return data;
  }

  // --- 上面是新加的，下面是你已经确认过的 ---

  /// 创建一个新的 `GameDetailParam` 实例，并根据提供的参数进行更新。
  GameDetailParam copyWith({
    String? gameId,
    QueryParamData? filterData,
  }) {
    return GameDetailParam(
      gameId: gameId ?? this.gameId,
      filterData: filterData ?? this.filterData,
    );
  }

  /// 重写 `toString` 方法，方便调试。
  @override
  String toString() {
    return 'GameDetailParam(gameId: $gameId, filterData: $filterData)';
  }

  /// 重写 `==` 操作符，用于比较实例。
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GameDetailParam &&
        other.gameId == gameId &&
        other.filterData == filterData;
  }

  /// 重写 `hashCode`，与 `==` 保持一致。
  @override
  int get hashCode => gameId.hashCode ^ filterData.hashCode;
}
