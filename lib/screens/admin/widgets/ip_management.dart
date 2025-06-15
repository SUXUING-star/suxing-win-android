import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/defence/defence_item.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
// 使用你提供的日期格式化工具
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';
import 'package:suxingchahui/services/main/denfence/defence_service.dart';

class IPManagement extends StatefulWidget {
  final InputStateService inputStateService;
  const IPManagement({
    super.key,
    required this.inputStateService,
  });

  @override
  State<IPManagement> createState() => _IPManagementState();
}

class _IPManagementState extends State<IPManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _blacklistIpController = TextEditingController();
  late final DefenceService _defenceService;
  bool _hasInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInit) {
      _defenceService = context.read<DefenceService>();
      _hasInit = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _blacklistIpController.dispose();
    super.dispose();
  }

  Future<void> _removeFromBlacklist(String ip) async {
    setState(() => _isLoading = true);
    try {
      await _defenceService.removeFromBlacklist(ip);
      if (!mounted) return;
      AppSnackBar.showSuccess('已从黑名单移除: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError('操作失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToBlacklist(String ip) async {
    if (ip.isEmpty) {
      AppSnackBar.showWarning('请输入有效的IP地址');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _defenceService.addToBlacklist(ip);
      _blacklistIpController.clear();
      if (!mounted) return;
      AppSnackBar.showSuccess('已添加到黑名单: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError('操作失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToWhitelist(String ip) async {
    if (ip.isEmpty) {
      AppSnackBar.showWarning('请输入有效的IP地址');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _defenceService.addToWhitelist(ip);
      _ipController.clear();
      if (!mounted) return;
      AppSnackBar.showSuccess('已添加到白名单: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError('操作失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWhitelist(String ip) async {
    setState(() => _isLoading = true);
    try {
      await _defenceService.removeFromWhitelist(ip);
      if (!mounted) return;
      AppSnackBar.showSuccess('已从白名单移除: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError('操作失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '黑名单', icon: Icon(Icons.block)),
            Tab(text: '白名单', icon: Icon(Icons.check_circle)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListTab(
                context: context,
                listType: 'blacklist',
                controller: _blacklistIpController,
                onAdd: _addToBlacklist,
                future: _defenceService.getBlacklist(),
                onRemove: _removeFromBlacklist,
              ),
              _buildListTab(
                context: context,
                listType: 'whitelist',
                controller: _ipController,
                onAdd: _addToWhitelist,
                future: _defenceService.getWhitelist(),
                onRemove: _removeFromWhitelist,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTab({
    required BuildContext context,
    required String listType,
    required TextEditingController controller,
    required Future<void> Function(String) onAdd,
    required Future<void> Function(String) onRemove,
    required Future<List<DefenceItem>> future,
  }) {
    final bool isBlacklist = listType == 'blacklist';
    final String addLabel = isBlacklist ? '添加IP到黑名单' : '添加IP到白名单';
    final String buttonLabel = isBlacklist ? '拉黑' : '添加';
    final String emptyMessage = isBlacklist ? '黑名单为空' : '白名单为空';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextInputField(
                  inputStateService: widget.inputStateService,
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: addLabel,
                    hintText: '输入IP地址',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FunctionalButton(
                onPressed:
                    _isLoading ? () {} : () => onAdd(controller.text.trim()),
                isEnabled: !_isLoading,
                label: buttonLabel,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DefenceItem>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return CustomErrorWidget(
                    errorMessage: '加载失败: ${snapshot.error}');
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return EmptyStateWidget(message: emptyMessage);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400.0,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 2.5,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _IPCard(
                    item: item,
                    isBlacklist: isBlacklist,
                    onRemove: onRemove,
                    isLoading: _isLoading,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IPCard extends StatelessWidget {
  final DefenceItem item;
  final bool isBlacklist;
  final Function(String) onRemove;
  final bool isLoading;

  const _IPCard({
    required this.item,
    required this.isBlacklist,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBlacklist ? Colors.red : Colors.green;
    final icon = isBlacklist ? Icons.block : Icons.check_circle;
    final bool isExpired = item.isExpired;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isExpired ? Colors.grey.shade400 : color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: isExpired ? Colors.grey : color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.ip,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '添加: ${DateTimeFormatter.formatStandard(item.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '过期: ${DateTimeFormatter.formatStandard(item.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.grey.shade600 : color,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExpired ? '已过期' : '有效',
                  style: TextStyle(
                    color: isExpired ? Colors.grey : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: isLoading ? null : () => onRemove(item.ip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
