import 'package:flutter/material.dart';
import '../../../../../../utils/font/font_config.dart';
import '../field/tag_selection.dart';

class DesktopPostForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final List<String> selectedTags;
  final List<String> availableTags;
  final bool isSubmitting;
  final Function() onSubmit;
  final String submitButtonText;
  final String? postIdInfo;
  final String? createTimeInfo;
  final Widget? additionalInfo;
  final Function(String tag, bool selected) onTagSelected;

  const DesktopPostForm({
    Key? key,
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.selectedTags,
    required this.availableTags,
    required this.isSubmitting,
    required this.onSubmit,
    required this.submitButtonText,
    this.postIdInfo,
    this.createTimeInfo,
    this.additionalInfo,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100; // Allow for some margin

    return Form(
      key: formKey,
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
                          _buildSectionTitle('帖子信息', context),
                          const SizedBox(height: 24),
                          _buildTitleField(context),
                          const SizedBox(height: 24),
                          TagSelection(
                            availableTags: availableTags,
                            selectedTags: selectedTags,
                            onTagSelected: onTagSelected,
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildMetadataInfo(context),
                          if (additionalInfo != null) ...[
                            const SizedBox(height: 24),
                            additionalInfo!,
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
                          _buildSectionTitle('帖子内容', context),
                          const SizedBox(height: 24),
                          _buildContentField(context),
                          const SizedBox(height: 32),
                          _buildSubmitButton(context),
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

  Widget _buildSectionTitle(String text, BuildContext context) {
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

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      controller: titleController,
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

  Widget _buildContentField(BuildContext context) {
    return TextFormField(
      controller: contentController,
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

  Widget _buildSubmitButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isSubmitting ? '处理中...' : submitButtonText,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataInfo(BuildContext context) {
    if (postIdInfo != null && createTimeInfo != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '帖子ID: $postIdInfo',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            '创建于: $createTimeInfo',
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
}