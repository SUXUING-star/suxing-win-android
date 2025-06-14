// lib/widgets/components/form/gameform/field/game_tags_field.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameTagsField extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onChanged;

  const GameTagsField({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  @override
  _GameTagsFieldState createState() => _GameTagsFieldState();
}

class _GameTagsFieldState extends State<GameTagsField> {
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;

    setState(() {
      if (!_tags.contains(tag.trim())) {
        _tags.add(tag.trim());
        widget.onChanged(_tags);
      }
      _tagController.clear();
    });
    _focusNode.requestFocus();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.onChanged(_tags);
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '游戏标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '输入标签，按回车添加',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                ),
                onSubmitted: _addTag,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => _buildTagChip(tag)).toList(),
        ),
        SizedBox(height: 8),
        Text(
          '提示: 尽量填会社名/画师/剧本家',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(tag),
      deleteIcon: Icon(Icons.close, size: 18),
      onDeleted: () => _removeTag(tag),
      backgroundColor: Theme.of(context).primaryColor.withSafeOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).primaryColor.withSafeOpacity(0.3)),
      ),
    );
  }
}