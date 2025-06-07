// lib/constants/game/game_constants.dart

/// 该文件定义了游戏相关的常量、状态主题和辅助工具类。
/// 它包含游戏收藏状态、游戏分类和游戏标签的显示属性和计算方法。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/models/game/game_collection.dart'; // 游戏收藏模型

/// `GameCollectionStatusTheme` 类：定义游戏收藏状态相关的显示属性结构。
///
/// 包含背景颜色、文本颜色、图标和标签文本。
class GameCollectionStatusTheme {
  final Color backgroundColor; // 背景颜色
  final Color textColor; // 文本颜色（用于图标和标签文本）
  final IconData icon; // 图标
  final String text; // 标签文本

  /// 构造函数。
  const GameCollectionStatusTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.text,
  });
}

/// `GameCollectionStatusUtils` 类：提供不同游戏收藏状态的显示主题。
///
/// 该类根据收藏状态字符串返回对应的显示主题。
class GameCollectionStatusUtils {
  /// “想玩”状态的显示主题。
  static const wantToPlayTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFE6F0FF),
    textColor: Color(0xFF3D8BFF),
    icon: Icons.star_border,
    text: '想玩',
  );

  /// “在玩”状态的显示主题。
  static const playingTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Color(0xFF4CAF50),
    icon: Icons.sports_esports,
    text: '在玩',
  );

  /// “玩过”状态的显示主题。
  static const playedTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFF3E5F5),
    textColor: Color(0xFF9C27B0),
    icon: Icons.check_circle_outline,
    text: '玩过',
  );

  /// “未知状态”的显示主题。
  static const unknownTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF616161),
    icon: Icons.bookmark_border,
    text: '状态未知',
  );

  /// “评分”的显示主题。
  static const ratingDisplayTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFFFF3E0),
    textColor: Color(0xFFF57C00),
    icon: Icons.star,
    text: '评分',
  );

  /// “总计”的显示主题。
  static const totalTheme = GameCollectionStatusTheme(
    backgroundColor: Color(0xFFFFF8E1),
    textColor: Color(0xFFFFAB00),
    icon: Icons.collections_bookmark_outlined,
    text: '总计',
  );

  /// 根据状态字符串返回对应的显示主题。
  ///
  /// [status]：状态字符串。
  /// 返回对应的 `GameCollectionStatusTheme`。
  static GameCollectionStatusTheme getTheme(String? status) {
    switch (status) {
      case GameCollectionStatus.wantToPlay:
        return wantToPlayTheme;
      case GameCollectionStatus.playing:
        return playingTheme;
      case GameCollectionStatus.played:
        return playedTheme;
      default:
        return unknownTheme;
    }
  }
}

/// `GameConstants` 类：定义游戏相关的常量。
class GameConstants {
  /// 默认游戏分类列表。
  static const List<String> defaultGameCategory = [
    categoryOriginal,
    categoryTranslated
  ];

  /// 默认筛选选项 Map。
  static const Map<String, String> defaultFilter = {
    'createTime': '最新发布',
    'viewCount': '最多浏览',
    'rating': '最高评分'
  };

  /// 汉化分类常量。
  static const String categoryTranslated = '汉化';

  /// 生肉分类常量。
  static const String categoryOriginal = '生肉';

  /// 获取游戏状态的显示属性。
  ///
  /// [approvalStatus]：审核状态字符串。
  /// 返回包含文本和颜色的 Map。
  static Map<String, dynamic> getGameStatusDisplay(String? approvalStatus) {
    switch (approvalStatus?.toLowerCase()) {
      case GameStatus.pending:
        return {
          'text': '审核中',
          'color': Colors.orange,
        };
      case GameStatus.approved:
        return {
          'text': '已通过',
          'color': Colors.green,
        };
      case GameStatus.rejected:
        return {
          'text': '已拒绝',
          'color': Colors.red,
        };
      default:
        return {
          'text': '未知',
          'color': Colors.grey,
        };
    }
  }
}

/// `GameCategoryUtils` 类：提供游戏分类相关的工具方法。
class GameCategoryUtils {
  /// 根据分类字符串获取对应的颜色。
  ///
  /// [category]：分类字符串。
  /// 返回对应的颜色。
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

/// `GameTagUtils` 类：提供游戏标签相关的工具方法。
class GameTagUtils {
  /// 默认标签颜色列表。
  static const List<Color> _defaultTagColors = [
    Color(0xFF64B5F6),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFF4DB6AC),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
    Color(0xFFF06292),
    Color(0xFFE57373),
    Color(0xFFFF8A65),
    Color(0xFF90A4AE),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF78909C),
  ];

  /// 根据标签字符串的哈希值获取一个稳定的颜色。
  ///
  /// [tag]：标签字符串。
  /// 返回对应的颜色。
  static Color getTagColor(String tag) {
    final colorIndex =
        tag.hashCode.abs() % _defaultTagColors.length; // 根据哈希值计算颜色索引
    return _defaultTagColors[colorIndex]; // 返回对应颜色
  }

  /// 根据背景颜色计算合适的文本颜色。
  ///
  /// [backgroundColor]：背景颜色。
  /// 返回白色。
  static Color getTextColorForBackground(Color backgroundColor) {
    return Colors.white; // 返回白色
  }
}
