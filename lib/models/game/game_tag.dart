// lib/models/tag/game_tag.dart
class GameTag {
  final String name;
  final int count;

  GameTag({
    required this.name,
    required this.count,
  });

  factory GameTag.fromJson(Map<String, dynamic> json) {
    return GameTag(
      name: json['tag'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': name,
      'count': count,
    };
  }
}