// lib/models/game/game/game_download_link.dart

// 游戏下载链接模型
import 'package:suxingchahui/models/utils/util_json.dart';

class GameDownloadLink {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyUrl = 'url';
  static const String jsonKeyUserId = 'userId';

  final String id;
  final String title;
  final String description;
  final String url;
  final String userId;

  const GameDownloadLink({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameDownloadLink.fromJson(Map<String, dynamic> json) {
    return GameDownloadLink(
      id: UtilJson.parseId(json[jsonKeyId]),
      userId: UtilJson.parseId(json[jsonKeyUserId]),
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]),
      url: UtilJson.parseStringSafely(json[jsonKeyUrl]),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id,
      jsonKeyUserId: userId,
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
    };
  }

  static List<GameDownloadLink> fromListJson(dynamic json) {
    return UtilJson.parseObjectList<GameDownloadLink>(
        json, (listJson) => GameDownloadLink.fromJson(listJson));
  }


  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toRequestJson() {
    return {
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
    };
  }

  // 创建一个空的 GameDownloadLink 对象
  static GameDownloadLink empty() {
    return GameDownloadLink(
      id: '',
      userId: '',
      title: '',
      description: '',
      url: '',
    );
  }
}