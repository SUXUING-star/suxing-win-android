// lib/widgets/components/form/gameform/field/game_tags_form_field.dart

/// 该文件定义了 [GameTagsFormField] 组件，用于游戏标签的输入和管理。
/// [GameTagsFormField] 提供一个复合输入体验：
/// 1. 用户可以手动输入新标签。
/// 2. 用户可以从一个预定义的“可用标签”列表中点击选择标签。
/// 组件会展示已选标签，并支持删除。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// [GameTagsFormField] 类：游戏标签输入和管理的 StatefulWidget。
///
/// 该组件提供一个文本输入框用于添加新标签，并以 Chip 形式展示已添加的标签和可用的标签，
/// 支持添加和删除操作。
class GameTagsFormField extends StatefulWidget {
  final List<String> selectedTags; // 已选择的标签列表
  final Function(List<String>) onChanged; // 标签列表变化时的回调函数
  final List<String> availableTags; // 所有可用的标签数据源
  final String? loadTagsErrMsg; // 加载可用标签失败时的错误信息

  /// 构造函数。
  ///
  /// [selectedTags]：初始已选标签列表。
  /// [onChanged]：标签列表变化时的回调。
  /// [availableTags]：用于选择的可用标签列表。
  /// [loadTagsErrMsg]：加载标签失败的错误信息。
  const GameTagsFormField({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    required this.availableTags,
    this.loadTagsErrMsg,
  });

  @override
  _GameTagsFormFieldState createState() => _GameTagsFormFieldState();
}

class _GameTagsFormFieldState extends State<GameTagsFormField> {
  final TextEditingController _tagController =
      TextEditingController(); // 标签输入控制器
  late List<String> _tags; // 内部维护的已选标签列表
  final FocusNode _focusNode = FocusNode(); // 输入框焦点控制器

  @override
  void initState() {
    super.initState();
    // 使用 widget 的 selectedTags 初始化内部状态，确保父组件重建时能正确更新
    _tags = List.from(widget.selectedTags);
  }

  @override
  void didUpdateWidget(covariant GameTagsFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件传入的 selectedTags 发生变化时，同步更新内部状态
    if (widget.selectedTags != oldWidget.selectedTags) {
      setState(() {
        _tags = List.from(widget.selectedTags);
      });
    }
  }

  /// 添加标签。
  ///
  /// [tag]：要添加的标签文本。
  /// 如果标签不为空且未重复，则添加到列表中并通知父组件。
  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return; // 标签为空时不处理

    // 使用 setState 来确保 UI 更新
    setState(() {
      if (!_tags.contains(trimmedTag)) {
        // 标签不重复时添加
        _tags.add(trimmedTag); // 添加标签
        widget.onChanged(_tags); // 通知父组件标签列表已改变
      }
      _tagController.clear(); // 清空输入框
    });
    // 重新获取输入框焦点，方便连续输入
    _focusNode.requestFocus();
  }

  /// 删除标签。
  ///
  /// [tag]：要删除的标签文本。
  /// 从列表中删除标签并通知父组件。
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag); // 删除标签
      widget.onChanged(_tags); // 通知父组件标签列表已改变
    });
  }

  @override
  void dispose() {
    _tagController.dispose(); // 销毁输入控制器
    _focusNode.dispose(); // 销毁焦点控制器
    super.dispose(); // 调用父类 dispose
  }

  @override
  Widget build(BuildContext context) {
    // 过滤出那些可用但尚未被选择的标签
    final unselectedAvailableTags =
        widget.availableTags.where((tag) => !_tags.contains(tag)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '游戏标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // --- 标签输入框 ---
        TextField(
          controller: _tagController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '输入新标签，按回车或右侧按钮添加',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
            ),
          ),
          onSubmitted: _addTag,
        ),
        const SizedBox(height: 12),

        // --- 已选标签列表 ---
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => _buildSelectedTagChip(tag)).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          '提示: 尽量填会社名/画师/剧本家，最多5个，每个最长8个字。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // --- 可用标签区域 ---
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '可用标签 (点击添加)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),

        // 处理加载错误或列表为空的情况
        _buildAvailableTagsSection(unselectedAvailableTags),
      ],
    );
  }

  /// 构建可用标签区域的UI
  Widget _buildAvailableTagsSection(List<String> unselectedTags) {
    // 优先显示错误信息
    if (widget.loadTagsErrMsg != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '加载可用标签失败: ${widget.loadTagsErrMsg}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    // 如果没有错误，但列表为空
    if (unselectedTags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '没有更多可用标签了',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 正常显示可用标签
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          unselectedTags.map((tag) => _buildAvailableTagChip(tag)).toList(),
    );
  }

  /// 构建单个【已选】标签 Chip。
  Widget _buildSelectedTagChip(String tag) {
    return Chip(
      label: Text(tag),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _removeTag(tag),
      backgroundColor: Theme.of(context).primaryColor.withSafeOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.3)),
      ),
    );
  }

  /// 构建单个【可用】标签 Chip。
  Widget _buildAvailableTagChip(String tag) {
    return ActionChip(
      avatar: Icon(
        Icons.add_circle_outline,
        size: 16,
        color: Theme.of(context).primaryColor,
      ),
      label: Text(tag),
      onPressed: () => _addTag(tag), // 点击时调用添加逻辑
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
