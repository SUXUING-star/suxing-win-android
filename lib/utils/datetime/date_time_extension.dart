// lib/utils/datetime/date_time_extension.dart

import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';

extension DateTimeObjectExtension on DateTime {
  DateTime toBeijingTime() =>
      DateTimeFormatter.toBeijingTime(this);

  String formatStandard() =>
      DateTimeFormatter.formatStandard(this);

  String formatNormal() =>
      DateTimeFormatter.formatNormal(this);

  String formatShort() =>
      DateTimeFormatter.formatShort(this);

  String formatRelative() =>
      DateTimeFormatter.formatRelative(this);

  String formatCustom(String pattern) =>
      DateTimeFormatter.formatCustom(this, pattern);

  String formatTimeAgo() =>
      DateTimeFormatter.formatTimeAgo(this);
}


