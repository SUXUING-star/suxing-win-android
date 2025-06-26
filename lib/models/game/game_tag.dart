// lib/models/game/game_tag.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameTag {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyName = 'tag'; // JSON 字段名为 'tag' 对应 Dart 属性 'name'
  static const String jsonKeyCount = 'count';

  final String name;
  final int count;

  const GameTag({
    required this.name,
    required this.count,
  });

  factory GameTag.fromJson(Map<String, dynamic> json) {
    return GameTag(
      name: UtilJson.parseStringSafely(json[jsonKeyName]), // 使用常量
      count: UtilJson.parseIntSafely(json[jsonKeyCount]), // 使用常量
    );
  }

  static List<GameTag> fromListJson(dynamic json) {
    if (json is! List) {
      return [];
    }
    return UtilJson.parseObjectList(
        json, (listJson) => GameTag.fromJson(listJson));
  }

  static List<String> fromObjectListToStringList(List<GameTag> list) {
    final newList = list.map((gt) {
      return gt.name;
    }).toList();
    return newList;
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyName: name, // 使用常量
      jsonKeyCount: count, // 使用常量
    };
  }
}
