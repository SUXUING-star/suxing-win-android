import 'package:flutter/material.dart';
// *** 1. 导入 RequestLockService ***
import 'package:suxingchahui/services/utils/request_lock_service.dart';
import 'package:suxingchahui/services/form/post_form_cache_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
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
  final bool isSubmitting; // 由父组件控制的提交状态
  final Function(PostFormData) onSubmit; // 提交回调
  final String submitButtonText;
  final String? postIdInfo;
  final String? updatetimeInfo;
  final Widget? additionalInfo;

  const PostForm({
    super.key,
    required this.title,
    this.initialTitle = '',
    this.initialContent = '',
    this.initialTags = const [],
    required this.availableTags,
    required this.isSubmitting, // 接收外部状态
    required this.onSubmit,
    required this.submitButtonText,
    this.postIdInfo,
    this.updatetimeInfo,
    this.additionalInfo,
  });

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedTags;
  final _formKey = GlobalKey<FormState>();

  bool _isDraftRestored = false;
  // --- 移除内部提交状态，依赖 widget.isSubmitting 和 RequestLockService ---
  // bool _isInternalSubmitting = false;

  // --- 定义用于锁定的 Key ---
  // 如果是编辑，可以用 postId 保证唯一性；如果是新建，用一个固定的 key
  String get _submitOperationKey => widget.postIdInfo != null
      ? 'submit_post_${widget.postIdInfo}'
      : 'submit_new_post';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedTags = List.from(widget.initialTags);
    WidgetsBinding.instance.addObserver(this);
    _checkAndRestoreDraft();
  }

  @override
  void dispose() {
    // *** 检查是否正在提交 (通过锁服务) ***
    // 如果操作正在进行，不保存草稿（因为提交成功后会清除）
    if (!RequestLockService.instance.isLocked(_submitOperationKey)) {
      _saveDraft();
    }
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // *** 检查是否正在提交 (通过锁服务) ***
      if (!RequestLockService.instance.isLocked(_submitOperationKey)) {
        _saveDraft();
      }
    }
  }

  // --- 使用 widget.isSubmitting 来决定按钮文本和状态 ---
  String get _effectiveSubmitButtonText =>
      widget.isSubmitting ? '处理中...' : widget.submitButtonText;

  // --- build 方法保持不变 ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width >= 960;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
      ),
      body: Form(
        key: _formKey,
        child: useDesktopLayout
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  // --- 布局方法 (_buildDesktopLayout, _buildMobileLayout) 保持不变 ---
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

  // --- 草稿相关方法 (_checkAndRestoreDraft, _loadAndApplyDraft, _saveDraft, _isFormEmpty) 保持不变 ---
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
    // 如果表单是空的就不保存
    if (_isFormEmpty()) {
      print("表单空，不保存帖子草稿。");
      // 在 dispose 或 AppLifecycle 检查时，如果正在提交，也不应该保存
      // （这个检查已移到调用 _saveDraft 的地方）
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

  // --- UI 构建辅助方法 (_buildSectionTitle, _buildTitleField, _buildTagsSection, _buildContentField, _buildMetadataInfo, _buildMobileInfoCard, _buildMobileContentCard, _buildMobileTagsCard) 保持不变 ---

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
    return FormTextInputField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '标题',
        hintText: '请输入帖子标题',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      maxLength: 50,
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
              // *** 使用 widget.isSubmitting 控制 FilterChip 是否可选 ***
              onSelected: widget.isSubmitting
                  ? null // 如果正在提交，不允许修改标签
                  : (selected) {
                      // 检查锁状态不是必须的，因为isSubmitting应该已经反映了
                      // if (RequestLockService.instance.isLocked(_submitOperationKey)) return;
                      setState(() {
                        if (selected) {
                          if (_selectedTags.length < 3) {
                            _selectedTags.add(tag);
                          } else {
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
    return FormTextInputField(
      controller: _contentController,
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
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入内容';
        }
        return null;
      },
    );
  }

  // --- 修改提交按钮逻辑 ---
  Widget _buildSubmitButton() {
    return Center(
      child: FunctionalButton(
        // *** 使用 widget.isSubmitting 来禁用按钮 ***
        // 同时 RequestLockService 会在 _submit 内部再次检查
        onPressed: widget.isSubmitting ? null : _submit, // 禁用时为 null
        label: _effectiveSubmitButtonText, // 文本根据 widget.isSubmitting 变化
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

  // *** 修改提交逻辑以使用 RequestLockService ***
  Future<void> _submit() async {
    // 改为 async
    FocusScope.of(context).unfocus(); // 收起键盘

    // 1. 验证表单
    if (!_formKey.currentState!.validate()) {
      AppSnackBar.showWarning(context, '请检查标题和内容是否填写完整');
      return;
    }
    // 2. 验证标签
    if (_selectedTags.isEmpty) {
      AppSnackBar.showWarning(context, '请至少选择一个标签');
      return;
    }

    // 3. 使用 RequestLockService 尝试锁定并执行
    bool didExecute = await RequestLockService.instance.tryLockAsync(
      _submitOperationKey, // 使用定义的 key
      action: () async {
        // --- 锁定成功后执行的核心逻辑 ---
        // a. 准备数据
        final data = PostFormData(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _selectedTags,
        );

        // b. 调用外部提交函数 (这里假设外部会处理 loading 状态的变更)
        // 注意：widget.onSubmit 本身不一定是 async 的，但它触发的动作通常是
        // tryLockAsync 会等待这个 Future 完成（如果 action 是 async）
        try {
          widget.onSubmit(data); // 调用父组件传入的回调

          // c. 提交动作已发出，异步清除草稿
          // 最好是在父组件确认提交成功后再清除，但如果 onSubmit
          // 本身就代表了“开始提交”，在这里清除也是一种策略
          await PostFormCacheService().clearDraft();
          // print("提交操作已触发，草稿已清除。");
        } catch (e) {
          // 如果 onSubmit 或 clearDraft 内部抛出同步或异步异常
          print("执行提交操作时出错: $e");
          if (mounted) AppSnackBar.showError(context, '提交时发生错误');
          // 异常会被 tryLockAsync 捕获，并确保 unlock
          // 如果需要向上层传递错误，可以在这里 rethrow
          // rethrow;
        }
        // --- 核心逻辑结束 ---
      },
      onLockFailed: () {
        // --- 锁定失败时的回调 ---
        if (mounted) {
          AppSnackBar.showInfo(context, '正在提交中，请稍候...');
        }
      },
    );

    // `didExecute` 可以用来判断 action 是否真的执行了
    if (didExecute) {
      // print('提交操作已开始执行...');
      // 这里不需要再手动管理 _isInternalSubmitting 了
    }
  }
}
