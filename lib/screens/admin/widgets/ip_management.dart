// lib/screens/admin/widgets/ip_management.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/services/main/denfence/defence_service.dart';

class IPManagement extends StatefulWidget {
  const IPManagement({super.key});

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
  late final InputStateService _inputStateService;
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
      _inputStateService =
          Provider.of<InputStateService>(context, listen: false);
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
      AppSnackBar.showError(context, '已从黑名单移除: $ip');
      setState(() {});
    } catch (e) {
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToBlacklist(String ip) async {
    if (ip.isEmpty) {
      AppSnackBar.showWarning(context, '请输入有效的IP地址');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final defenceService = context.read<DefenceService>();
      await defenceService.addToBlacklist(ip);
      _blacklistIpController.clear();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '已添加到黑名单: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToWhitelist(String ip) async {
    if (ip.isEmpty) {
      AppSnackBar.showWarning(context, '请输入有效的IP地址');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final defenceService = context.read<DefenceService>();
      await defenceService.addToWhitelist(ip);
      _ipController.clear();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '已添加到白名单: $ip');
      setState(() {});
    } catch (e) {
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWhitelist(String ip) async {
    setState(() => _isLoading = true);
    try {
      final defenceService = context.read<DefenceService>();
      await defenceService.removeFromWhitelist(ip);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '已从白名单移除: $ip');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
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
              _buildBlacklistTab(),
              _buildWhitelistTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlacklistTab() {
    final defenceService = context.read<DefenceService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextInputField(
                  inputStateService: _inputStateService,
                  controller: _blacklistIpController,
                  decoration: const InputDecoration(
                    labelText: '添加IP到黑名单',
                    hintText: '输入IP地址',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FunctionalButton(
                onPressed: _isLoading
                    ? () {}
                    : () => _addToBlacklist(_blacklistIpController.text.trim()),
                isEnabled: !_isLoading,
                label: '拉黑',
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: defenceService.getBlacklist(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingWidget.inline();
              }

              if (snapshot.hasError) {
                return CustomErrorWidget(
                  errorMessage: '加载失败: ${snapshot.error}',
                );
              }

              final ips = snapshot.data ?? [];
              if (ips.isEmpty) {
                return EmptyStateWidget(message: "黑名单为空");
              }

              return ListView.builder(
                itemCount: ips.length,
                itemBuilder: (context, index) {
                  final ip = ips[index];
                  final createdAt = DateTime.parse(ip['created_at']).toLocal();
                  final expiresAt = DateTime.parse(ip['expires_at']).toLocal();
                  final isExpired = expiresAt.isBefore(DateTime.now());

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(ip['ip']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('添加时间: ${createdAt.toString().split('.')[0]}'),
                          Text(
                            '过期时间: ${expiresAt.toString().split('.')[0]}',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.red,
                            ),
                          ),
                          Text(
                            isExpired ? '已过期' : '有效',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isLoading
                            ? null
                            : () => _removeFromBlacklist(ip['ip']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWhitelistTab() {
    final defenceService = context.read<DefenceService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextInputField(
                  inputStateService: _inputStateService,
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: '添加IP到白名单',
                    hintText: '输入IP地址',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FunctionalButton(
                  onPressed: _isLoading
                      ? () {}
                      : () => _addToWhitelist(_ipController.text.trim()),
                  isEnabled: !_isLoading,
                  label: '添加'),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: defenceService.getWhitelist(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingWidget.inline();
              }

              if (snapshot.hasError) {
                return CustomErrorWidget(
                  errorMessage: '加载失败: ${snapshot.error}',
                );
              }

              final ips = snapshot.data ?? [];
              if (ips.isEmpty) {
                return EmptyStateWidget(message: '白名单为空');
              }

              return ListView.builder(
                itemCount: ips.length,
                itemBuilder: (context, index) {
                  final ip = ips[index];
                  final createdAt = DateTime.parse(ip['created_at']).toLocal();
                  final expiresAt = DateTime.parse(ip['expires_at']).toLocal();
                  final isExpired = expiresAt.isBefore(DateTime.now());

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(ip['ip']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('添加时间: ${createdAt.toString().split('.')[0]}'),
                          Text(
                            '过期时间: ${expiresAt.toString().split('.')[0]}',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.green,
                            ),
                          ),
                          Text(
                            isExpired ? '已过期' : '有效',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isLoading
                            ? null
                            : () => _removeFromWhitelist(ip['ip']),
                      ),
                    ),
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
