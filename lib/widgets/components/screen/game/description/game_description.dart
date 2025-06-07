// lib/widgets/components/screen/game/description/game_description.dart

/// 该文件定义了 GameDescription 组件，一个用于显示游戏详细描述和下载链接的 StatelessWidget。
/// GameDescription 展示游戏的文字描述，并根据可用性显示下载链接。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/widgets/components/screen/game/download/game_download_links.dart'; // 导入游戏下载链接组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型

/// `GameDescription` 类：显示游戏详细描述的组件。
///
/// 该组件展示游戏的文字描述，并根据游戏数据是否包含下载链接来显示下载链接区域。
class GameDescription extends StatelessWidget {
  final Game game; // 游戏数据
  final User? currentUser; // 当前登录用户

  /// 构造函数。
  ///
  /// [game]：游戏数据。
  /// [currentUser]：当前用户。
  const GameDescription({
    super.key,
    required this.game,
    required this.currentUser,
  });

  /// 构建游戏描述组件。
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9), // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05), // 阴影颜色
            blurRadius: 10, // 模糊半径
            offset: const Offset(0, 2), // 偏移量
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
        children: [
          Row(
            children: [
              Container(
                width: 4, // 宽度
                height: 20, // 高度
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, // 背景色
                  borderRadius: BorderRadius.circular(2), // 圆角
                ),
              ),
              const SizedBox(width: 8), // 间距
              Text(
                '详细描述', // 标题文本
                style: TextStyle(
                  fontSize: 18, // 字号
                  fontWeight: FontWeight.bold, // 字重
                  color: Colors.grey[800], // 颜色
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // 间距
          Text(
            game.description, // 游戏描述文本
            style: TextStyle(
              fontSize: 15, // 字号
              height: 1.6, // 行高
              color: Colors.grey[700], // 颜色
            ),
          ),
          if (game.downloadLinks.isNotEmpty) ...[
            // 如果存在下载链接
            const SizedBox(height: 24), // 间距
            Row(
              children: [
                Container(
                  width: 4, // 宽度
                  height: 20, // 高度
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, // 背景色
                    borderRadius: BorderRadius.circular(2), // 圆角
                  ),
                ),
                const SizedBox(width: 8), // 间距
                Text(
                  '下载链接', // 标题文本
                  style: TextStyle(
                    fontSize: 18, // 字号
                    fontWeight: FontWeight.bold, // 字重
                    color: Colors.grey[800], // 颜色
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // 间距
            GameDownloadLinks(
              downloadLinks: game.downloadLinks, // 下载链接列表
              currentUser: currentUser, // 当前用户
            ),
          ],
        ],
      ),
    );
  }
}
