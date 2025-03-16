// lib/screens/forum/edit_post_screen.dart
import 'package:flutter/material.dart';
import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/common/toaster/toaster.dart';
import '../../../widgets/components/form/postform/post_form.dart';
import '../../../widgets/components/form/postform/config/post_taglists.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _forumService = ForumService();
  final List<String> _availableTags = PostTagLists.availableTags;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return PostForm(
      title: '编辑帖子',
      initialTitle: widget.post.title,
      initialContent: widget.post.content,
      initialTags: List.from(widget.post.tags),
      availableTags: _availableTags,
      isSubmitting: _isSubmitting,
      onSubmit: _submitEdit,
      submitButtonText: '保存修改',
      postIdInfo: widget.post.id.substring(0, 8) + '...',
      createTimeInfo: widget.post.createTime.toString().substring(0, 16),
    );
  }

  Future<void> _submitEdit(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      await _forumService.updatePost(widget.post.id, data.title, data.content, data.tags);
      Toaster.success(context, "编辑帖子成功！");
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