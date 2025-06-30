// lib/models/game/game/game_form_data.dart

// 定义草稿数据模型
class GameFormDraft {
  final String title;
  final String summary;
  final String description;
  final String? musicUrl;
  final String? bvid;
  final String? coverImageUrl;
  final List<String> gameImageUrls;
  final List<Map<String, dynamic>> downloadLinks;
  final List<Map<String, dynamic>> externalLinks;
  final String? selectedCategory;
  final List<String> selectedTags;
  final DateTime lastSaved;
  final String draftKey;

  GameFormDraft({
    required this.title,
    required this.summary,
    required this.description,
    this.musicUrl,
    this.bvid,
    this.coverImageUrl,
    required this.gameImageUrls,
    required this.downloadLinks,
    required this.externalLinks,
    this.selectedCategory,
    required this.selectedTags,
    required this.lastSaved,
    required this.draftKey,
  });

  // 从 Map 构造
  factory GameFormDraft.fromJson(Map<String, dynamic> json) {
    // 安全解析 List<String>
    List<String> parseStringList(dynamic listData) {
      if (listData is List) return listData.whereType<String>().toList();
      return [];
    }

    // 安全解析 List<Map<String, dynamic>>
    List<Map<String, dynamic>> parseMapList(dynamic listData) {
      if (listData is List) {
        return listData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    }

    return GameFormDraft(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String? ?? '',
      musicUrl: json['musicUrl'] as String?,
      bvid: json['bvid'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      gameImageUrls: parseStringList(json['gameImageUrls']),
      downloadLinks: parseMapList(json['downloadLinks']),
      externalLinks: parseMapList(json['externalLinks']),
      selectedCategory: json['selectedCategory'] as String?,
      selectedTags: parseStringList(json['selectedTags']),
      lastSaved: DateTime.tryParse(json['lastSaved'] as String? ?? '') ??
          DateTime.now(),
      draftKey: json['draftKey'] as String? ?? 'unknown',
    );
  }

  // 转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'description': description,
      'musicUrl': musicUrl,
      'bvid': bvid,
      'coverImageUrl': coverImageUrl,
      'gameImageUrls': gameImageUrls,
      'downloadLinks': downloadLinks,
      'externalLinks': externalLinks,
      'selectedCategory': selectedCategory,
      'selectedTags': selectedTags,
      'lastSaved': lastSaved.toIso8601String(),
      'draftKey': draftKey,
    };
  }
}