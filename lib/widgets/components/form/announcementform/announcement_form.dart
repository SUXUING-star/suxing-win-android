// lib/widgets/components/form/announcementform/announcement_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/announcement/announcement.dart';
import '../../../../utils/device/device_utils.dart';
import 'field/basic_info_field.dart';
import 'field/display_settings_field.dart';
import 'field/action_field.dart';
import 'preview/announcement_preview_button.dart';

class AnnouncementForm extends StatefulWidget {
  final AnnouncementFull announcement;
  final Function(AnnouncementFull) onSubmit;
  final VoidCallback onCancel;

  const AnnouncementForm({
    Key? key,
    required this.announcement,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  late AnnouncementFull _announcement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 复制公告对象，避免直接修改原对象
    _announcement = AnnouncementFull(
      id: widget.announcement.id,
      title: widget.announcement.title,
      content: widget.announcement.content,
      type: widget.announcement.type,
      imageUrl: widget.announcement.imageUrl,
      actionUrl: widget.announcement.actionUrl,
      actionText: widget.announcement.actionText,
      createdAt: widget.announcement.createdAt,
      priority: widget.announcement.priority,
      isActive: widget.announcement.isActive,
      startDate: widget.announcement.startDate,
      endDate: widget.announcement.endDate,
      targetUsers: widget.announcement.targetUsers,
      createdBy: widget.announcement.createdBy,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_announcement);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and orientation
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: useDesktopLayout ? _buildDesktopLayout(context) : _buildMobileLayout(context),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100; // Allow for some margin
    final isEditing = widget.announcement.id.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel - Display and Action settings (40% width)
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: cardHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '展示设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),

                          // 展示设置 - 传入加载状态与回调
                          DisplaySettingsField(
                            startDate: _announcement.startDate,
                            endDate: _announcement.endDate,
                            isActive: _announcement.isActive,
                            priority: _announcement.priority,
                            imageUrl: _announcement.imageUrl,
                            isLoading: _isLoading,
                            onStartDateChanged: (date) {
                              setState(() {
                                _announcement.startDate = date;
                                // 如果结束日期早于开始日期，则更新结束日期
                                if (_announcement.endDate.isBefore(date)) {
                                  _announcement.endDate = date.add(const Duration(days: 7));
                                }
                              });
                            },
                            onEndDateChanged: (date) {
                              if (date.isBefore(_announcement.startDate)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('结束日期不能早于开始日期')),
                                );
                              } else {
                                setState(() {
                                  _announcement.endDate = date;
                                });
                              }
                            },
                            onActiveChanged: (value) {
                              setState(() {
                                _announcement.isActive = value;
                              });
                            },
                            onPriorityChanged: (value) {
                              setState(() {
                                _announcement.priority = value;
                              });
                            },
                            onImageUrlChanged: (value) {
                              setState(() {
                                _announcement.imageUrl = value.isEmpty ? null : value;
                              });
                            },
                            onLoadingChanged: (loading) {
                              setState(() {
                                _isLoading = loading;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // 操作链接
                          ActionField(
                            actionUrl: _announcement.actionUrl,
                            actionText: _announcement.actionText,
                            onActionUrlChanged: (value) {
                              setState(() {
                                _announcement.actionUrl = value.isEmpty ? null : value;
                              });
                            },
                            onActionTextChanged: (value) {
                              setState(() {
                                _announcement.actionText = value.isEmpty ? null : value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Right panel - Basic Information (60% width)
            Expanded(
              flex: 6,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: cardHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '基本信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),

                          // 基本信息
                          BasicInfoField(
                            title: _announcement.title,
                            content: _announcement.content,
                            type: _announcement.type,
                            onTitleChanged: (value) {
                              setState(() {
                                _announcement.title = value;
                              });
                            },
                            onContentChanged: (value) {
                              setState(() {
                                _announcement.content = value;
                              });
                            },
                            onTypeChanged: (value) {
                              setState(() {
                                _announcement.type = value;
                              });
                            },
                          ),
                          const SizedBox(height: 32),

                          // 提交与预览按钮 - 居中
                          Center(child: _buildButtonRow(isEditing)),
                          const SizedBox(height: 16), // 添加底部填充以避免切断
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final isEditing = widget.announcement.id.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基本信息
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BasicInfoField(
              title: _announcement.title,
              content: _announcement.content,
              type: _announcement.type,
              onTitleChanged: (value) {
                setState(() {
                  _announcement.title = value;
                });
              },
              onContentChanged: (value) {
                setState(() {
                  _announcement.content = value;
                });
              },
              onTypeChanged: (value) {
                setState(() {
                  _announcement.type = value;
                });
              },
            ),
          ),
        ),

        // 展示设置
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DisplaySettingsField(
              startDate: _announcement.startDate,
              endDate: _announcement.endDate,
              isActive: _announcement.isActive,
              priority: _announcement.priority,
              imageUrl: _announcement.imageUrl,
              isLoading: _isLoading,
              onStartDateChanged: (date) {
                setState(() {
                  _announcement.startDate = date;
                  if (_announcement.endDate.isBefore(date)) {
                    _announcement.endDate = date.add(const Duration(days: 7));
                  }
                });
              },
              onEndDateChanged: (date) {
                if (date.isBefore(_announcement.startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('结束日期不能早于开始日期')),
                  );
                } else {
                  setState(() {
                    _announcement.endDate = date;
                  });
                }
              },
              onActiveChanged: (value) {
                setState(() {
                  _announcement.isActive = value;
                });
              },
              onPriorityChanged: (value) {
                setState(() {
                  _announcement.priority = value;
                });
              },
              onImageUrlChanged: (value) {
                setState(() {
                  _announcement.imageUrl = value.isEmpty ? null : value;
                });
              },
              onLoadingChanged: (loading) {
                setState(() {
                  _isLoading = loading;
                });
              },
            ),
          ),
        ),

        // 操作链接
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ActionField(
              actionUrl: _announcement.actionUrl,
              actionText: _announcement.actionText,
              onActionUrlChanged: (value) {
                setState(() {
                  _announcement.actionUrl = value.isEmpty ? null : value;
                });
              },
              onActionTextChanged: (value) {
                setState(() {
                  _announcement.actionText = value.isEmpty ? null : value;
                });
              },
            ),
          ),
        ),

        // 按钮
        _buildButtonRow(isEditing),
        const SizedBox(height: 16), // 添加底部填充以避免切断
      ],
    );
  }

  Widget _buildButtonRow(bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: const Text('取消'),
        ),
        const SizedBox(width: 16),
        AnnouncementPreviewButton(
          announcement: _announcement,
          isLoading: _isLoading,
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isEditing ? '更新公告' : '创建公告',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '正在处理图片...',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}