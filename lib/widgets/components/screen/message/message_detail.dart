import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 用于时间格式化
import 'package:suxingchahui/models/message/message_type.dart';
import '../../../../models/message/message.dart';

/// 消息详情展示 Widget (通常用于桌面端的右侧面板)
class MessageDetail extends StatelessWidget {
  final Message message;          // 要显示详情的消息对象
  final VoidCallback onClose;      // 关闭详情面板的回调
  final VoidCallback onDelete;     // 删除此消息的回调
  final Function(Message) onViewDetail; // 点击 "查看关联" 时的回调

  const MessageDetail({
    Key? key,
    required this.message,
    required this.onClose,
    required this.onDelete,
    required this.onViewDetail,
  }) : super(key: key);

  /// 格式化详情页显示的时间 (可以移到全局工具类)
  String _formatDetailTime(DateTime time) {
    return DateFormat('yyyy年MM月dd日 HH:mm:ss').format(time); // 显示更详细的时间，包含秒
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // 给详情页一个白色背景
      child: Column(
        children: [
          _buildHeader(context), // 构建头部 AppBar
          // 使用 Expanded 包裹 SingleChildScrollView 使内容区域可滚动
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16).copyWith(top: 8), // 调整内边距，顶部可以小一点
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
                children: [
                  _buildTypeLabel(), // 显示类型标签
                  SizedBox(height: 24), // 增加间距
                  _buildContentSection(), // 显示内容详情
                  SizedBox(height: 24),
                  _buildTimeSection(), // 显示时间信息
                  SizedBox(height: 24),
                  // 如果是分组消息且有引用内容，显示引用区域
                  if (message.isGrouped && message.references != null && message.references!.isNotEmpty)
                    _buildReferencesSection(),
                  SizedBox(height: 16), // 底部留白
                ],
              ),
            ),
          ),
          _buildActionButtons(context), // 构建底部的操作按钮
        ],
      ),
    );
  }

  /// 构建详情页的头部 AppBar
  Widget _buildHeader(BuildContext context) {
    return AppBar(
      title: Text('消息详情', style: TextStyle(fontSize: 18, color: Colors.black87)),
      backgroundColor: Colors.grey[50], // 使用浅灰色背景
      elevation: 0.5, // 添加轻微阴影增加层次感
      automaticallyImplyLeading: false, // 不自动添加返回按钮
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: Colors.grey[700]), // 关闭图标
          tooltip: '关闭详情', // 提示文字
          onPressed: onClose, // 调用关闭回调
        ),
      ],
    );
  }

  /// 构建消息类型标签
  Widget _buildTypeLabel() {
    // 从模型获取显示名称和颜色
    final typeText = message.messageType.displayName;
    final labelColor = message.messageType.labelBackgroundColor;
    final textColor = message.messageType.labelTextColor;

    return Align( // 确保标签靠左
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: labelColor, // 使用模型提供的背景色
          borderRadius: BorderRadius.circular(16), // 圆角标签
        ),
        child: Text(
          typeText, // 使用模型提供的显示名称
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500), // 使用模型提供的文字颜色
        ),
      ),
    );
  }

  /// 构建内容详情区域
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '内容详情',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 10),
        Container( // 给内容区域添加背景和边距，使其更易读
          padding: EdgeInsets.all(12),
          width: double.infinity, // 撑满父容器宽度
          decoration: BoxDecoration(
              color: Colors.grey[100], // 浅灰色背景
              borderRadius: BorderRadius.circular(8) // 圆角
          ),
          // 使用 SelectableText 允许用户复制消息内容
          child: SelectableText(
            message.content, // 显示完整的消息内容
            style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87), // 调整字体大小、行高和颜色
          ),
        ),
      ],
    );
  }

  /// 构建时间信息区域
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 10), // 增加一点间距
        // 显示接收时间
        Row(
          children: [
            Icon(Icons.call_received, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              // 使用 displayTime 和详细格式化
              '接收: ${_formatDetailTime(message.displayTime)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        SizedBox(height: 6), // 行间距
        // 如果消息已读且有已读时间，则显示
        if (message.isRead && message.readTime != null)
          Row(
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.green[600]), // 已读图标
              SizedBox(width: 8),
              Text(
                '阅读: ${_formatDetailTime(message.readTime!)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
      ],
    );
  }

  /// 构建引用内容区域 (仅当消息是分组消息且有引用时显示)
  Widget _buildReferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '相关内容摘要', // 标题
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container( // 给引用内容添加不同的背景和边框
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50], // 使用浅蓝灰色背景
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueGrey[100]!), // 边框颜色
          ),
          child: Text(
            // 显示 lastContent，如果为空则提供提示文本
            message.lastContent?.isNotEmpty ?? false
                ? message.lastContent!
                : "（无相关内容摘要）",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              // 无内容时使用斜体
              fontStyle: message.lastContent?.isNotEmpty ?? false
                  ? FontStyle.normal
                  : FontStyle.italic,
              height: 1.5, // 调整行高
            ),
          ),
        ),
      ],
    );
  }

  /// 构建底部的操作按钮区域
  Widget _buildActionButtons(BuildContext context) {
    // 从模型获取导航信息，判断是否可以导航
    final bool canNavigate = message.navigationDetails != null;

    return Container(
      // 添加上边框线，与内容区域分隔
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        color: Colors.white, // 背景色
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // 内边距
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 按钮默认靠右对齐
        children: [
          // 删除按钮
          OutlinedButton.icon(
            icon: Icon(Icons.delete_outline, size: 20),
            label: Text('删除'),
            onPressed: onDelete, // 调用删除回调
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red, // 红色文字和图标
              side: BorderSide(color: Colors.red[300]!), // 红色边框
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 按钮内边距
            ),
          ),
          SizedBox(width: 12), // 按钮间距
          // "查看关联" 按钮，仅当可导航时显示
          if (canNavigate)
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_new, size: 20),
              label: Text('查看关联'),
              onPressed: () => onViewDetail(message), // 调用查看详情回调
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, // 主题色背景
                foregroundColor: Colors.white, // 白色文字和图标
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 1, // 添加轻微阴影
              ),
            ),
        ],
      ),
    );
  }
}