// lib/models/activity/activity_type_count.dart

import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/activity/enrich_activity_type.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

/// 单个活动类型的统计数据。
@immutable
class ActivityTypeCount implements CommonColorThemeExtension{
  // --- JSON 字段键常量 ---
  static const String jsonKeyType = 'type';
  static const String jsonKeyCount = 'count';

  /// 活动类型，保持为 [String] 以兼容现有工具类。
  final String type;

  /// 该类型的活动数量。
  final int count;

  const ActivityTypeCount({
    required this.type,
    required this.count,
  });

  /// 复制并更新 ActivityTypeCount 对象部分字段。
  ActivityTypeCount copyWith({
    String? type,
    int? count,
  }) {
    return ActivityTypeCount(
      type: type ?? this.type,
      count: count ?? this.count,
    );
  }

  factory ActivityTypeCount.fromJson(MapEntry<String, dynamic> e) {
    return ActivityTypeCount(
      type: e.key, // key is the activity type string
      count: UtilJson.parseIntSafely(e.value),
    );
  }

  @override
  String getTextLabel() => enrichType.textLabel;

  @override
  Color getTextColor() => enrichType.textColor;

  @override
  IconData getIconData() => enrichType.iconData;

  @override
  Color getBackgroundColor() => enrichType.backgroundColor;

}

extension ActivityTypeCountExtension on ActivityTypeCount {
  EnrichActivityType get enrichType => EnrichActivityType.fromType(type);
}
