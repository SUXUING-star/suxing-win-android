// lib/models/game/game/game_external_link.dart

import 'package:suxingchahui/models/utils/util_json.dart';

class GameExternalLink {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyUrl = 'url';

  final String title;
  final String url;

  const GameExternalLink({
    required this.title,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameExternalLink.fromJson(Map<String, dynamic> json) {
    return GameExternalLink(
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      url: UtilJson.parseStringSafely(json[jsonKeyUrl]),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      jsonKeyTitle: title,
      jsonKeyUrl: url,
    };
  }

  static List<GameExternalLink> fromListJson(dynamic json) {
    return UtilJson.parseObjectList<GameExternalLink>(
        json, (listJson) => GameExternalLink.fromJson(listJson));
  }

  // 创建一个空的 GameDownloadLink 对象
  static GameExternalLink empty() {
    return GameExternalLink(
      title: '',
      url: '',
    );
  }
}