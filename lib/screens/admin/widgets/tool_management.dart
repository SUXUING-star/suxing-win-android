// lib/screens/admin/widgets/tool_management.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/models/linkstools/tool.dart';
import 'package:suxingchahui/widgets/components/form/toolform/tool_form_dialog.dart';

class ToolManagement extends StatefulWidget {
  final LinkToolService linkToolService;
  const ToolManagement({
    super.key,
    required this.linkToolService,
  });

  @override
  State<ToolManagement> createState() => _ToolManagementState();
}

class _ToolManagementState extends State<ToolManagement>
    with SnackBarNotifierMixin {
  late Future<List<Tool>> _toolsFuture;
  bool _isProcessing = false; // 防止重复点击
  late final LinkToolService _linkToolService;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _linkToolService = widget.linkToolService;
      _hasInitializedDependencies = true;
    }

    if (_hasInitializedDependencies) {
      _loadTools();
    }
  }

  // --- 新增: 加载数据的方法 ---
  void _loadTools({bool forceRefresh = false}) {
    setState(() {
      _toolsFuture = _linkToolService.getTools(forceRefresh: forceRefresh);
    });
  }

  // --- 修改: 刷新数据方法 ---
  Future<void> _refreshData() async {
    _loadTools(forceRefresh: true);
    await _toolsFuture; // 等待 Future 完成给 RefreshIndicator
  }
  // --- 结束修改 ---

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    return Scaffold(
      // --- 修改: 使用 FutureBuilder ---
      body: FutureBuilder<List<Tool>>(
        future: _toolsFuture, // 绑定 Future
        builder: (context, snapshot) {
          // 处理加载状态
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingWidget.inline();
          }
          // 处理错误状态
          if (snapshot.hasError) {
            return CustomErrorWidget(
              onRetry: () => _loadTools(forceRefresh: true),
              errorMessage: '错误: ${snapshot.error}',
            );
          }
          // 处理无数据或空数据状态
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: Stack(
                children: [ListView(), Center(child: Text('暂无工具数据'))],
              ),
            );
          }

          // 有数据时
          final tools = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshData, // 下拉刷新
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : _showAddToolDialog, // 防止重复
                    icon: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Icon(Icons.add),
                    label: Text(_isProcessing ? '处理中...' : '添加工具'),
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
                          leading: const Icon(Icons.build), // 可以改成 Tool 的图标
                          title: Text(tool.name),
                          subtitle: Text(tool.description,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _isProcessing
                                    ? null
                                    : () => _showEditToolDialog(tool),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: _isProcessing
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
      // --- 结束修改 ---
    );
  }

  // --- 修改: 添加/编辑/删除操作后刷新数据 ---
  Future<void> _showAddToolDialog() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await showDialog<Map<String, dynamic>>(
        // 指定泛型类型
        context: context,
        builder: (context) => const ToolFormDialog(),
      );

      if (result != null && mounted) {
        try {
          final tool = Tool.fromJson(result); // 转换
          await _linkToolService.addTool(tool);
          _loadTools(forceRefresh: true); // 强制刷新
          showSnackbar(message: '工具添加成功', type: SnackbarType.success);
        } catch (e) {
          showSnackbar(message: '添加失败：$e', type: SnackbarType.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showEditToolDialog(Tool tool) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await showDialog<Map<String, dynamic>>(
        // 指定泛型类型
        context: context,
        builder: (context) => ToolFormDialog(tool: tool),
      );

      if (result != null && mounted) {
        try {
          final updatedTool = Tool.fromJson(result); // 转换
          await _linkToolService.updateTool(updatedTool);
          _loadTools(forceRefresh: true); // 强制刷新
          showSnackbar(message: '工具更新成功', type: SnackbarType.success);
        } catch (e) {
          // print('更新工具错误: $e');
          showSnackbar(message: '更新失败：$e', type: SnackbarType.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showDeleteConfirmation(Tool tool) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除工具"${tool.name}"吗？'),
          actions: [
            FunctionalTextButton(
                onPressed: () => Navigator.pop(context, false), label: '取消'),
            FunctionalButton(
                onPressed: () => Navigator.pop(context, true), label: '删除'),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await _linkToolService.deleteTool(tool.id);
          _loadTools(forceRefresh: true); // 强制刷新
          showSnackbar(message: '工具删除成功', type: SnackbarType.success);
        } catch (e) {
          showSnackbar(message: '删除失败：$e', type: SnackbarType.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
// --- 结束修改 ---
}
