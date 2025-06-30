// // lib/constants/game/game_constants.dart
//
// /// 该文件定义了游戏相关的常量、状态主题和辅助工具类。
// /// 它包含游戏收藏状态、游戏分类和游戏标签的显示属性和计算方法。
// library;
//
// import 'package:flutter/material.dart'; // Flutter UI 框架
// import 'package:suxingchahui/models/game/collection_item.dart'; // 游戏收藏模型
//
// /// `GameCollectionStatusTheme` 类：定义游戏收藏状态相关的显示属性结构。
// ///
// /// 包含背景颜色、文本颜色、图标和标签文本。
// class GameCollectionStatusTheme {
//   final Color backgroundColor; // 背景颜色
//   final Color textColor; // 文本颜色（用于图标和标签文本）
//   final IconData icon; // 图标
//   final String text; // 标签文本
//
//   /// 构造函数。
//   const GameCollectionStatusTheme({
//     required this.backgroundColor,
//     required this.textColor,
//     required this.icon,
//     required this.text,
//   });
// }
//
// /// `GameCollectionStatusUtils` 类：提供不同游戏收藏状态的显示主题。
// ///
// /// 该类根据收藏状态字符串返回对应的显示主题。
// class GameCollectionStatusUtils {
//   /// “想玩”状态的显示主题。
//   static const wantToPlayTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFE6F0FF),
//     textColor: Color(0xFF3D8BFF),
//     icon: Icons.star_border,
//     text: '想玩',
//   );
//
//   /// “在玩”状态的显示主题。
//   static const playingTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFE8F5E9),
//     textColor: Color(0xFF4CAF50),
//     icon: Icons.sports_esports,
//     text: '在玩',
//   );
//
//   /// “玩过”状态的显示主题。
//   static const playedTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFF3E5F5),
//     textColor: Color(0xFF9C27B0),
//     icon: Icons.check_circle_outline,
//     text: '玩过',
//   );
//
//   /// “未知状态”的显示主题。
//   static const unknownTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFF5F5F5),
//     textColor: Color(0xFF616161),
//     icon: Icons.bookmark_border,
//     text: '状态未知',
//   );
//
//   /// “评分”的显示主题。
//   static const ratingDisplayTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFFFF3E0),
//     textColor: Color(0xFFF57C00),
//     icon: Icons.star,
//     text: '评分',
//   );
//
//   /// “总计”的显示主题。
//   static const totalTheme = GameCollectionStatusTheme(
//     backgroundColor: Color(0xFFFFF8E1),
//     textColor: Color(0xFFFFAB00),
//     icon: Icons.collections_bookmark_outlined,
//     text: '总计',
//   );
//
//   /// 根据状态字符串返回对应的显示主题。
//   ///
//   /// [status]：状态字符串。
//   /// 返回对应的 `GameCollectionStatusTheme`。
//   static GameCollectionStatusTheme getTheme(String? status) {
//     switch (status) {
//       case GameCollectionItem.statusWantToPlay:
//         return wantToPlayTheme;
//       case GameCollectionItem.statusPlaying:
//         return playingTheme;
//       case GameCollectionItem.statusPlayed:
//         return playedTheme;
//       default:
//         return unknownTheme;
//     }
//   }
// }
