// lib/models/activity/check_in_meta_detail.dart

import 'package:suxingchahui/models/util_json.dart';

class CheckInActivityDetails {
  // --- JSON 字段键常量 ---
  static const String jsonKeyConsecutiveDays = 'consecutiveDays';
  static const String jsonKeyExpGained = 'expGained';
  static const String jsonKeyRecentCheckIns = 'recentCheckIns';

  final int consecutiveDays;
  final int expGained;
  final List<DateTime> recentCheckIns;

  const CheckInActivityDetails({
    required this.consecutiveDays,
    required this.expGained,
    required this.recentCheckIns,
  });

  factory CheckInActivityDetails.fromMetadata(
      Map<String, dynamic> metadataMap) {
    return CheckInActivityDetails(
      consecutiveDays:
          UtilJson.parseIntSafely(metadataMap[jsonKeyConsecutiveDays]),
      expGained: UtilJson.parseIntSafely(metadataMap[jsonKeyExpGained]),
      recentCheckIns:
          UtilJson.parseListDateTime(metadataMap[jsonKeyRecentCheckIns]),
    );
  }

  /// 创建一个空的 CheckInActivityDetails 对象。
  static CheckInActivityDetails empty() {
    return const CheckInActivityDetails(
      consecutiveDays: 0,
      expGained: 0,
      recentCheckIns: [],
    );
  }

  /// 复制并更新 CheckInActivityDetails 对象部分字段。
  CheckInActivityDetails copyWith({
    int? consecutiveDays,
    int? expGained,
    List<DateTime>? recentCheckIns,
  }) {
    return CheckInActivityDetails(
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      expGained: expGained ?? this.expGained,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
    );
  }
}
