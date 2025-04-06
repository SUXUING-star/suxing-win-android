// lib/screens/forum/edit_post_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/components/form/postform/post_form.dart';
import '../../../widgets/components/form/postform/config/post_taglists.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;

  const EditPostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _forumService = ForumService();
  final List<String> _availableTags = PostTagLists.availableTags;
  bool _isSubmitting = false;
  bool _isLoading = true;
  Post? _post;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    try {
      setState(() => _isLoading = true);
      final post = await _forumService.getPost(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context,'加载帖子数据失败: ${e.toString()}');

    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingWidget.fullScreen(message: "正在加载数据");
    }

    if (_post == null) {
      return CustomErrorWidget(title: '无法加载帖子数据');
    }

    return PostForm(
      title: '编辑帖子',
      initialTitle: _post!.title,
      initialContent: _post!.content,
      initialTags: List.from(_post!.tags),
      availableTags: _availableTags,
      isSubmitting: _isSubmitting,
      onSubmit: _submitEdit,
      submitButtonText: '保存修改',
      postIdInfo: _post!.id.substring(0, 8) + '...',
      updatetimeInfo: _post!.updateTime.toString().substring(0, 16),
    );
  }

  Future<void> _submitEdit(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      await _forumService.updatePost(_post!.id, data.title, data.content, data.tags);
      AppSnackBar.showSuccess(context, "编辑成功");
      NavigationUtils.pop(context, true);
    } catch (e) {
      AppSnackBar.showError(context,'编辑失败: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}