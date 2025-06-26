// lib/models/game/game_navigation_info.dart
import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameNavigationInfo {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyPreviousId = 'previousId';
  static const String jsonKeyPreviousTitle = 'previousTitle';
  static const String jsonKeyNextId = 'nextId';
  static const String jsonKeyNextTitle = 'nextTitle';

  final String? previousId;
  final String? previousTitle;
  final String? nextId;
  final String? nextTitle;

  const GameNavigationInfo({
    this.previousId,
    this.previousTitle,
    this.nextId,
    this.nextTitle,
  });

  factory GameNavigationInfo.fromJson(Map<String, dynamic> json) {
    return GameNavigationInfo(
      // ID 字段可能是 ObjectId，使用 parseNullableId 处理
      previousId: UtilJson.parseNullableId(json[jsonKeyPreviousId]), // 使用常量
      // 标题字段，如果为 null 或空字符串，则解析为 null
      previousTitle: UtilJson.parseNullableStringSafely(
          json[jsonKeyPreviousTitle]), // 使用常量
      nextId: UtilJson.parseNullableId(json[jsonKeyNextId]), // 使用常量
      nextTitle:
          UtilJson.parseNullableStringSafely(json[jsonKeyNextTitle]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (previousId != null) map[jsonKeyPreviousId] = previousId; // 使用常量
    if (previousTitle != null) {
      map[jsonKeyPreviousTitle] = previousTitle; // 使用常量
    }
    if (nextId != null) map[jsonKeyNextId] = nextId; // 使用常量
    if (nextTitle != null) map[jsonKeyNextTitle] = nextTitle; // 使用常量
    return map;
  }

  GameNavigationInfo copyWith({
    ValueGetter<String?>? previousId,
    ValueGetter<String?>? previousTitle,
    ValueGetter<String?>? nextId,
    ValueGetter<String?>? nextTitle,
  }) {
    return GameNavigationInfo(
      previousId: previousId != null ? previousId() : this.previousId,
      previousTitle:
          previousTitle != null ? previousTitle() : this.previousTitle,
      nextId: nextId != null ? nextId() : this.nextId,
      nextTitle: nextTitle != null ? nextTitle() : this.nextTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameNavigationInfo &&
          runtimeType == other.runtimeType &&
          previousId == other.previousId &&
          previousTitle == other.previousTitle &&
          nextId == other.nextId &&
          nextTitle == other.nextTitle;

  @override
  int get hashCode =>
      previousId.hashCode ^
      previousTitle.hashCode ^
      nextId.hashCode ^
      nextTitle.hashCode;

  @override
  String toString() {
    return 'GameNavigationInfo{previousId: $previousId, previousTitle: $previousTitle, nextId: $nextId, nextTitle: $nextTitle}';
  }

  bool get isEmpty =>
      previousId == null &&
      previousTitle == null &&
      nextId == null &&
      nextTitle == null;
  bool get isNotEmpty => !isEmpty;
}
