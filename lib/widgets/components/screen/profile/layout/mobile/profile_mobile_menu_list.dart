// lib/widgets/components/screen/profile/layout/mobile/profile_mobile_menu_list.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/constants/profile/profile_menu_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class ProfileMobileMenuList extends StatelessWidget {
  final List<ProfileMenuItem> menuItems;

  final User? currentUser;

  const ProfileMobileMenuList({
    super.key,
    required this.menuItems,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    // 用 Container 包裹，并添加 margin 和 decoration
    return Container(
      // 添加外边距，使其与头部和屏幕边缘分开
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      decoration: BoxDecoration(
          color: Colors.white.withSafeOpacity(0.7), // 半透明白色背景
          borderRadius: BorderRadius.circular(12.0), // 添加圆角
          boxShadow: [
            // 可选：添加一点阴影增加层次感
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ]),
      // 使用 ClipRRect 裁剪内部内容，使其符合圆角边界
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 非常重要，让 Column 只占用必要高度
          children: [
            // 动态生成菜单项和分割线
            ...menuItems.asMap().entries.map((entry) {
              int idx = entry.key;
              ProfileMenuItem item = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(item.iconData,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withSafeOpacity(0.8)), // 图标颜色稍微柔和点
                    title: AppText(
                      item.textLabel,
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Colors.grey.shade400), // 箭头颜色淡一点
                    onTap: item.onTap(context, currentUser) ??
                        () => NavigationUtils.pushNamed(context, item.route),
                    // 设置 List Tile 的内边距，可以稍微调整
                    // contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    dense: true, // 让列表项更紧凑一点
                  ),
                  // 在非最后一个菜单项后添加分割线
                  if (idx < menuItems.length - 1)
                    Divider(
                      height: 1, // 分割线高度
                      thickness: 0.5, // 分割线厚度
                      indent: 56, // 左边缩进，大约是图标宽度+边距
                      endIndent: 16, // 右边缩进
                      color: Colors.grey.shade300, // 分割线颜色淡一点
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
