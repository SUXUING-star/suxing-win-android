// lib/models/user/user/user_extension.dart

import 'package:suxingchahui/models/user/user/enrich_level.dart';
import 'package:suxingchahui/models/user/user/user.dart';

extension UserExtension on User {
// --- 完整的 hasCheckedInToday getter ---
  bool get hasCheckedInToday {
    if (lastCheckInDate == null) return false;

    final now = DateTime.now();
    // 使用 toUtc() 来比较日期，避免时区问题
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final checkInDateUtc = DateTime.utc(
      lastCheckInDate!.year,
      lastCheckInDate!.month,
      lastCheckInDate!.day,
    );

    return checkInDateUtc.isAtSameMomentAs(todayUtc);
  }

  EnrichLevel get enrichLevel => EnrichLevel.fromLevel(level);
}
