import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 用于时间格式化
import 'package:suxingchahui/models/message/message_type.dart';
import '../../../../models/message/message.dart';

/// 消息列表中的单个项目 Widget
class MessageListItem extends StatelessWidget {
  final Message message;      // 要显示的消息对象
  final VoidCallback onTap;    // 点击列表项时的回调
  final bool isSelected;   // 是否被选中 (用于高亮等)
  final bool isCompact;    // 是否为紧凑模式 (影响边距和行数)

  const MessageListItem({
    super.key,
    required this.message,
    required this.onTap,
    this.isSelected = false,
    this.isCompact = false,
  });

  /// 格式化显示时间 (可以移到全局工具类)
  String _formatDisplayTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24 && now.day == time.day) {
      return DateFormat('HH:mm').format(time); // 今天：显示时分
    } else if (difference.inHours < 48 && now.day == time.day + 1) {
      return '昨天 ${DateFormat('HH:mm').format(time)}'; // 昨天：显示昨天+时分
    } else if (now.year == time.year) {
      return DateFormat('MM-dd').format(time); // 今年：显示月日
    } else {
      return DateFormat('yyyy-MM-dd').format(time); // 往年：显示年月日
    }
  }

  @override
  Widget build(BuildContext context) {
    // 从模型获取预览内容，并指定截断长度
    final previewText = message.getPreviewContent(maxLength: isCompact ? 30 : 47);

    // 从模型获取显示名称和图标 (通过 message.messageType 访问扩展属性)
    final displayName = message.messageType.displayName;
    final iconData = message.messageType.iconData;

    return InkWell( // 使用 InkWell 提供点击水波纹效果
      onTap: onTap,
      splashColor: Theme.of(context).primaryColor.withOpacity(0.1), // 水波纹颜色
      highlightColor: Theme.of(context).primaryColor.withOpacity(0.05), // 点击高亮颜色
      child: Container(
        // 根据是否选中设置背景色
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.transparent,
        padding: EdgeInsets.symmetric(
            horizontal: 16.0, vertical: isCompact ? 8.0 : 12.0), // 根据模式调整垂直边距
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 图标和文本顶部对齐
          children: [
            // 左侧图标和未读标记
            Stack(
              clipBehavior: Clip.none, // 允许红点超出 CircleAvatar 边界
              children: [
                CircleAvatar(
                  radius: 22, // 图标背景圆大小
                  // 根据是否已读设置背景色
                  backgroundColor: message.isRead
                      ? Colors.grey[200] // 已读用灰色背景
                      : Theme.of(context).primaryColor.withOpacity(0.15), // 未读用主题色浅背景
                  child: Icon(
                    iconData, // 使用从模型获取的图标
                    // 根据是否已读设置图标颜色
                    color: message.isRead
                        ? Colors.grey[500] // 已读用灰色图标
                        : Theme.of(context).primaryColor, // 未读用主题色图标
                    size: 22, // 图标大小
                  ),
                ),
                // 如果未读，显示红点
                if (!message.isRead)
                  Positioned(
                    top: -2, // 调整红点位置
                    right: -2,
                    child: Container(
                      width: 10, // 红点大小
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.redAccent, // 红点颜色
                          shape: BoxShape.circle,
                          // 添加白色边框使其更突出
                          border: Border.all(color: Colors.white, width: 1.5)
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12), // 图标和文本之间的间距

            // 中间标题和预览文本
            Expanded( // 让文本区域占据剩余空间
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 文本左对齐
                children: [
                  Text(
                    displayName, // 使用从模型获取的显示名称
                    style: TextStyle(
                      fontSize: 15,
                      // 未读时加粗
                      fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                      // 未读时颜色更深
                      color: message.isRead ? Colors.black87 : Colors.black,
                    ),
                    maxLines: 1, // 标题只显示一行
                    overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                  ),
                  SizedBox(height: 4), // 标题和预览文本之间的间距
                  Text(
                    previewText, // 使用从模型获取的预览文本
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600], // 预览文本用灰色
                    ),
                    // 根据模式调整最大行数
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                  ),
                ],
              ),
            ),
            SizedBox(width: 8), // 文本和时间戳之间的间距

            // 右侧时间戳
            Padding(
              padding: const EdgeInsets.only(top: 2.0), // 微调时间戳的垂直位置，使其与标题对齐
              child: Text(
                _formatDisplayTime(message.displayTime), // 使用格式化后的显示时间
                style: TextStyle(fontSize: 12, color: Colors.grey[500]), // 时间戳用小号灰色字
              ),
            ),
          ],
        ),
      ),
    );
  }
}