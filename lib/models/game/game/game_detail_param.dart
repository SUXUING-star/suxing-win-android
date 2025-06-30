// lib/models/game/game/game_detail_param.dart

/// 该文件定义了 GameDetailParam 模型，用于在导航到游戏详情页时传递参数。
library;

import 'package:suxingchahui/models/common/query_param_data.dart';
import 'package:suxingchahui/models/game/game/game_details_response.dart';
import 'package:suxingchahui/models/utils/util_json.dart'; // --- 操，必须引进来 ---

/// `GameDetailParam` 类：游戏详情页导航参数模型。
///
/// 封装了进入游戏详情页所需的游戏ID和可选的筛选数据。
class GameDetailParam {
  static const jsonKeyGameId = 'gameId';
  static const jsonKeyGameWithStatus = 'gameWithStatus';
  static const jsonKeyFilterData = 'filterData';

  /// 目标游戏的唯一标识符。
  final String gameId;

  final GameDetailsResponse? gameDetailsResponse;

  /// 关联的筛选和分页数据（可选）。
  final QueryParamData? filterData;

  /// 构造函数。
  const GameDetailParam({
    required this.gameId,
    this.gameDetailsResponse,
    this.filterData,
  });

  // --- 操，看这里，我他妈给你加上了 ---

  /// 从 JSON 对象创建 `GameDetailParam` 实例。
  factory GameDetailParam.fromJson(Map<String, dynamic> json) {
    return GameDetailParam(
      gameId: UtilJson.parseId(json[jsonKeyGameId]),
      // 安全地处理可空的 filterData
      filterData: json[jsonKeyFilterData] != null
          ? QueryParamData.fromJson(json[jsonKeyGameWithStatus])
          : null,
      gameDetailsResponse:
          GameDetailsResponse.fromJson(json[jsonKeyGameWithStatus]),
    );
  }

  /// 将 `GameDetailParam` 实例转换为 JSON 对象。
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameId: gameId,
      jsonKeyGameWithStatus: gameDetailsResponse?.toJson(),
      jsonKeyFilterData: filterData?.toJson(),
    };

    return data;
  }

  // --- 上面是新加的，下面是你已经确认过的 ---

  /// 创建一个新的 `GameDetailParam` 实例，并根据提供的参数进行更新。
  GameDetailParam copyWith({
    String? gameId,
    QueryParamData? filterData,
    GameDetailsResponse? gameDetailsResponse,
  }) {
    return GameDetailParam(
      gameId: gameId ?? this.gameId,
      filterData: filterData ?? this.filterData,
      gameDetailsResponse:
          gameDetailsResponse ?? this.gameDetailsResponse,
    );
  }

  /// 重写 `toString` 方法，方便调试。
  @override
  String toString() {
    return 'GameDetailParam($jsonKeyGameId: $gameId, $jsonKeyFilterData: $filterData , $jsonKeyGameWithStatus: $gameDetailsResponse)';
  }
}
