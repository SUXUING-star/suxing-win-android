// lib/models/game/game_tag.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameTag {
  final String name;
  final int count;

  const GameTag({
    required this.name,
    required this.count,
  });

  factory GameTag.fromJson(Map<String, dynamic> json) {
    return GameTag(
      name: UtilJson.parseStringSafely(json['tag']),
      count: UtilJson.parseIntSafely(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': name,
      'count': count,
    };
  }
}
