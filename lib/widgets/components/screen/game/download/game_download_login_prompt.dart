// lib/widgets/components/screen/game/download/game_download_login_prompt.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';

class GameDownloadLoginPrompt extends StatelessWidget {
  const GameDownloadLoginPrompt({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0), // 外边距
      elevation: 2, // 阴影
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 形状
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 内边距
        child: Column(
          children: [
            const Icon(
              Icons.lock_person_outlined, // 图标
              size: 50, // 大小
              color: Colors.deepPurpleAccent, // 颜色
            ),
            const SizedBox(height: 16), // 间距
            Text(
              '查看下载链接需登录', // 文本
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // 居中对齐
            ),
            const SizedBox(height: 8), // 间距
            Text(
              '登录后即可查看和管理游戏资源', // 文本
              textAlign: TextAlign.center, // 居中对齐
              style: Theme.of(context).textTheme.bodyMedium, // 样式
            ),
            const SizedBox(height: 24), // 间距
            FunctionalButton(
              label: '前往登录', // 按钮文本
              icon: Icons.login, // 图标
              onPressed: () =>
                  NavigationUtils.navigateToLogin(context), // 点击导航到登录页
            ),
          ],
        ),
      ),
    );
  }
}
