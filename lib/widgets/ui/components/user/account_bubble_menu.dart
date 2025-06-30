// lib/widgets/ui/components/user/account_bubble_menu.dart

/// 该文件定义了 AccountBubbleMenu 组件，一个用于选择已保存账号的弹出菜单。
/// AccountBubbleMenu 显示一个可供选择的账号列表，并提供账号切换功能。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/user/user/account.dart'; // 导入账号模型
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart'; // 导入安全用户头像组件

/// `AccountBubbleMenu` 类：用于选择已保存账号的弹出菜单组件。
///
/// 该组件显示一个账号列表，用户可点击选择账号进行操作。
class AccountBubbleMenu extends StatelessWidget {
  final Function(SavedAccount) onAccountSelected; // 账号选中回调
  final List<SavedAccount> accounts; // 保存的账号列表
  final BuildContext anchorContext; // 锚点上下文
  final Offset? anchorOffset; // 菜单相对于锚点的偏移量
  final Color? backgroundColor; // 菜单的背景颜色

  /// 构造函数。
  ///
  /// [accounts]：账号列表。
  /// [onAccountSelected]：账号选中回调。
  /// [anchorContext]：锚点上下文。
  /// [anchorOffset]：锚点偏移量。
  /// [backgroundColor]：背景颜色。
  const AccountBubbleMenu({
    super.key,
    required this.accounts,
    required this.onAccountSelected,
    required this.anchorContext,
    this.anchorOffset,
    this.backgroundColor,
  });

  /// 构建账号气泡菜单。
  ///
  /// 该方法根据屏幕尺寸和提供的账号列表构建菜单 UI。
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 获取屏幕宽度

    final menuWidth = screenWidth < 400 ? screenWidth * 0.8 : 320.0; // 计算菜单宽度

    const double avatarRadiusInMenu = 16.0; // 菜单中头像半径
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio; // 设备像素比
    final int calculatedMemCacheSize =
        (avatarRadiusInMenu * 2 * devicePixelRatio).round(); // 计算内存缓存尺寸

    return Material(
      color: Colors.transparent, // Material 背景透明
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => NavigationUtils.of(context).pop(), // 点击外部关闭菜单
              child: Container(
                color: Colors.transparent, // 容器透明
              ),
            ),
          ),
          Positioned(
            left: anchorOffset?.dx ?? 0, // 菜单左侧位置
            top: (anchorOffset?.dy ?? 0) + 10, // 菜单顶部位置，向下偏移
            child: Container(
              width: menuWidth, // 菜单宽度
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6, // 菜单最大高度
              ),
              decoration: BoxDecoration(
                color: backgroundColor ??
                    Colors.white.withSafeOpacity(0.95), // 背景颜色
                borderRadius: BorderRadius.circular(12), // 圆角
                boxShadow: [
                  // 阴影
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.1), // 阴影颜色
                    blurRadius: 10, // 模糊半径
                    spreadRadius: 1, // 扩散半径
                    offset: const Offset(0, 2), // 偏移量
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // 裁剪圆角
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 垂直方向适应内容
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 水平方向拉伸
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16), // 内边距
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withSafeOpacity(0.05), // 背景颜色
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withSafeOpacity(0.3), // 分隔线颜色
                            width: 0.5, // 分隔线宽度
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline, // 图标
                            size: 18, // 大小
                            color: Theme.of(context).primaryColor, // 颜色
                          ),
                          const SizedBox(width: 8), // 间距
                          Text(
                            '选择账号', // 文本
                            style: TextStyle(
                              fontSize: 14, // 字号
                              fontWeight: FontWeight.w500, // 字重
                              color: Theme.of(context).primaryColor, // 颜色
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (accounts.isEmpty) // 账号列表为空时显示提示
                      Padding(
                        padding: const EdgeInsets.all(16), // 内边距
                        child: Text(
                          '没有保存的账号', // 提示文本
                          textAlign: TextAlign.center, // 文本居中
                          style: TextStyle(
                            color: Colors.grey[600], // 颜色
                            fontSize: 14, // 字号
                          ),
                        ),
                      )
                    else // 账号列表不为空时显示列表
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.4, // 最大高度
                        ),
                        child: ListView.builder(
                          shrinkWrap: true, // 根据内容收缩
                          padding: EdgeInsets.zero, // 内边距
                          itemCount: accounts.length, // 项数量
                          itemBuilder: (context, index) {
                            final account = accounts[index]; // 当前账号

                            final bool isLastItem =
                                index == accounts.length - 1; // 是否最后一个项

                            return InkWell(
                              onTap: () {
                                NavigationUtils.of(context).pop(); // 关闭菜单
                                onAccountSelected(account); // 选中账号回调
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: !isLastItem // 非最后一项显示底部边框
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withSafeOpacity(0.3), // 分隔线颜色
                                            width: 0.5, // 分隔线宽度
                                          ),
                                        )
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12), // 内边距
                                child: Row(
                                  children: [
                                    SafeUserAvatar(
                                      userId: account.userId ?? '', // 用户ID
                                      avatarUrl: account.avatarUrl, // 头像URL
                                      username: account.username ??
                                          account.email, // 用户名或邮箱
                                      radius: avatarRadiusInMenu, // 半径
                                      memCacheWidth:
                                          calculatedMemCacheSize, // 内存缓存宽度
                                      memCacheHeight:
                                          calculatedMemCacheSize, // 内存缓存高度
                                    ),
                                    const SizedBox(width: 12), // 间距

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start, // 水平左对齐
                                        mainAxisSize:
                                            MainAxisSize.min, // 垂直方向适应内容
                                        children: [
                                          Text(
                                            account.username ??
                                                account.email, // 用户名或邮箱
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500, // 字重
                                              fontSize: 14, // 字号
                                            ),
                                            maxLines: 1, // 最大行数
                                            overflow: TextOverflow
                                                .ellipsis, // 溢出显示省略号
                                          ),
                                          const SizedBox(height: 2), // 间距
                                          Text(
                                            account.email, // 邮箱
                                            style: TextStyle(
                                              color: Colors.grey[600], // 颜色
                                              fontSize: 12, // 字号
                                            ),
                                            maxLines: 1, // 最大行数
                                            overflow: TextOverflow
                                                .ellipsis, // 溢出显示省略号
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (account.enrichLevel.level >=
                                        1) // 显示等级标签
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2), // 内边距
                                        decoration: BoxDecoration(
                                          color: account.enrichLevel
                                              .backgroundColor, // 背景颜色
                                          borderRadius:
                                              BorderRadius.circular(10), // 圆角
                                        ),
                                        child: Text(
                                          'Lv.${account.enrichLevel.level}', // 文本
                                          style: const TextStyle(
                                            fontSize: 11, // 字号
                                            color: Colors.white, // 颜色
                                            fontWeight: FontWeight.bold, // 字重
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12), // 内边距
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(), // 点击关闭菜单
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withSafeOpacity(0.1), // 背景颜色
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // 圆角
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8), // 内边距
                        ),
                        child: Text(
                          '使用其他账号', // 文本
                          style: TextStyle(
                            color: Theme.of(context).primaryColor, // 颜色
                            fontSize: 14, // 字号
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
