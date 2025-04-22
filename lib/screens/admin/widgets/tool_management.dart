// lib/screens/admin/widgets/tool_management.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../services/main/linktool/link_tool_service.dart';
import '../../../models/linkstools/tool.dart';
import '../../../widgets/components/form/toolform/tool_form_dialog.dart';

class ToolManagement extends StatefulWidget {
  const ToolManagement({super.key});

  @override
  State<ToolManagement> createState() => _ToolManagementState();
}

class _ToolManagementState extends State<ToolManagement> {
  final LinkToolService _linkToolService = LinkToolService();
  // 添加一个刷新触发器
  int _refreshTrigger = 0;
  // 添加加载状态
  bool _isLoading = false;

  // 刷新数据
  void _refreshData() {
    setState(() {
      _refreshTrigger++; // 增加计数器以触发StreamBuilder重建
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Tool>>(
        // 使用刷新触发器作为key，确保数据改变时重建
        key: ValueKey("tools_$_refreshTrigger"),
        stream: _linkToolService.getTools(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tools = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showAddToolDialog,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? '处理中...' : '添加工具'),
                  ),
                ),
                Expanded(
                  child: tools.isEmpty
                      ? Center(child: Text('暂无工具数据'))
                      : ListView.builder(
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
                                      onPressed: _isLoading
                                          ? null
                                          : () => _showEditToolDialog(tool),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: _isLoading
                                          ? null
                                          : () => _showDeleteConfirmation(tool),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddToolDialog() async {
    // 防止重复操作
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await showDialog(
        context: context,
        builder: (context) => const ToolFormDialog(),
      );

      if (result != null) {
        try {
          // 转换为Tool对象
          final tool = Tool.fromJson(result);
          await _linkToolService.addTool(tool);

          // 刷新UI
          _refreshData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('工具添加成功')),
            );
          }
        } catch (e) {
          print('添加工具错误: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('添加失败：$e')),
            );
          }
        }
      }
    } finally {
      // 确保状态重置
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditToolDialog(Tool tool) async {
    // 防止重复操作
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await showDialog(
        context: context,
        builder: (context) => ToolFormDialog(tool: tool),
      );

      if (result != null) {
        try {
          // 修改：使用fromJson转换Map为Tool对象
          final updatedTool = Tool.fromJson(result);
          await _linkToolService.updateTool(updatedTool);

          // 刷新UI
          _refreshData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('工具更新成功')),
            );
          }
        } catch (e) {
          print('更新工具错误: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('更新失败：$e')),
            );
          }
        }
      }
    } finally {
      // 确保状态重置
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation(Tool tool) async {
    // 防止重复操作
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除工具"${tool.name}"吗？'),
          actions: [
            FunctionalTextButton(
                onPressed: () => NavigationUtils.pop(context, false),
                label: '取消'),
            FunctionalButton(
                onPressed: () => NavigationUtils.pop(context, true),
                label: '删除'),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await _linkToolService.deleteTool(tool.id);

          // 刷新UI
          _refreshData();

          if (mounted) {
            AppSnackBar.showSuccess(context, '工具删除成功');
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(context, '删除失败：$e');
          }
        }
      }
    } finally {
      // 确保状态重置
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
