import 'dart:io'; // 需要导入 dart:io
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 需要导入 image_picker
// import 'package:intl/intl.dart'; // 这个文件不再需要 intl
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入 AppSnackBar
import '../../../../models/announcement/announcement.dart';
import '../../../../services/common/upload/file_upload_service.dart'; // 导入上传服务
import '../../../../utils/device/device_utils.dart';
import 'field/basic_info_field.dart';
import 'field/display_settings_field.dart';
import 'field/action_field.dart';
import 'preview/announcement_preview_button.dart'; // 预览按钮也需要调整

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
  late AnnouncementFull _formData; // 使用 _formData 来跟踪表单状态
  bool _isLoading = false; // 表单级别的加载状态

  // --- 图片状态 ---
  dynamic _imageSource; // String? (URL) 或 XFile? (本地文件) or null
  String? _originalImageUrl; // 编辑时记录原始 URL
  // --- 图片状态结束 ---

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // 使用 copyWith 初始化表单数据，与 widget 分离
    _formData = widget.announcement.copyWith();

    // 初始化图片状态
    _originalImageUrl = widget.announcement.imageUrl;
    _imageSource = widget.announcement.imageUrl; // 初始源就是 URL 或 null
  }

  // 图片源更新回调
  void _handleImageSourceChange(dynamic newSource) {
    setState(() {
      _imageSource = newSource;
      // 注意：这里不需要更新 _formData.imageUrl，因为最终 URL 在提交时才确定
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackBar.showWarning(context, '请检查表单内容是否填写完整');
      return;
    }

    setState(() { _isLoading = true; });

    String? finalImageUrl; // 最终提交的图片 URL
    String? uploadError;

    try {
      // --- 图片处理 ---
      if (_imageSource is XFile) {
        // 1. 需要上传新图片
        final fileToUpload = File((_imageSource as XFile).path);
        // 仅当编辑模式且图片已更改时，传递 oldImageUrl
        String? oldUrlToReplace = (widget.announcement.id.isNotEmpty && _imageSource != _originalImageUrl)
            ? _originalImageUrl
            : null;

        //print("准备上传新图片... 旧 URL (如替换): $oldUrlToReplace");
        finalImageUrl = await FileUpload.uploadImage(
          fileToUpload,
          folder: 'announcements', // 指定文件夹
          // 根据需要设置 maxWidth, maxHeight, quality
          maxWidth: 1200,
          quality: 85,
          oldImageUrl: oldUrlToReplace,
        );
        //print("新图片上传成功，URL: $finalImageUrl");

      } else if (_imageSource is String && (_imageSource as String).isNotEmpty) {
        // 2. 使用的是 URL 字符串
        finalImageUrl = _imageSource as String;
        //print("使用提供的 URL: $finalImageUrl");

      } else {
        // 3. 图片源是 null 或空字符串，表示无图片或已清除
        finalImageUrl = null;
        // 如果是编辑模式且之前有图片，后端需要处理删除逻辑
        if (widget.announcement.id.isNotEmpty && _originalImageUrl != null) {
         //print("图片已被清除，将提交 null URL。后端应处理删除原图: $_originalImageUrl");
        } else {
          //print("未设置图片或图片为空。");
        }
      }
      // --- 图片处理结束 ---

      // 创建最终要提交的 AnnouncementFull 对象
      // 合并表单数据和处理后的图片 URL
      final AnnouncementFull announcementToSubmit = _formData.copyWith(
        // 关键：用处理后的 finalImageUrl 更新
        imageUrl: finalImageUrl,
        clearImageUrl: finalImageUrl == null, // 如果最终url是null，明确告诉copyWith清除
        // 其他字段已通过各自的 onChanged 在 _formData 中更新
      );

      // 调用外部提交函数
      print("准备提交公告数据: ${announcementToSubmit.toJson()}"); // 打印 JSON 方便调试
      widget.onSubmit(announcementToSubmit);

    } catch (e) {
      // 捕获上传或处理过程中的错误
      uploadError = '处理公告时出错: $e';
      print(uploadError);
      if (mounted) {
        AppSnackBar.showError(context, uploadError);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: useDesktopLayout ? _buildDesktopLayout(context) : _buildMobileLayout(context),
        ),
        if (_isLoading) _buildLoadingOverlay(), // 加载遮罩
      ],
    );
  }

  // --- 布局构建方法 ---
  // Desktop 布局
  Widget _buildDesktopLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100;
    final isEditing = widget.announcement.id.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel (展示设置和操作)
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: cardHeight),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('展示设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 16),
                          // --- DisplaySettingsField ---
                          DisplaySettingsField(
                            startDate: _formData.startDate,
                            endDate: _formData.endDate,
                            isActive: _formData.isActive,
                            priority: _formData.priority,
                            imageSource: _imageSource, // 传递当前图片源
                            onStartDateChanged: (date) => setState(() => _formData = _formData.copyWith(startDate: date)),
                            onEndDateChanged: (date) {
                              if (date.isBefore(_formData.startDate)) {
                                AppSnackBar.showWarning(context, '结束日期不能早于开始日期');
                              } else {
                                setState(() => _formData = _formData.copyWith(endDate: date));
                              }
                            },
                            onActiveChanged: (value) => setState(() => _formData = _formData.copyWith(isActive: value)),
                            onPriorityChanged: (value) => setState(() => _formData = _formData.copyWith(priority: value)),
                            onImageSourceChanged: _handleImageSourceChange, // 处理图片源变化
                          ),
                          const SizedBox(height: 24),
                          const Text('操作链接 (可选)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 16),
                          // --- ActionField ---
                          ActionField(
                            actionUrl: _formData.actionUrl,
                            actionText: _formData.actionText,
                            onActionUrlChanged: (value) => setState(() => _formData = _formData.copyWith(actionUrl: value, clearActionUrl: value.isEmpty)),
                            onActionTextChanged: (value) => setState(() => _formData = _formData.copyWith(actionText: value, clearActionText: value.isEmpty)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right panel (基本信息)
            Expanded(
              flex: 6,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: cardHeight),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 16),
                          // --- BasicInfoField ---
                          BasicInfoField(
                            title: _formData.title,
                            content: _formData.content,
                            type: _formData.type,
                            onTitleChanged: (value) => setState(() => _formData = _formData.copyWith(title: value)),
                            onContentChanged: (value) => setState(() => _formData = _formData.copyWith(content: value)),
                            onTypeChanged: (value) => setState(() => _formData = _formData.copyWith(type: value)),
                          ),
                          const SizedBox(height: 32),
                          Center(child: _buildButtonRow(isEditing)),
                          const SizedBox(height: 16),
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

  // Mobile 布局
  Widget _buildMobileLayout(BuildContext context) {
    final isEditing = widget.announcement.id.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基本信息 Card
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BasicInfoField(
              title: _formData.title,
              content: _formData.content,
              type: _formData.type,
              onTitleChanged: (value) => setState(() => _formData = _formData.copyWith(title: value)),
              onContentChanged: (value) => setState(() => _formData = _formData.copyWith(content: value)),
              onTypeChanged: (value) => setState(() => _formData = _formData.copyWith(type: value)),
            ),
          ),
        ),
        // 展示设置 Card
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DisplaySettingsField(
              startDate: _formData.startDate,
              endDate: _formData.endDate,
              isActive: _formData.isActive,
              priority: _formData.priority,
              imageSource: _imageSource,
              onStartDateChanged: (date) => setState(() => _formData = _formData.copyWith(startDate: date)),
              onEndDateChanged: (date) {
                if (date.isBefore(_formData.startDate)) {
                  AppSnackBar.showWarning(context, '结束日期不能早于开始日期');
                } else {
                  setState(() => _formData = _formData.copyWith(endDate: date));
                }
              },
              onActiveChanged: (value) => setState(() => _formData = _formData.copyWith(isActive: value)),
              onPriorityChanged: (value) => setState(() => _formData = _formData.copyWith(priority: value)),
              onImageSourceChanged: _handleImageSourceChange,
            ),
          ),
        ),
        // 操作链接 Card
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ActionField(
              actionUrl: _formData.actionUrl,
              actionText: _formData.actionText,
              onActionUrlChanged: (value) => setState(() => _formData = _formData.copyWith(actionUrl: value, clearActionUrl: value.isEmpty)),
              onActionTextChanged: (value) => setState(() => _formData = _formData.copyWith(actionText: value, clearActionText: value.isEmpty)),
            ),
          ),
        ),
        _buildButtonRow(isEditing),
        const SizedBox(height: 16),
      ],
    );
  }

  // 按钮行
  Widget _buildButtonRow(bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: const Text('取消'),
        ),
        const SizedBox(width: 16),
        // --- 预览按钮 ---
        AnnouncementPreviewButton(
          // 传递当前的表单数据和图片源给预览按钮
          announcement: _formData,
          imageSourceForPreview: _imageSource,
          isLoading: _isLoading,
        ),
        const SizedBox(width: 16),
        // --- 提交按钮 ---
        ElevatedButton.icon(
          icon: _isLoading
              ? Container( // 替换为加载指示器
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 8),
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Icon(isEditing ? Icons.save : Icons.add_circle_outline, size: 20),
          label: Text(isEditing ? '更新公告' : '创建公告'),
          onPressed: _isLoading ? null : _submitForm, // 调用新的提交方法
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // 加载遮罩
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在处理...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}