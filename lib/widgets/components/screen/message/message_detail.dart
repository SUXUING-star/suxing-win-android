import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 用于时间格式化
import 'package:suxingchahui/models/message/message_type.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import '../../../../models/message/message.dart';

/// 消息详情展示 Widget (通常用于桌面端的右侧面板)
class MessageDetail extends StatelessWidget {
  final Message message; // 要显示详情的消息对象
  final VoidCallback onClose; // 关闭详情面板的回调
  final VoidCallback onDelete; // 删除此消息的回调
  final Function(Message) onViewDetail; // 点击 "查看关联" 时的回调

  const MessageDetail({
    super.key,
    required this.message,
    required this.onClose,
    required this.onDelete,
    required this.onViewDetail,
  });

  /// 格式化详情页显示的时间 (可以移到全局工具类)
  String _formatDetailTime(DateTime time) {
    return DateTimeFormatter.formatStandard(time); // 显示更详细的时间，包含秒
  }

  @override
  Widget build(BuildContext context) {
    // --- 修改开始: 使用 Scaffold 替代 Container + Column ---
    return Scaffold(
      backgroundColor: Colors.white, // 设置背景色
      appBar: AppBar(
        // 使用标准的 AppBar
        backgroundColor: Colors.white, // AppBar 背景色
        elevation: 0.5, // 可以加一点阴影或边框效果
        shadowColor: Colors.grey[300],
        title: Text(
          '消息详情',
          style: TextStyle(
              fontSize: 17,
              color: Colors.black87,
              fontWeight: FontWeight.w600), // 调整标题样式
        ),
        automaticallyImplyLeading: false, // 不显示默认的返回按钮
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[700]), // 关闭图标
            tooltip: '关闭详情', // 提示文字
            onPressed: onClose, // 调用关闭回调
          ),
        ],
      ),
      // Body 部分直接是可滚动区域
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16).copyWith(top: 20, bottom: 20), // 调整内边距
        child: Column(
          // 内层 Column 用于排列详情项
          crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
          children: [
            _buildTypeLabel(), // 显示类型标签
            SizedBox(height: 24), // 增加间距
            _buildContentSection(), // 显示内容详情
            SizedBox(height: 24),
            _buildTimeSection(context), // 显示时间信息
            SizedBox(height: 24),
            // 如果是分组消息且有引用内容，显示引用区域
            if (message.isGrouped &&
                message.references != null &&
                message.references!.isNotEmpty)
              _buildReferencesSection(),
            // SizedBox(height: 16), // 底部留白由 Scaffold padding 控制或 body padding 控制
          ],
        ),
      ),
      // 使用 bottomNavigationBar 放置操作按钮
      bottomNavigationBar: _buildActionButtons(context),
    );
    // --- 修改结束 ---
  }

  /// 构建消息类型标签
  Widget _buildTypeLabel() {
    final typeText = message.messageType.displayName;
    final labelColor = message.messageType.labelBackgroundColor;
    final textColor = message.messageType.labelTextColor;

    return Align(
      // 确保标签靠左
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: labelColor, // 使用模型提供的背景色
          borderRadius: BorderRadius.circular(16), // 圆角标签
        ),
        child: Text(
          typeText, // 使用模型提供的显示名称
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w500), // 使用模型提供的文字颜色
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
        Container(
          // 给内容区域添加背景和边距，使其更易读
          padding: EdgeInsets.all(12),
          width: double.infinity, // 撑满父容器宽度
          decoration: BoxDecoration(
              color: Colors.grey[100], // 浅灰色背景
              borderRadius: BorderRadius.circular(8) // 圆角
              ),
          // 使用 SelectableText 允许用户复制消息内容
          child: SelectableText(
            message.content, // 显示完整的消息内容
            style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87), // 调整字体大小、行高和颜色
          ),
        ),
      ],
    );
  }

  /// 构建时间信息区域
  Widget _buildTimeSection(BuildContext context) {
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
        SizedBox(height: 10),
        // --- 修改开始: Row 内部 Text 用 Expanded 包裹 ---
        Row(
          // 对应 L147
          children: [
            Icon(Icons.call_received, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Expanded(
              // <-- 包裹 Text
              child: Text(
                '接收: ${_formatDetailTime(message.displayTime)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                // softWrap: true, // Expanded 会处理换行，这个可以不加
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        if (message.isRead && message.readTime != null)
          Row(
            // 对应 L161
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.green[600]),
              SizedBox(width: 8),
              Expanded(
                // <-- 包裹 Text
                child: Text(
                  '阅读: ${_formatDetailTime(message.readTime!)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  // softWrap: true,
                ),
              ),
            ],
          ),
        // --- 修改结束 ---
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
        Container(
          // 给引用内容添加不同的背景和边框
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
    final bool canNavigate = message.navigationDetails != null;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        color: Colors.white,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12.0,
      ),
      // --- 修改开始: 使用 Wrap 替代 Row ---
      child: Wrap(
        // 对应 L237 的 Row
        alignment: WrapAlignment.end, // 子项整体靠右
        spacing: 12.0, // 水平间距
        runSpacing: 8.0, // 垂直间距 (如果换行)
        children: [
          // 删除按钮 (保持不变)
          OutlinedButton.icon(
            icon: Icon(Icons.delete_outline, size: 20),
            label: Text('删除'),
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red[300]!),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          // 查看关联按钮 (保持不变)
          if (canNavigate)
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_new, size: 20),
              label: Text('查看关联'),
              onPressed: () => onViewDetail(message),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 1,
              ),
            ),
        ],
      ),
      // --- 修改结束 ---
    );
  }
}
