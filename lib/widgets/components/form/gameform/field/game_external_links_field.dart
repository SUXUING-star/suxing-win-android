// lib/widgets/components/form/gameform/field/game_external_links_field.dart

/// 该文件定义了 GameExternalLinksField 组件，用于管理游戏的外部链接。
/// GameExternalLinksField 提供添加、编辑和删除外部链接的功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件所需
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 基础输入对话框所需
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart'; // 文本输入字段组件所需
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 提示条组件所需

/// `GameExternalLinksField` 类：管理游戏外部链接的 StatelessWidget。
///
/// 该组件提供一个界面，用于添加、编辑和删除游戏的外部链接。
class GameExternalLinksField extends StatelessWidget {
  final List<GameExternalLink> externalLinks; // 外部链接列表
  final ValueChanged<List<GameExternalLink>> onChanged; // 链接列表变化时的回调
  final InputStateService inputStateService; // 输入状态服务

  /// 构造函数。
  ///
  /// [externalLinks]：外部链接列表。
  /// [onChanged]：链接列表变化时的回调。
  /// [inputStateService]：输入状态服务。
  const GameExternalLinksField({
    super.key,
    required this.externalLinks,
    required this.onChanged,
    required this.inputStateService,
  });

  /// 添加外部链接。
  ///
  /// [context]：Build 上下文。
  /// 弹出对话框，获取链接标题和 URL，然后将其添加到列表中。
  void _addExternalLink(BuildContext context) {
    _showLinkDialog(
      context: context,
      dialogTitle: '添加关联链接', // 对话框标题
      confirmButtonText: '添加', // 确认按钮文本
      onConfirmAction: (title, url) {
        // 确认操作回调
        final newLinks = List<GameExternalLink>.from(externalLinks); // 创建新列表
        newLinks.add(GameExternalLink(
          title: title,
          url: url,
        )); // 添加新链接
        onChanged(newLinks); // 通知父组件列表已更新
      },
    );
  }

  /// 编辑外部链接。
  ///
  /// [context]：Build 上下文。
  /// [index]：要编辑链接的索引。
  /// 弹出对话框，预填当前链接信息，然后更新链接。
  void _editExternalLink(BuildContext context, int index) {
    final link = externalLinks[index]; // 获取要编辑的链接
    _showLinkDialog(
      context: context,
      dialogTitle: '编辑关联链接', // 对话框标题
      initialTitle: link.title, // 初始标题
      initialUrl: link.url, // 初始 URL
      confirmButtonText: '保存', // 确认按钮文本
      onConfirmAction: (title, url) {
        // 确认操作回调
        final newLinks = List<GameExternalLink>.from(externalLinks); // 创建新列表
        newLinks[index] = GameExternalLink(
          title: title,
          url: url,
        ); // 更新链接
        onChanged(newLinks); // 通知父组件列表已更新
      },
    );
  }

  /// 显示链接输入对话框。
  ///
  /// [context]：Build 上下文。
  /// [dialogTitle]：对话框标题。
  /// [initialTitle]：初始标题。
  /// [initialUrl]：初始 URL。
  /// [confirmButtonText]：确认按钮文本。
  /// [onConfirmAction]：确认操作回调。
  /// 包含标题和 URL 输入框，并进行 URL 格式校验。
  void _showLinkDialog({
    required BuildContext context,
    required String dialogTitle,
    String initialTitle = '',
    String initialUrl = '',
    required String confirmButtonText,
    required void Function(String title, String url) onConfirmAction,
  }) {
    final titleController =
        TextEditingController(text: initialTitle); // 标题输入控制器
    final urlController = TextEditingController(text: initialUrl); // URL 输入控制器

    BaseInputDialog.show<void>(
      context: context,
      title: dialogTitle, // 对话框标题
      contentBuilder: (BuildContext dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
          children: [
            TextInputField(
              inputStateService: inputStateService,
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '链接标题', // 标签文本
                hintText: '例如：官方网站, Steam页面', // 提示文本
              ),
            ),
            const SizedBox(height: 12), // 垂直间距
            TextInputField(
              inputStateService: inputStateService,
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '链接 URL', // 标签文本
                hintText: 'https://', // 提示文本
              ),
              keyboardType: TextInputType.url, // 键盘类型为 URL
            ),
          ],
        );
      },
      confirmButtonText: confirmButtonText, // 确认按钮文本
      onConfirm: () async {
        final title = titleController.text.trim(); // 获取标题并去除首尾空格
        final url = urlController.text.trim(); // 获取 URL 并去除首尾空格

        if (title.isNotEmpty && url.isNotEmpty) {
          // 标题和 URL 不能为空
          final uri = Uri.tryParse(url); // 尝试解析 URL
          if (uri == null ||
              (!uri.isScheme("HTTP") && !uri.isScheme("HTTPS")) ||
              uri.host.isEmpty) {
            if (context.mounted) {
              // 检查组件是否挂载
              AppSnackBar.showWarning('请输入有效的 HTTP 或 HTTPS 链接！'); // 显示警告
            }
            throw Exception('URL 格式无效'); // 抛出异常
          }
          onConfirmAction(title, url); // 触发确认操作回调
          return;
        } else {
          if (context.mounted) {
            // 检查组件是否挂载
            AppSnackBar.showWarning('链接标题和 URL 不能为空！'); // 显示警告
          }
          throw Exception('输入校验失败'); // 抛出异常
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // 垂直内边距
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '其他关联链接',
                style: Theme.of(context).textTheme.titleMedium, // 标题样式
              ),
              FunctionalButton(
                onPressed: () => _addExternalLink(context), // 点击添加链接
                icon: Icons.add_link, // 图标
                label: '添加链接', // 按钮文本
              ),
            ],
          ),
        ),
        if (externalLinks.isEmpty) // 链接列表为空时显示提示
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0), // 垂直内边距
            child: Center(
              child: Text(
                '暂无其他关联链接',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else // 链接列表不为空时显示列表
          ListView.builder(
            shrinkWrap: true, // 根据内容收缩高度
            physics: const NeverScrollableScrollPhysics(), // 禁用滚动
            itemCount: externalLinks.length, // 链接数量
            itemBuilder: (context, index) {
              final link = externalLinks[index]; // 当前链接
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0), // 垂直外边距
                elevation: 1.5, // 阴影
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 圆角边框
                ),
                child: ListTile(
                  leading: const Icon(Icons.link), // 链接图标
                  title: Text(link.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w500)), // 链接标题
                  subtitle: SelectableText(
                    link.url, // 链接 URL
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, // 编辑图标
                            color: Colors.blueGrey[600],
                            size: 20),
                        tooltip: '编辑', // 工具提示
                        onPressed: () =>
                            _editExternalLink(context, index), // 点击编辑链接
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever_outlined, // 删除图标
                            color: Colors.red[400],
                            size: 20),
                        tooltip: '删除', // 工具提示
                        onPressed: () {
                          final newLinks = List<GameExternalLink>.from(
                              externalLinks); // 创建新列表
                          newLinks.removeAt(index); // 移除链接
                          onChanged(newLinks); // 通知父组件列表已更新
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
