// lib/constants/game/game_constants.dart
import 'package:flutter/material.dart';

import '../../models/game/game_collection.dart';

// 定义一个简单的类或 Map 来存储每个 Tab 的配置信息
class GameCollectionTabConfig {
  final String status;
  final String Function(int count) titleBuilder; // 用于动态构建 Tab 标题
  final IconData icon;

  const GameCollectionTabConfig({
    required this.status,
    required this.titleBuilder,
    required this.icon,
  });
}

class GameConstants {
  static const List<String> defaultGameCategory = [
    categoryOriginal,
    categoryTranslated
  ];

  static const Map<String, String> defaultFilter = {
    'createTime': '最新发布',
    'viewCount': '最多浏览',
    'rating': '最高评分'
  };

  static const String categoryTranslated = '汉化';
  static const String categoryOriginal = '生肉';

  // 新增：定义 Tab 的配置列表
  static final List<GameCollectionTabConfig> collectionTabs = [
    GameCollectionTabConfig(
      status: GameCollectionStatus.wantToPlay,
      titleBuilder: (count) => '想玩${count > 0 ? ' $count' : ''}',
      icon: Icons.star_border,
    ),
    GameCollectionTabConfig(
      status: GameCollectionStatus.playing,
      titleBuilder: (count) => '在玩${count > 0 ? ' $count' : ''}',
      icon: Icons.videogame_asset,
    ),
    GameCollectionTabConfig(
      status: GameCollectionStatus.played,
      titleBuilder: (count) => '玩过${count > 0 ? ' $count' : ''}',
      icon: Icons.check_circle,
    ),
  ];

  // 根据收藏类型获取对应颜色 (保持不变)
  static Color getGameCollectionStatusColor(collectionType) {
    switch (collectionType) {
      case GameCollectionStatus.wantToPlay:
        return Colors.blue;
      case GameCollectionStatus.playing:
        return Colors.green;
      case GameCollectionStatus.played:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class GameCategoryUtils {
  static Color getCategoryColor(String category) {
    switch (category) {
      case (GameConstants.categoryTranslated):
        return Colors.blue.shade300;
      case (GameConstants.categoryOriginal):
        return Colors.green.shade300;
      default:
        return Colors.grey.shade200;
    }
  }
}

class GameTagUtils {
  // --- 定义标签颜色列表 (私有静态常量) ---
  static const List<Color> _defaultTagColors = [
    // --- 常用色系的 300 系列 ---
    Color(0xFF64B5F6), // blue[300]
    Color(0xFF4FC3F7), // lightBlue[300]
    Color(0xFF81C784), // green[300]
    Color(0xFF4DB6AC), // teal[300]
    Color(0xFF7986CB), // indigo[300]
    Color(0xFFBA68C8), // purple[300]
    Color(0xFFF06292), // pink[300]
    Color(0xFFE57373), // red[300]
    Color(0xFFFF8A65), // deepOrange[300]
    Color(0xFF90A4AE), // blueGrey[300]

    // --- 加入一些 400 系列增加层次感和对比度 ---
    Color(0xFF42A5F5), // blue[400]
    Color(0xFF66BB6A), // green[400]
    Color(0xFF26C6DA), // cyan[400]  (青色，对比度好)
    Color(0xFFAB47BC), // purple[400]
    Color(0xFFFFA726), // orange[400] (比 300 饱和度高点)
    Color(0xFF7E57C2), // deepPurple[400] (深紫，对比度好)
    Color(0xFF5C6BC0), // indigo[400]
    Color(0xFF78909C), // blueGrey[400]
  ];

  /// 根据标签字符串的哈希值获取一个稳定的颜色 (静态方法)
  static Color getTagColor(String tag) {
    final colorIndex = tag.hashCode.abs() % _defaultTagColors.length;
    return _defaultTagColors[colorIndex];
  }



  /// 根据背景颜色计算合适的文本颜色 (静态方法)
  static Color getTextColorForBackground(Color backgroundColor) {
    return Colors.white;
  }
}
