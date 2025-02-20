// lib/screens/admin/widgets/tool_management.dart
import 'package:flutter/material.dart';
import '../../../services/link_tool_service.dart';
import '../../../models/linkstools/tool.dart';
import '../../../widgets/form/toolform/tool_form_dialog.dart';

class ToolManagement extends StatefulWidget {
  const ToolManagement({Key? key}) : super(key: key);

  @override
  State<ToolManagement> createState() => _ToolManagementState();
}

class _ToolManagementState extends State<ToolManagement> {
  final LinkToolService _linkToolService = LinkToolService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Tool>>(
        stream: _linkToolService.getTools(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tools = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _showAddToolDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('添加工具'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.build),
                        title: Text(tool.name),
                        subtitle: Text(tool.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditToolDialog(tool),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(tool),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddToolDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ToolFormDialog(),
    );

    if (result != null) {
      try {
        await _linkToolService.addTool(Tool.fromJson(result));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工具添加成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：$e')),
        );
      }
    }
  }

  // 在 tool_management.dart 中修改
  Future<void> _showEditToolDialog(Tool tool) async {
    final result = await showDialog<Tool>( // 明确指定返回类型
      context: context,
      builder: (context) => ToolFormDialog(tool: tool),
    );

    if (result != null) {
      try {
        await _linkToolService.updateTool(result); // 直接使用 Tool 对象
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工具更新成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Tool tool) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除工具"${tool.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _linkToolService.deleteTool(tool.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工具删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }
}