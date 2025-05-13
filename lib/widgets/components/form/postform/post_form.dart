import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 需要 Provider
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/services/utils/request_lock_service.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 需要 InputStateService
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 不修改这个文件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../utils/device/device_utils.dart';
import '../../../../utils/font/font_config.dart';

// --- PostFormData 保持不变 ---
class PostFormData {
  final String title;
  final String content;
  final List<PostTag> tags;

  PostFormData({
    required this.title,
    required this.content,
    required this.tags,
  });
}

class PostForm extends StatefulWidget {
  final String title;
  final String? initialTitle; // 从外部传入的原始值
  final String? initialContent; // 从外部传入的原始值
  final List<PostTag> initialTags;
  final List<PostTag> availableTags;
  final bool isSubmitting;
  final Function(PostFormData) onSubmit;
  final String submitButtonText;
  final String? postIdInfo;
  final String? updatetimeInfo;
  final Widget? additionalInfo;

  const PostForm({
    super.key,
    required this.title,
    this.initialTitle,
    this.initialContent,
    this.initialTags = const [],
    required this.availableTags,
    required this.isSubmitting,
    required this.onSubmit,
    required this.submitButtonText,
    this.postIdInfo,
    this.updatetimeInfo,
    this.additionalInfo,
  });

  @override
  _PostFormState createState() => _PostFormState();
}

/// -------------------------------------------------------------------
/// 后端payload参照
/// var req struct {
///		Title   string   `json:"title" binding:"required,min=2,max=100"`
///		Content string   `json:"content" binding:"required,min=2"`
///		Tags    []string `json:"tags"`
///	}
///-------------------------------------------------------------------

class _PostFormState extends State<PostForm> {
  late List<PostTag> _selectedTags;
  final _formKey = GlobalKey<FormState>();

  // State 变量存储最终传递给 FormTextInputField 的初始值
  late String _effectiveInitialTitle;
  late String _effectiveInitialContent;

  String get _submitOperationKey => widget.postIdInfo != null
      ? 'submit_post_${widget.postIdInfo}'
      : 'submit_new_post';

  String get _titleSlotName => widget.postIdInfo != null
      ? 'post_title_${widget.postIdInfo}'
      : 'post_title_new';
  String get _contentSlotName => widget.postIdInfo != null
      ? 'post_content_${widget.postIdInfo}'
      : 'post_content_new';

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);

    // *** 在 PostForm 的 initState 中决定最终的初始值 ***
    final inputStateService = context.read<InputStateService>();

    // 决定标题初始值：优先使用 Service 中的草稿
    final titleFromService = inputStateService.getText(_titleSlotName);
    _effectiveInitialTitle = (titleFromService.isNotEmpty)
        ? titleFromService // 使用草稿
        : (widget.initialTitle ?? ''); // 否则使用外部传入值（或空）

    // 决定内容初始值：优先使用 Service 中的草稿
    final contentFromService = inputStateService.getText(_contentSlotName);
    _effectiveInitialContent = (contentFromService.isNotEmpty)
        ? contentFromService // 使用草稿
        : (widget.initialContent ?? ''); // 否则使用外部传入值（或空）

    // *** 不需要在这里写回 Service ***
    // *** FormTextInputField 会根据 slotName 和这个 effectiveInitialValue 自行处理 ***
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _effectiveSubmitButtonText =>
      widget.isSubmitting ? '处理中...' : widget.submitButtonText;

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

  // --- 布局方法 (_buildDesktopLayout, _buildMobileLayout) ---
  Widget _buildDesktopLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double availableHeight = screenSize.height - kToolbarHeight - 48;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      _buildTitleField(), // 使用更新后的 State 变量
                      const SizedBox(height: 24),
                      _buildTagsSection(),
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
                      _buildContentField(), // 使用更新后的 State 变量
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
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

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileInfoCard(),
          _buildMobileContentCard(),
          _buildMobileTagsCard(),
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
          _buildSubmitButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- UI 构建辅助方法 ---

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

  // 私有函数，构建标题填写区域
  Widget _buildTitleField() {
    return FormTextInputField(
      slotName: _titleSlotName,
      initialValue: _effectiveInitialTitle, // 使用 State 中决定的初始值
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
        if (value.length < 2) {
          return '标题长度过短';
        }
        if (value.length > 100) {
          return '标题长度过长';
        }
        return null;
      },
    );
  }

  Widget _buildTagsSection() {
    // (标签逻辑不变)
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
                tag.displayText,
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

  // 构建内容输入区域
  Widget _buildContentField() {
    return FormTextInputField(
      slotName: _contentSlotName,
      initialValue: _effectiveInitialContent, // 使用 State 中决定的初始值
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
        if (value.length < 2) {
          return '内容过短';
        }
        if (value.length > 500) {
          return '内容过长';
        }

        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: FunctionalButton(
        isEnabled: !widget.isSubmitting,
        onPressed: !widget.isSubmitting ? () => _submit() : null,
        label: _effectiveSubmitButtonText,
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
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMobileInfoCard() {
    // (内部调用 _buildTitleField 已使用新 State 变量)
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
    // (内部调用 _buildContentField 已使用新 State 变量)
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
    // (标签部分不变)
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildTagsSection(),
      ),
    );
  }

  // --- Form Submission Logic ---
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppSnackBar.showWarning(context, '请检查标题和内容是否填写完整');
      return;
    }
    if (_selectedTags.isEmpty) {
      AppSnackBar.showWarning(context, '请至少选择一个标签');
      return;
    }

    final inputStateService = context.read<InputStateService>();
    // *** 从 InputStateService 获取最终提交的值 ***
    final finalTitle = inputStateService.getText(_titleSlotName);
    final finalContent = inputStateService.getText(_contentSlotName);

    // 再次校验从 Service 获取的值
    if (finalTitle.trim().isEmpty || finalContent.trim().isEmpty) {
      AppSnackBar.showWarning(context, '请确保标题和内容已输入');
      // 这种情况理论上不应该发生，因为 FormField 验证过了，
      // 且 Service 的值应该与 Controller 同步。但加上保险。
      return;
    }

    bool didExecute = await RequestLockService.instance.tryLockAsync(
      _submitOperationKey,
      action: () async {
        final data = PostFormData(
          title: finalTitle.trim(), // 使用 Service 的最终值
          content: finalContent.trim(), // 使用 Service 的最终值
          tags: _selectedTags,
        );

        try {
          widget.onSubmit(data); // 调用外部提交

          // *** 提交成功或开始后，清除 Service 中的状态 ***
          inputStateService.clearText(_titleSlotName);
          inputStateService.clearText(_contentSlotName);
          print("提交触发，已清除 Title 和 Content 的内存状态。");
        } catch (e) {
          print("执行提交操作时出错: $e");
          if (mounted) AppSnackBar.showError(context, '提交时发生错误');
        }
      },
      onLockFailed: () {
        if (mounted) {
          AppSnackBar.showInfo(context, '正在提交中，请稍候...');
        }
      },
    );

    if (didExecute) {
      // print('提交操作已开始执行...');
    }
  }
}
