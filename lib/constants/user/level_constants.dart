// // lib/constants/user/level_constants.dart
//
// /// LevelUtils定义了用户等级相关的常量和实用方法。
// /// 该类提供获取等级描述和等级对应颜色的功能。
// library;
//
// import 'package:flutter/material.dart'; // 导入 Flutter 颜色相关功能
//
// /// `LevelUtils` 类：提供用户等级相关的实用方法。
// ///
// /// 该类包含获取等级描述和根据等级返回对应颜色的功能。
// class LevelUtils {
//   /// 获取等级描述。
//   ///
//   /// [level]：用户等级。
//   /// 返回等级对应的描述字符串。
//   static String getLevelDescription(int level) {
//     switch (level) {
//       case 1:
//         return "茶会新人，刚刚踏入茶会的大门";
//       case 2:
//         return "茶会学徒，对茶会有了初步了解";
//       case 3:
//         return "茶会探索者，在茶会中游刃有余";
//       case 4:
//         return "茶会专家，对茶会了如指掌";
//       case 5:
//         return "茶会大师，茶会的荣誉成员";
//       default:
//         return "茶会新人，刚刚踏入茶会的大门"; // 默认返回新人描述
//     }
//   }
//
//   /// 根据等级返回对应的颜色。
//   ///
//   /// [level]：用户等级。
//   /// 返回等级对应的 [Color] 对象。
//   static Color getLevelColor(int level) {
//     if (level <= 0) {
//       return Colors.grey[700]!; // 0级或负数时返回深灰色
//     }
//
//     switch (level) {
//       case 1:
//         return Colors.lightGreen[300]!; // 等级初阶
//       case 2:
//         return Colors.lightGreen[500]!; // 等级初阶
//       case 3:
//         return Colors.lightGreen[700]!; // 等级初阶
//       case 4:
//         return Colors.green[600]!; // 等级中阶
//       case 5:
//         return Colors.teal[500]!; // 等级中阶
//       case 6:
//         return Colors.blue[500]!; // 等级中阶
//       case 7:
//         return Colors.indigo[500]!; // 等级高阶
//       case 8:
//         return Colors.purple[500]!; // 等级高阶
//       case 9:
//         return Colors.pink[400]!; // 等级高阶
//       case 10:
//         return Colors.amber[700]!; // 等级里程碑
//     }
//
//     if (level <= 15) {
//       // 等级 11-15 范围
//       if (level <= 12) return Colors.cyan[600]!; // 等级 11-12
//       if (level <= 14) return Colors.lightBlue[700]!; // 等级 13-14
//       return Colors.blueAccent[700]!; // 等级 15
//     }
//     if (level <= 20) {
//       // 等级 16-20 范围
//       if (level <= 17) return Colors.deepPurple[400]!; // 等级 16-17
//       if (level <= 19) return Colors.purpleAccent[400]!; // 等级 18-19
//       return Colors.red[400]!; // 等级 20
//     }
//
//     if (level <= 25) {
//       // 等级 21-25 范围
//       if (level <= 22) return Colors.deepOrange[500]!; // 等级 21-22
//       if (level <= 24) return Colors.orange[800]!; // 等级 23-24
//       return Colors.red[700]!; // 等级 25
//     }
//     if (level <= 29) {
//       // 等级 26-29 范围
//       return Colors.blueGrey[700]!; // 等级 26-29
//     }
//
//     return const Color(0xFFD4AF37); // 等级 30 及以上
//   }
// }
