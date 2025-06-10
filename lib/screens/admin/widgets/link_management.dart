// lib/screens/admin/widgets/link_management.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 引入 Button
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 引入 Button
import 'package:suxingchahui/models/linkstools/site_link.dart';
import 'package:suxingchahui/widgets/components/form/linkform/link_form_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class LinkManagement extends StatefulWidget {
  final LinkToolService linkToolService;
  final InputStateService inputStateService;
  const LinkManagement({
    super.key,
    required this.linkToolService,
    required this.inputStateService,
  });

  @override
  State<LinkManagement> createState() => _LinkManagementState();
}

class _LinkManagementState extends State<LinkManagement> {
  late Future<List<SiteLink>> _linksFuture;
  bool _isProcessing = false; // 用于防止重复点击按钮

  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }

    if (_hasInitializedDependencies) {
      _loadLinks();
    }
  }

  // --- 新增: 加载数据的方法 ---
  void _loadLinks({bool forceRefresh = false}) {
    setState(() {
      _linksFuture = widget.linkToolService.getLinks();
    });
  }

  // --- 修改: 刷新数据方法 ---
  Future<void> _refreshData() async {
    // 强制刷新
    _loadLinks(forceRefresh: true);
    // FutureBuilder 会自动处理状态，这里不需要更多操作
    // 但为了 RefreshIndicator 完成动画，返回一个 Future
    await _linksFuture; // 等待新的 Future 完成
  }
  // --- 结束修改 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SiteLink>>(
        future: _linksFuture, // 绑定 Future 状态
        builder: (context, snapshot) {
          // 处理加载状态
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 保持加载指示器在中间
            return const LoadingWidget();
          }
          // 处理错误状态
          if (snapshot.hasError) {
            return CustomErrorWidget(
              onRetry: () => _loadLinks(forceRefresh: true),
              retryText: '重试',
              errorMessage: '错误: ${snapshot.error}',
            );
          }
          // 处理无数据或空数据状态
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // 允许下拉刷新空列表
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: Stack(
                // 使用 Stack 让 "暂无数据" 能响应下拉刷新
                children: [
                  ListView(), // 空 ListView 使得 RefreshIndicator 可用
                  const EmptyStateWidget(
                    message: "啥也没有",
                  ),
                ],
              ),
            );
          }

          // 有数据时
          final links = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshData, // 下拉刷新调用
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : _showAddLinkDialog, // 防止重复点击
                    icon: _isProcessing
                        ? const LoadingWidget()
                        : const Icon(Icons.add),
                    label: Text(_isProcessing ? '处理中...' : '添加链接'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(link.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(link.description),
                              if (link.url.isNotEmpty)
                                Text(
                                  link.url,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _isProcessing
                                    ? null
                                    : () => _showEditLinkDialog(link),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: _isProcessing
                                    ? null
                                    : () => _showDeleteConfirmation(link),
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
  Future<void> _showAddLinkDialog() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await showDialog<Map<String, dynamic>>(
        // 指定泛型类型
        context: context,
        builder: (context) => LinkFormDialog(
          inputStateService: widget.inputStateService,
        ),
      );

      if (result != null && mounted) {
        try {
          await widget.linkToolService.addLink(SiteLink.fromJson(result));
          _loadLinks(forceRefresh: true); // 成功后强制刷新
          AppSnackBar.showSuccess('链接添加成功');
        } catch (e) {
          AppSnackBar.showError('添加失败：$e');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showEditLinkDialog(SiteLink link) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await showDialog<Map<String, dynamic>>(
        // 指定泛型类型
        context: context,
        builder: (context) => LinkFormDialog(
          link: link,
          inputStateService: widget.inputStateService,
        ),
      );

      if (result != null && mounted) {
        try {
          // 使用 Link.fromJson 将 Map 转换为 Link 对象
          await widget.linkToolService.updateLink(SiteLink.fromJson(result));
          _loadLinks(forceRefresh: true); // 成功后强制刷新
          AppSnackBar.showSuccess('链接更新成功');
        } catch (e) {
          AppSnackBar.showError('更新失败：$e');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showDeleteConfirmation(SiteLink link) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除链接"${link.title}"吗？'),
          actions: [
            FunctionalTextButton(
              // 使用自定义按钮
              onPressed: () => Navigator.pop(context, false),
              label: '取消',
            ),
            FunctionalButton(
              // 使用自定义按钮
              onPressed: () => Navigator.pop(context, true),
              label: '删除',
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await widget.linkToolService.deleteLink(link.id);
          _loadLinks(forceRefresh: true); // 成功后强制刷新
          AppSnackBar.showSuccess('链接删除成功');
        } catch (e) {
          AppSnackBar.showError('删除失败：$e');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
