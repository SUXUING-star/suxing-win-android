// lib/widgets/forum/post_form.dart
import 'package:flutter/material.dart';
import '../../../../utils/device/device_utils.dart';
import '../../../../utils/font/font_config.dart';

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
  final String? createTimeInfo;
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
    this.createTimeInfo,
    this.additionalInfo,
  }) : super(key: key);

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedTags;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and check if desktop layout should be used
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: Text(
              widget.isSubmitting ? '处理中...' : '提交',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: useDesktopLayout ? _buildDesktopLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100; // Allow for some margin

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel - Post metadata (40% width)
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('帖子信息'),
                          const SizedBox(height: 24),
                          _buildTitleField(),
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
            ),

            const SizedBox(width: 24),

            // Right panel - Post content (60% width)
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('帖子内容'),
                          const SizedBox(height: 24),
                          _buildContentField(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Center(
              child: ElevatedButton(
                onPressed: widget.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.isSubmitting ? '处理中...' : widget.submitButtonText,
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
        const Divider(),
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
        if (value == null || value.isEmpty) {
          return '请输入标题';
        }
        return null;
      },
    );
  }

  Widget _buildTagsSection() {
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.25),
              checkmarkColor: Colors.blue,
              backgroundColor: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedTags.length < 3) {
                      _selectedTags.add(tag);
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
      ),
      decoration: const InputDecoration(
        labelText: '内容',
        hintText: '请输入帖子内容',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.article),
      ),
      maxLines: 16,
      maxLength: 5000,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入内容';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: widget.isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          widget.isSubmitting ? '处理中...' : widget.submitButtonText,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataInfo() {
    if (widget.postIdInfo != null && widget.createTimeInfo != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '帖子ID: ${widget.postIdInfo}',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            '创建于: ${widget.createTimeInfo}',
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
            TextFormField(
              controller: _contentController,
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
              ),
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '请输入帖子内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 5000,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入内容';
                }
                return null;
              },
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '最多选择3个标签',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
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
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue.withOpacity(0.25),
                  checkmarkColor: Colors.blue,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedTags.length < 3) {
                          _selectedTags.add(tag);
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
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = PostFormData(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: _selectedTags,
    );

    widget.onSubmit(data);
  }
}