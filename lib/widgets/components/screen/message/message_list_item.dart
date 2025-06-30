// lib/widgets/components/screen/message/message_list_item.dart

/// 该文件定义了 MessageListItem 组件，用于显示消息列表中的单个消息项。
/// MessageListItem 展示消息的类型、内容预览、时间，并根据已读状态和选中状态显示不同样式。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/utils/datetime/date_time_extension.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/models/message/message.dart'; // 消息模型

/// `MessageListItem` 类：消息列表中的单个项目组件。
///
/// 该组件用于在消息列表中展示一条消息，根据消息的已读状态、选中状态和紧凑模式调整显示样式。
class MessageListItem extends StatelessWidget {
  final Message message; // 要显示的消息对象
  final VoidCallback onTap; // 点击列表项时的回调函数
  final bool isSelected; // 标识列表项是否被选中
  final bool isCompact; // 标识是否为紧凑显示模式

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [message]：要显示的消息对象。
  /// [onTap]：点击列表项时的回调。
  /// [isSelected]：是否被选中，默认为 false。
  /// [isCompact]：是否为紧凑模式，默认为 false。
  const MessageListItem({
    super.key,
    required this.message,
    required this.onTap,
    this.isSelected = false,
    this.isCompact = false,
  });

  /// 构建消息列表项 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `InkWell` 组件，包含消息的布局和样式。
  @override
  Widget build(BuildContext context) {
    final previewText =
        message.getPreviewContent(maxLength: isCompact ? 30 : 47); // 获取消息预览文本

    final textLabel = message.textLabel; // 获取消息类型显示名称
    final iconData = message.iconData; // 获取消息类型图标

    return InkWell(
      // 可点击区域
      onTap: onTap, // 点击回调
      splashColor: Theme.of(context).primaryColor.withSafeOpacity(0.1), // 水波纹颜色
      highlightColor:
          Theme.of(context).primaryColor.withSafeOpacity(0.05), // 点击高亮颜色
      child: Container(
        // 消息项容器
        color: isSelected // 根据选中状态设置背景色
            ? Theme.of(context).primaryColor.withSafeOpacity(0.08)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
            horizontal: 16.0, vertical: isCompact ? 8.0 : 12.0), // 根据紧凑模式调整内边距
        child: Row(
          // 水平布局
          crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
          children: [
            Stack(
              // 堆叠布局，用于图标和未读标记
              clipBehavior: Clip.none, // 允许子组件超出边界
              children: [
                CircleAvatar(
                  // 圆形头像/图标背景
                  radius: 22, // 大小
                  backgroundColor: message.isRead // 根据已读状态设置背景色
                      ? Colors.grey[200]
                      : Theme.of(context).primaryColor.withSafeOpacity(0.15),
                  child: Icon(
                    // 图标
                    iconData, // 使用消息类型图标
                    color: message.isRead // 根据已读状态设置图标颜色
                        ? Colors.grey[500]
                        : Theme.of(context).primaryColor,
                    size: 22, // 图标大小
                  ),
                ),
                if (!message.isRead) // 未读时显示红点
                  Positioned(
                    // 定位红点
                    top: -2,
                    right: -2,
                    child: Container(
                      // 红点容器
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          // 红点装饰
                          color: Colors.redAccent, // 红色
                          shape: BoxShape.circle, // 圆形
                          border: Border.all(
                              color: Colors.white, width: 1.5)), // 白色边框
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12), // 间隔

            Expanded(
              // 占据剩余空间
              child: Column(
                // 垂直布局
                crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                children: [
                  Text(
                    // 消息标题
                    textLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: message.isRead
                          ? FontWeight.normal
                          : FontWeight.w600, // 未读时加粗
                      color: message.isRead
                          ? Colors.black87
                          : Colors.black, // 未读时颜色更深
                    ),
                    maxLines: 1, // 只显示一行
                    overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                  ),
                  const SizedBox(height: 4), // 间隔
                  Text(
                    // 消息预览文本
                    previewText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600], // 灰色
                    ),
                    maxLines: isCompact ? 1 : 2, // 根据紧凑模式调整最大行数
                    overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // 间隔

            Padding(
              // 时间戳
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                message.displayTime.formatTimeAgo(), // 格式化时间
                style: TextStyle(fontSize: 12, color: Colors.grey[500]), // 字体样式
              ),
            ),
          ],
        ),
      ),
    );
  }
}
