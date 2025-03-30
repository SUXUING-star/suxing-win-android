
import 'package:flutter/material.dart';
class LevelColor{
  // 根据等级返回不同的颜色
  static getLevelColor(int level) {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 20) return Colors.purple;
    if (level < 50) return Colors.orange;
    return Colors.red;
  }
}
