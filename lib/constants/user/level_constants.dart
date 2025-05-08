import 'package:flutter/material.dart';

class LevelUtils {
  // 根据等级返回不同的颜色
  // 1-10级：每级颜色不同，尽量鲜艳且有区分度
  // 11-20级：一组颜色，代表进阶
  // 21-30级（或更高）：另一组颜色，代表高级/大师
  static Color getLevelColor(int level) {
    if (level <= 0) {
      return Colors.grey[700]!; // 0级或负数，给个深灰色
    }

    // 1-10级，追求每一级的独特性
    switch (level) {
      case 1:
        return Colors.lightGreen[300]!; // 稍有起色
      case 2:
        return Colors.lightGreen[500]!; // 稍有起色
      case 3:
        return Colors.lightGreen[700]!; // 稍有起色
      case 4:
        return Colors.green[600]!; // 稳步提升
      case 5:
        return Colors.teal[500]!; // 小有成就 - 青色系
      case 6:
        return Colors.blue[500]!; // 熟练 - 蓝色系
      case 7:
        return Colors.indigo[500]!; // 精通 - 靛蓝色
      case 8:
        return Colors.purple[500]!; // 专家 - 紫色系
      case 9:
        return Colors.pink[400]!;   // 接近大师 - 粉紫色，骚一点
      case 10:
        return Colors.amber[700]!;  // 里程碑 - 暗金/琥珀色
    }

    // 11-20级，进入新的阶段，可以用一些更沉稳或华丽的颜色组合
    if (level <= 15) { // 11-15级
      // 可以用一个色系的不同亮度，或者一组相近的高级颜色
      // 例如：从深蓝到浅蓝的过渡，或者金属质感
      // 这里我们用一组明亮的进阶色
      int R = 50 + (level - 11) * 20;  // 50 -> 130
      int G = 150 - (level - 11) * 15; // 150 -> 90
      int B = 200 + (level - 11) * 5;  // 200 -> 220
      // return Color.fromRGBO(R.clamp(0,255), G.clamp(0,255), B.clamp(0,255), 1);
      // 或者简单点：
      if (level <= 12) return Colors.cyan[600]!;       // 11, 12
      if (level <= 14) return Colors.lightBlue[700]!;  // 13, 14
      return Colors.blueAccent[700]!;                 // 15
    }
    if (level <= 20) { // 16-20级
      // 另一组成熟色
      if (level <= 17) return Colors.deepPurple[400]!; // 16, 17
      if (level <= 19) return Colors.purpleAccent[400]!; // 18, 19
      return Colors.red[400]!; // 20级，一个重要节点，给个红色系
    }

    // 21-30级 (或更高)，大师/传奇领域
    if (level <= 25) { // 21-25级
      // 更深的红色或橙色系
      if (level <= 22) return Colors.deepOrange[500]!; // 21, 22
      if (level <= 24) return Colors.orange[800]!;    // 23, 24
      return Colors.red[700]!;                       // 25
    }
    if (level <= 29) { // 26-29级
      // 可以用非常深的颜色或者带金属光泽的颜色
      return Colors.blueGrey[700]!; // 沉稳的蓝灰色
    }

    // 30级及以上 (封顶色)
    return Color(0xFFD4AF37); // 或者一个非常尊贵的颜色，比如深金 `Color(0xFFD4AF37)`
    // return Color(0xFFFFD700); // 纯金色 (Material Gold)
    // return Colors.redAccent[700]!; // 最终的炽热红
  }
}