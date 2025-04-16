// lib/widgets/forum/post_form.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/app.dart';
import 'package:suxingchahui/services/form/post_form_cache_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 确保路径正确
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart'; // 确保路径正确
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../utils/device/device_utils.dart'; // 确保路径正确
import '../../../../utils/font/font_config.dart'; // 确保路径正确

class PostFormData {
  final String title;
  final String content;
  final List<String> tags;

  PostFormData({
    required this.title,
    required this.content,
    required this.tags,
  });
}

class PostForm extends StatefulWidget {
  final String title;
  final String initialTitle;
  final String initialContent;
  final List<String> initialTags;
  final List<String> availableTags;
  final bool isSubmitting;
  final Function(PostFormData) onSubmit;
  final String submitButtonText;
  final String? postIdInfo;
  final String? updatetimeInfo;
  final Widget? additionalInfo;

  const PostForm({
    Key? key,
    required this.title,
    this.initialTitle = '',
    this.initialContent = '',
    this.initialTags = const [],
    required this.availableTags,
    required this.isSubmitting,
    required this.onSubmit,
    required this.submitButtonText,
    this.postIdInfo,
    this.updatetimeInfo,
    this.additionalInfo,
  }) : super(key: key);

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedTags;
  final _formKey = GlobalKey<FormState>();

  bool _isDraftRestored = false;
  bool _isInternalSubmitting = false; // 内部逻辑状态，区分 widget.isSubmitting

  // Optional: Key for Scaffold if needed for ScaffoldMessenger or drawers
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedTags = List.from(widget.initialTags);
    // *** 再注册 observer 和检查草稿 ***
    WidgetsBinding.instance.addObserver(this);
    _checkAndRestoreDraft(); // <--- 添加检查草稿调用
  }

  @override
  void dispose() {
    // *** 如果不是内部正在提交，就保存草稿 ***
    if (!_isInternalSubmitting) {
      _saveDraft(); // <--- 添加保存草稿调用
    }
    // *** 移除 observer ***
    WidgetsBinding.instance.removeObserver(this);
    // dispose 控制器
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 新增生命周期监听方法
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用暂停或后台时，如果没在提交就保存草稿
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_isInternalSubmitting) {
        _saveDraft(); // <--- 添加保存草稿调用
      }
    }
  }

  String get _effectiveSubmitButtonText =>
      widget.isSubmitting ? '处理中...' : widget.submitButtonText;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width >= 960;

    // Note: No Scaffold.of() here anymore

    return Scaffold(
      // key: _scaffoldKey, // Assign key if needed
      appBar: CustomAppBar(
        // Assuming CustomAppBar works like a standard AppBar
        title: widget.title,
        actions: [
          TextButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: Text(
              _effectiveSubmitButtonText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: useDesktopLayout
            ? _buildDesktopLayout(context) // Pass the correct context
            : _buildMobileLayout(context), // Pass the correct context
      ),
    );
  }

  // --- Desktop Layout ---
  Widget _buildDesktopLayout(BuildContext context) {
    // Context is fine here
    final screenSize = MediaQuery.of(context).size;
    // *** FIX HERE: Use kToolbarHeight directly ***
    final double availableHeight = screenSize.height -
        kToolbarHeight -
        48; // 48 = 24 top + 24 bottom padding

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel
          Expanded(
            flex: 4,
            child: Card(
              elevation: 2,
              child: Container(
                constraints: BoxConstraints(maxHeight: availableHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('帖子信息'),
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      const SizedBox(height: 24),
                      _buildTagsSection(),
                      // Pass context if it needs it for ScaffoldMessenger
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildMetadataInfo(),
                      if (widget.additionalInfo != null) ...[
                        const SizedBox(height: 24),
                        widget.additionalInfo!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right panel
          Expanded(
            flex: 6,
            child: Card(
              elevation: 2,
              child: Container(
                constraints: BoxConstraints(maxHeight: availableHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('帖子内容'),
                      const SizedBox(height: 24),
                      _buildContentField(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      // Pass context if it needs it for ScaffoldMessenger
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Mobile Layout ---
  Widget _buildMobileLayout(BuildContext context) {
    // Context is fine here
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileInfoCard(),
          _buildMobileContentCard(),
          _buildMobileTagsCard(), // Pass context if needed
          if (widget.additionalInfo != null)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.additionalInfo!,
              ),
            ),
          const SizedBox(height: 8),
          _buildSubmitButton(), // Pass context if needed
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _checkAndRestoreDraft() async {
    // 如果是编辑帖子 (通过 widget.postIdInfo 判断) 或已恢复过，就不弹窗
    if (widget.postIdInfo != null || _isDraftRestored) return;

    bool hasDraft = await PostFormCacheService().hasDraft();
    if (hasDraft && mounted) {
      // 检查页面是否还在
      try {
        // 使用你的 CustomConfirmDialog
        await CustomConfirmDialog.show(
          context: context,
          title: '恢复草稿',
          message: '检测到上次未完成的编辑，是否恢复？',
          confirmButtonText: '恢复',
          cancelButtonText: '丢弃',
          onConfirm: () async {
            await _loadAndApplyDraft(); // 确认恢复
            if (mounted) {
              setState(() {
                _isDraftRestored = true;
              });
              AppSnackBar.showSuccess(context, '草稿已恢复');
            }
          },
          onCancel: () async {
            await PostFormCacheService().clearDraft(); // 丢弃就清掉
          },
        );
      } catch (e) {
        print("恢复草稿对话框出错: $e");
        if (mounted) AppSnackBar.showError(context, '处理草稿时出错');
        await PostFormCacheService().clearDraft(); // 出错也清掉
      }
    }
  }

  Future<void> _loadAndApplyDraft() async {
    final draft = await PostFormCacheService().loadDraft();
    if (draft != null && mounted) {
      setState(() {
        // 把草稿内容填回控制器和状态
        _titleController.text = draft.title;
        _contentController.text = draft.content;
        _selectedTags = List.from(draft.tags);
      });
      print("帖子草稿已应用。");
    }
  }

  Future<void> _saveDraft() async {
    // 如果表单是空的或内部正在提交，就不保存
    if (_isFormEmpty() || _isInternalSubmitting) {
      print("表单空或正在提交，不保存帖子草稿。");
      return;
    }
    // 创建草稿对象
    final draft = PostFormDraft(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: _selectedTags,
      lastSaved: DateTime.now(),
    );
    // 保存
    await PostFormCacheService().saveDraft(draft);
    print("帖子草稿已保存。");
  }

  // 辅助判断表单是否为空
  bool _isFormEmpty() {
    return _titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _selectedTags.isEmpty;
  }

  // --- Reusable UI Component Builders ---

  Widget _buildSectionTitle(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 16, thickness: 1),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        fontSize: 16,
      ),
      decoration: const InputDecoration(
        labelText: '标题',
        hintText: '请输入帖子标题',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入标题';
        }
        return null;
      },
    );
  }

  Widget _buildTagsSection() {
    // Pass context IF showing Snackbar here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签 (最多选择3个)',
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              onSelected: widget.isSubmitting
                  ? null
                  : (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedTags.length < 3) {
                            _selectedTags.add(tag);
                          } else {
                            // Show snackbar - context here *should* be okay
                            // because it's from user interaction after build.
                            AppSnackBar.showWarning(context, '最多只能选择 3 个标签');
                          }
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        fontSize: 15,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        labelText: '内容',
        hintText: '请输入帖子内容...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Icon(Icons.article_outlined),
        ),
      ),
      maxLines: null,
      minLines: DeviceUtils.isDesktop ? 10 : 8,
      maxLength: 5000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入内容';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    // Pass context IF showing Snackbar here
    return Center(
      child: AppButton(
        onPressed: widget.isSubmitting ? null : _submit,
        // Call _submit directly
        text: _effectiveSubmitButtonText,
        isPrimaryAction: true,
      ),
    );
  }

  Widget _buildMetadataInfo() {
    if (widget.updatetimeInfo != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.update, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '更新于: ${widget.updatetimeInfo}',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          // Consider adding postIdInfo display here if needed
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // --- Mobile Layout Specific Card Builders ---

  Widget _buildMobileInfoCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('帖子信息'),
            const SizedBox(height: 16),
            _buildTitleField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContentCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('帖子内容'),
            const SizedBox(height: 16),
            _buildContentField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTagsCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildTagsSection(), // Call reusable tags section
      ),
    );
  }

  // --- Form Submission Logic ---

  // --- 提交逻辑 ---
  void _submit() {
    FocusScope.of(context).unfocus(); // 收起键盘

    // 1. 验证表单
    if (!_formKey.currentState!.validate()) {
      AppSnackBar.showWarning(context, '请检查标题和内容是否填写完整');
      return;
    }
    // 2. 验证标签 (如果需要)
    if (_selectedTags.isEmpty) {
      AppSnackBar.showWarning(context, '请至少选择一个标签');
      return;
    }

    // *** 3. 标记内部提交开始 ***
    _isInternalSubmitting = true;

    // 4. 准备数据
    final data = PostFormData(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: _selectedTags,
    );

    // 5. 调用外部提交，并处理后续
    try {
      widget.onSubmit(data); // 调用外部传入的提交函数

      // 6. 提交动作已发出，异步清除草稿 (不阻塞 UI)
      //    假设 onSubmit 调用后就可以清除，如果需要等结果，逻辑要改
      PostFormCacheService().clearDraft().then((_) {
        print("提交后尝试清除草稿：成功");
      }).catchError((e) {
        print("提交后尝试清除草稿：失败 - $e");
      });
    } catch (e) {
      // 如果 onSubmit 抛出同步异常
      print("调用 onSubmit 出错: $e");
      if (mounted) AppSnackBar.showError(context, '提交时发生错误');
    } finally {
      // *** 7. 标记内部提交结束 ***
      // 注意：外部的 widget.isSubmitting 状态由父组件控制，这里只管内部状态
      _isInternalSubmitting = false;
    }
  }
}
