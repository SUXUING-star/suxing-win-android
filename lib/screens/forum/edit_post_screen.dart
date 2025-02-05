// lib/screens/forum/edit_post_screen.dart
import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _forumService = ForumService();
  final List<String> _availableTags = ['讨论', '攻略', '分享', '求助'];
  late List<String> _selectedTags;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _selectedTags = List.from(widget.post.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑帖子'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitEdit,
            child: Text(
              _isSubmitting ? '保存中...' : '保存',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请输入帖子标题',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '请输入帖子内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              maxLength: 5000,
            ),
            const SizedBox(height: 16),
            const Text('标签'),
            Wrap(
              spacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
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

  Future<void> _submitEdit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      await _forumService.updatePost(widget.post.id, title, content, _selectedTags);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}