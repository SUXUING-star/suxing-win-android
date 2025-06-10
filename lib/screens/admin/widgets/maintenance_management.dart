// lib/screens/admin/widgets/maintenance_management.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class MaintenanceManagement extends StatefulWidget {
  final MaintenanceService maintenanceService;
  final InputStateService inputStateService;
  const MaintenanceManagement({
    super.key,
    required this.inputStateService,
    required this.maintenanceService,
  });

  @override
  State<MaintenanceManagement> createState() => _MaintenanceManagementState();
}

class _MaintenanceManagementState extends State<MaintenanceManagement> {
  final _formKey = GlobalKey<FormState>();
  bool _isActive = false;
  bool _allowLogin = false;
  bool _forceLogout = false;
  String _maintenanceType = 'scheduled';

  bool _hasInitializedDependencies = false;
  String _message = '系统正在维护中，请稍后再试。';

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));

  bool _isLoading = false;

  final List<String> _maintenanceTypes = [
    'scheduled', // 计划维护
    'emergency', // 紧急维护
    'upgrade' // 升级维护
  ];

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
      // 延迟执行，避免在构建过程中调用 notifyListeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentMaintenanceStatus();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCurrentMaintenanceStatus() async {
    try {
      // 强制刷新维护状态
      await widget.maintenanceService.checkMaintenanceStatus();

      // 如果当前有维护状态，则加载到表单中
      if (mounted &&
          widget.maintenanceService.isInMaintenance &&
          widget.maintenanceService.maintenanceInfo != null) {
        final info = widget.maintenanceService.maintenanceInfo!;
        setState(() {
          _isActive = true;
          _message = info.message;
          _allowLogin = info.allowLogin;
          _forceLogout = info.forceLogout;
          _maintenanceType = info.maintenanceType;
          _startTime = info.startTime;
          _endTime = info.endTime;
        });
      }
    } catch (e) {
      //
    }
  }

  Future<void> _saveMaintenanceSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.maintenanceService.setMaintenanceMode(
        isActive: _isActive,
        startTime: _startTime,
        endTime: _endTime,
        message: _message,
        allowLogin: _allowLogin,
        forceLogout: _forceLogout,
        maintenanceType: _maintenanceType,
      );

      if (success) {
        AppSnackBar.showSuccess(_isActive ? '系统维护模式已开启' : '系统维护模式已关闭');
      } else {
        AppSnackBar.showError('设置维护模式失败');
      }
    } catch (e) {
      AppSnackBar.showError('发生错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateTime(
      BuildContext invokerContext, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: invokerContext, // 使用 invokerContext
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (!mounted) return;

    if (pickedDate != null) {
      // ---- 第二个 await: showTimePicker ----
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
      );
      if (!mounted) return;

      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStartTime) {
            _startTime = newDateTime;
            // 如果结束时间早于开始时间，自动调整结束时间
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            // 确保结束时间不早于开始时间
            if (newDateTime.isAfter(_startTime)) {
              _endTime = newDateTime;
            } else {
              AppSnackBar.showWarning('结束时间必须晚于开始时间');
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '维护模式说明',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '开启维护模式后，系统将显示维护通知给所有用户。您可以设置维护的时间、消息和类型。',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '不同类型的维护模式有不同的视觉效果：',
                    ),
                    const SizedBox(height: 8),
                    _buildMaintenanceTypeInfo(
                      context,
                      'scheduled',
                      '计划维护',
                      '橙色图标，用户可以关闭通知',
                      Icons.schedule,
                      Colors.orange,
                    ),
                    _buildMaintenanceTypeInfo(
                      context,
                      'upgrade',
                      '升级维护',
                      '蓝色图标，用户可以关闭通知',
                      Icons.system_update_alt,
                      Colors.blue,
                    ),
                    _buildMaintenanceTypeInfo(
                      context,
                      'emergency',
                      '紧急维护',
                      '红色图标，用户无法关闭通知',
                      Icons.warning_amber_rounded,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '维护模式设置',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 激活维护模式开关
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '维护模式状态',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;

                              // 如果开启维护模式，默认设置开始时间为现在，结束时间为1小时后
                              if (_isActive) {
                                _startTime = DateTime.now();
                                _endTime = DateTime.now()
                                    .add(const Duration(hours: 1));
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    if (_isActive) ...[
                      // 维护类型选择
                      const SizedBox(height: 16),
                      Text(
                        '维护类型',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _maintenanceType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _maintenanceTypes.map((type) {
                          String label;
                          IconData icon;
                          Color color;

                          switch (type) {
                            case 'emergency':
                              label = '紧急维护';
                              icon = Icons.warning_amber_rounded;
                              color = Colors.red;
                              break;
                            case 'upgrade':
                              label = '升级维护';
                              icon = Icons.system_update_alt;
                              color = Colors.blue;
                              break;
                            case 'scheduled':
                            default:
                              label = '计划维护';
                              icon = Icons.schedule;
                              color = Colors.orange;
                              break;
                          }

                          return DropdownMenuItem<String>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 8),
                                Text(label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _maintenanceType = value;

                              // 紧急维护默认强制登出，不允许登录
                              if (value == 'emergency') {
                                _forceLogout = true;
                                _allowLogin = false;
                              }
                            });
                          }
                        },
                      ),

                      // 维护消息
                      const SizedBox(height: 16),
                      Text(
                        '维护消息',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FormTextInputField(
                        inputStateService: widget.inputStateService,
                        initialValue: _message,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '输入显示给用户的维护消息',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入维护消息';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _message = value;
                          });
                        },
                      ),

                      // 维护时间设置
                      const SizedBox(height: 16),
                      Text(
                        '维护时间设置',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('开始时间'),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(_startTime),
                              ),
                              onTap: () => _selectDateTime(context, true),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('结束时间'),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(_endTime),
                              ),
                              onTap: () => _selectDateTime(context, false),
                            ),
                          ),
                        ],
                      ),

                      // 高级选项
                      const SizedBox(height: 16),
                      Text(
                        '高级选项',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('允许用户登录'),
                        subtitle: const Text('维护期间用户仍然可以登录系统'),
                        value: _allowLogin,
                        onChanged: (value) {
                          setState(() {
                            _allowLogin = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('强制用户登出'),
                        subtitle: const Text('维护开始时强制所有已登录用户退出'),
                        value: _forceLogout,
                        onChanged: (value) {
                          setState(() {
                            _forceLogout = value ?? false;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FunctionalButton(
                        onPressed:
                            _isLoading ? () {} : _saveMaintenanceSettings,
                        isEnabled: !_isLoading,
                        label: "保存",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceTypeInfo(
    BuildContext context,
    String type,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
