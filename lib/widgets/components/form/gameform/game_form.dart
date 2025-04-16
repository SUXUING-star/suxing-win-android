// lib/widgets/components/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/services/form/game_form_cache_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart'; // 确保路径正确
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'dart:async';

import '../../../../models/game/game.dart'; // 确保路径正确
import '../../../../services/common/upload/file_upload_service.dart'; // 确保路径正确
import '../../../../utils/device/device_utils.dart'; // 确保路径正确
import '../../../../utils/font/font_config.dart'; // 确保路径正确
import 'field/category_field.dart'; // 确保路径正确
import 'field/cover_image_field.dart'; // 确保路径正确
import 'field/download_links_field.dart'; // 确保路径正确
import 'field/game_images_field.dart'; // 确保路径正确
import 'field/tags_field.dart'; // 确保路径正确
import 'preview/game_preview_button.dart'; // 确保路径正确

class GameForm extends StatefulWidget {
  final Game? game;
  final Function(Game) onSubmit;

  const GameForm({
    Key? key,
    this.game,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _GameFormState createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musicUrlController = TextEditingController();

  // --- 图片状态变量 ---
  dynamic _coverImageSource; // String? (URL) 或 XFile? (本地文件)
  List<dynamic> _gameImagesSources = []; // List<String or XFile>

  final Set<String> _deletedOriginalImageUrls = {};
  // --- 图片状态变量结束 ---

  List<DownloadLink> _downloadLinks = [];
  double _rating = 0.0;
  bool _isLoading = false;
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];

  bool _isDraftRestored = false; // 标记是否已恢复草稿，避免重复询问
  bool _isSubmitting = false; // 标记是否正在提交，避免在提交时保存草稿

  String? _coverImageError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <--- 注册 observer
    _initializeFormData(); // 先初始化默认或编辑状态
    _checkAndRestoreDraft(); // <--- 再检查并恢复草稿
  }

  @override
  void dispose() {
    // 在 dispose 时，如果不是正在提交，则保存草稿
    if (!_isSubmitting) {
      _saveDraft(); // <--- 保存草稿
    }
    WidgetsBinding.instance.removeObserver(this); // <--- 移除 observer
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _musicUrlController.dispose();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用进入后台或暂停时，保存草稿
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (!_isSubmitting) {
        _saveDraft(); // <--- 保存草稿
      }
    }
  }

  void _initializeFormData() {
    _coverImageSource = null;
    _gameImagesSources = [];
    _deletedOriginalImageUrls.clear();
    _downloadLinks = [];
    _rating = 0.0;
    _selectedCategories = [];
    _selectedTags = [];
    _isLoading = false;
    _coverImageError = null;
    _categoryError = null;
    _titleController.clear();
    _summaryController.clear();
    _descriptionController.clear();
    _musicUrlController.clear();

    if (widget.game != null) {
      final game = widget.game!;
      _titleController.text = game.title;
      _summaryController.text = game.summary;
      _descriptionController.text = game.description;
      _musicUrlController.text = game.musicUrl ?? '';
      _coverImageSource = game.coverImage;
      _gameImagesSources = List.from(game.images);
      _downloadLinks = List.from(game.downloadLinks);
      _rating = game.rating;
      _selectedCategories = game.category
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      try {
        _selectedTags = game.tags != null ? List.from(game.tags!) : [];
      } catch (e) {
        _selectedTags = [];
        //print('初始化标签时出错: $e');
      }
    }
  }


  // --- 草稿检查与恢复 ---
  Future<void> _checkAndRestoreDraft() async {
    // 如果正在编辑游戏，或者已经恢复过草稿，则不再检查
    if (widget.game != null || _isDraftRestored) return;

    bool hasDraft = await GameFormCacheService().hasDraft();
    // 必须检查 mounted，妈的异步操作回来页面可能没了
    if (hasDraft && mounted) {
      try {
        await CustomConfirmDialog.show(
          context: context,
          title: '恢复草稿',
          message: '检测到上次未完成的编辑，是否恢复？',
          confirmButtonText: '恢复',
          cancelButtonText: '丢弃',
          onConfirm: () async {
            await _loadAndApplyDraft();
            if (mounted) {
              setState(() {
                _isDraftRestored = true; // 标记已恢复
              });
              AppSnackBar.showSuccess(context, '草稿已恢复');
            }
          },
          onCancel: () async {
            // 取消恢复，清除旧草稿
            await GameFormCacheService().clearDraft();
            print("User chose to discard the draft.");
          },
        );
      } catch (e) {
        print("Error showing/handling restore draft dialog: $e");
        if (mounted) {
          AppSnackBar.showError(context, '处理草稿时出错');
        }
        await GameFormCacheService().clearDraft(); // 出错也清掉
      }
    }
  }

  // --- 加载并应用草稿数据 ---
  Future<void> _loadAndApplyDraft() async {
    final draft = await GameFormCacheService().loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft.title;
        _summaryController.text = draft.summary;
        _descriptionController.text = draft.description;
        _musicUrlController.text = draft.musicUrl ?? '';
        _selectedCategories = draft.selectedCategories;
        _selectedTags = draft.selectedTags;

        _downloadLinks = draft.downloadLinks
            .map((map) => DownloadLink.fromJson(map)) // 草稿存的是Map，要转回来
            .toList();

        // 只恢复 URL，本地文件丢了就丢了
        _coverImageSource = draft.coverImageUrl;
        _gameImagesSources = List<dynamic>.from(draft.gameImageUrls);

        _coverImageError = null; // 清错误提示
        _categoryError = null;
      });
      print("Draft applied to form state.");
    } else if (draft == null) {
      print("Could not load draft or draft was null.");
    }
  }

  // --- 保存当前表单状态为草稿 ---
  Future<void> _saveDraft() async {
    // 表单空或者正在提交，滚蛋，不保存
    if (_isFormEmpty() || _isSubmitting) {
      print("Form is empty or submitting, skipping draft save.");
      return;
    }

    // 图片只存 URL，XFile 去死吧
    String? coverImageUrl;
    if (_coverImageSource is String) {
      coverImageUrl = _coverImageSource as String;
    }
    List<String> gameImageUrls = _gameImagesSources
        .whereType<String>() // 只搞 String
        .toList();

    // 创建草稿对象
    final draft = GameFormDraft(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      description: _descriptionController.text.trim(),
      musicUrl: _musicUrlController.text.trim().isEmpty ? null : _musicUrlController.text.trim(),
      coverImageUrl: coverImageUrl,
      gameImageUrls: gameImageUrls,
      downloadLinks: _downloadLinks.map((link) => link.toJson()).toList(), // 链接存 Map
      selectedCategories: _selectedCategories,
      selectedTags: _selectedTags,
      lastSaved: DateTime.now(),
    );

    await GameFormCacheService().saveDraft(draft);
    print("Draft saved on dispose/pause.");
  }

  // --- 辅助函数：检查表单是不是空的 ---
  bool _isFormEmpty() {
    // 简单检查下文本框、图片、链接、分类、标签是不是都没填
    return _titleController.text.trim().isEmpty &&
        _summaryController.text.trim().isEmpty &&
        _descriptionController.text.trim().isEmpty &&
        _musicUrlController.text.trim().isEmpty &&
        (_coverImageSource == null || (_coverImageSource is String && (_coverImageSource as String).isEmpty)) && // 检查封面图是不是真没有
        _gameImagesSources.where((s) => (s is String && s.isNotEmpty) || s is XFile).isEmpty && // 检查截图是不是真没有
        _downloadLinks.isEmpty &&
        _selectedCategories.isEmpty &&
        _selectedTags.isEmpty;
  }

  bool _validateForm() {
    bool isValid = _formKey.currentState?.validate() ?? false;

    // 验证封面图 (可能是 String URL 或 XFile)
    bool hasCover = _coverImageSource != null &&
        !(_coverImageSource is String && (_coverImageSource as String).isEmpty);
    if (!hasCover) {
      setState(() {
        _coverImageError = '请添加封面图片';
      });
      isValid = false;
    } else {
      setState(() {
        _coverImageError = null;
      });
    }

    if (_selectedCategories.isEmpty) {
      setState(() {
        _categoryError = '请选择至少一个分类';
      });
      isValid = false;
    } else {
      setState(() {
        _categoryError = null;
      });
    }

    return isValid;
  }



  Future<void> _submitForm() async {
    // 1. 表单验证，不过关就滚
    if (!_validateForm()) {
      AppSnackBar.showError(context, '请检查表单中的错误并修正');
      return;
    }

    // 2. 设置加载和提交状态
    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    // 声明最终要用的变量
    String? finalCoverImageUrl;
    List<String> finalGameImagesUrls = []; // *** 初始化为空列表 ***
    String? errorMessage;

    try {
      // ------------------------------------
      // 3. 处理封面图
      // ------------------------------------
      final dynamic currentCoverSource = _coverImageSource;

      if (currentCoverSource is XFile) {
        // 是新文件？上传它
        print("上传新封面...");
        final fileToUpload = File(currentCoverSource.path);
        finalCoverImageUrl = await FileUpload.uploadImage(
          fileToUpload,
          folder: 'games/covers',
          // 不再传递 oldImageUrl
        );
        print("新封面URL: $finalCoverImageUrl");
      } else if (currentCoverSource is String && currentCoverSource.isNotEmpty) {
        // 是旧 URL？直接用
        finalCoverImageUrl = currentCoverSource;
        print("保留封面URL: $finalCoverImageUrl");
      } else {
        // 啥也不是？那就是空
        finalCoverImageUrl = ''; // 或者 null，看你后端怎么定义“无图”
        print("无封面图");
      }

      // ------------------------------------
      // 4. 处理游戏截图
      // ------------------------------------
      final List<dynamic> currentImageSources = List.from(_gameImagesSources);
      final List<File> filesToUpload = [];
      final List<int> xFileIndices = []; // 记录 XFile 在原列表的索引

      // 4a. 找出所有新选的本地文件 (XFile)
      for (int i = 0; i < currentImageSources.length; i++) {
        if (currentImageSources[i] is XFile) {
          filesToUpload.add(File((currentImageSources[i] as XFile).path));
          xFileIndices.add(i);
        }
      }

      // 4b. 上传这些新文件 (如果有的话)
      List<String> uploadedUrls = [];
      if (filesToUpload.isNotEmpty) {
        print("上传 ${filesToUpload.length} 张新截图...");
        uploadedUrls = await FileUpload.uploadFiles(
          filesToUpload,
          folder: 'games/screenshots',
        );
        if (uploadedUrls.length != filesToUpload.length) {
          throw Exception("截图上传数量对不上！");
        }
        print("新截图上传成功: $uploadedUrls");
      } else {
        print("没有新截图需要上传");
      }

      // 4c. 构建最终 URL 列表 (合并旧 URL 和新上传的 URL，保持顺序)
      int uploadedUrlIndex = 0;
      // *** 创建一个临时的、允许 null 的列表来按顺序放置 URL ***
      List<String?> orderedUrlsPlaceholder = List.filled(currentImageSources.length, null);

      for (int i = 0; i < currentImageSources.length; i++) {
        final source = currentImageSources[i];
        if (xFileIndices.contains(i)) {
          // 这个位置原来是 XFile，用对应的已上传 URL 填入
          if (uploadedUrlIndex < uploadedUrls.length) {
            orderedUrlsPlaceholder[i] = uploadedUrls[uploadedUrlIndex++];
          }
        } else if (source is String && source.isNotEmpty) {
          // 这个位置是有效的旧 URL，直接使用
          orderedUrlsPlaceholder[i] = source;
        }
        // 其他情况（比如 null 或空字符串）保持为 null
      }

      // *** 过滤掉 null，得到最终的 List<String> ***
      finalGameImagesUrls = orderedUrlsPlaceholder.whereType<String>().toList();
      print("最终提交的截图列表 (${finalGameImagesUrls.length} 张): $finalGameImagesUrls");


      // ------------------------------------
      // 5. 构建 Game 对象
      // ------------------------------------
      final game = Game(
        id: widget.game?.id ?? mongo.ObjectId().toHexString(),
        authorId: widget.game?.authorId ?? 'GET_CURRENT_USER_ID()', // TODO: 替换成真实的用户 ID 获取逻辑
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategories.join(', '),
        coverImage: finalCoverImageUrl ?? '',      // 使用处理后的封面 URL
        images: finalGameImagesUrls,               // 使用处理后的截图 URL 列表
        tags: _selectedTags,
        rating: widget.game?.rating ?? 0.0,
        createTime: widget.game?.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
        viewCount: widget.game?.viewCount ?? 0,
        likeCount: widget.game?.likeCount ?? 0,
        likedBy: widget.game?.likedBy ?? [],
        downloadLinks: _downloadLinks,
        musicUrl: _musicUrlController.text.trim().isEmpty
            ? null
            : _musicUrlController.text.trim(),
        lastViewedAt: widget.game?.lastViewedAt,
        // 注意: approvalStatus, reviewedAt, reviewedBy 等字段由后端处理，前端不提交
      );

      // ------------------------------------
      // 6. 调用 onSubmit 回调
      // ------------------------------------
      print("提交 Game 对象...");
      widget.onSubmit(game);
      print("提交完成.");

      // ------------------------------------
      // 7. 清除本地草稿
      // ------------------------------------
      await GameFormCacheService().clearDraft();
      print("本地草稿已清除.");

    } catch (e) {
      // ------------------------------------
      // 8. 错误处理
      // ------------------------------------
      errorMessage = '操，提交时出错了: $e';
      print(errorMessage);
      if (mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } finally {
      // ------------------------------------
      // 9. 重置状态
      // ------------------------------------
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  // 当封面图片选择变化时调用
  void _handleCoverImageChange(dynamic newSource) {
    setState(() {
      _coverImageSource = newSource; // 直接更新状态
      // 如果新来源有效，清除错误提示
      if (_coverImageSource != null &&
          !(_coverImageSource is String &&
              (_coverImageSource as String).isEmpty)) {
        _coverImageError = null;
      }
    });
    //print("封面图片状态更新为: $_coverImageSource");
  }

  // 当游戏截图列表变化时调用
  void _handleGameImagesChange(List<dynamic> newSourcesList) {
    setState(() {
      _gameImagesSources = newSourcesList; // 直接更新状态
    });
    //print("游戏截图状态更新为: $_gameImagesSources");
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: useDesktopLayout
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
        if (_isLoading) LoadingWidget.inline(),
      ],
    );
  }

  // --- 桌面布局构建方法 (Refactored) ---
  Widget _buildDesktopLayout(BuildContext context) {
    final desktopCardHeight =
        MediaQuery.of(context).size.height - 100; // 保持原有计算方式
    return SingleChildScrollView(
      // 使用 SingleChildScrollView 替代 ListView 保持桌面原有滚动行为
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧面板 (视觉内容)
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: desktopCardHeight),
                  child: SingleChildScrollView(
                    // 内层滚动
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('图片和链接'), // 新增: 分区标题
                        const SizedBox(height: 16),
                        _buildCoverImageSection(), // 调用: 封面图区域
                        const SizedBox(height: 24),
                        _buildGameImagesSection(), // 调用: 截图区域
                        const SizedBox(height: 24),
                        _buildDownloadLinksField(), // 调用: 下载链接
                        const SizedBox(height: 24),
                        _buildMusicUrlField(), // 调用: 音乐链接
                        const SizedBox(height: 16), // 底部留白
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 右侧面板 (文本信息)
            Expanded(
              flex: 6,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: desktopCardHeight),
                  child: SingleChildScrollView(
                    // 内层滚动
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('游戏信息'), // 新增: 分区标题
                        const SizedBox(height: 16),
                        _buildTitleField(), // 调用: 标题
                        const SizedBox(height: 16),
                        _buildSummaryField(), // 调用: 简介
                        const SizedBox(height: 16),
                        _buildDescriptionField(), // 调用: 描述
                        const SizedBox(height: 24),
                        Row(
                          // 分类和评分 (保持行布局)
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildCategorySection()), // 调用: 分类区域
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTagsField(), // 调用: 标签
                        const SizedBox(height: 32),
                        Center(
                          // 预览和提交按钮 (保持居中和行布局)
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPreviewButton(),
                              const SizedBox(width: 16),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16), // 底部留白
                      ],
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

  // --- 移动布局构建方法 (Refactored) ---
  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      // 使用 ListView 保持移动端原有滚动行为
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 16), // 顶部留白
        _buildCoverImageSection(), // 调用: 封面图区域
        const SizedBox(height: 16),
        _buildTitleField(), // 调用: 标题
        const SizedBox(height: 16),
        _buildSummaryField(), // 调用: 简介
        const SizedBox(height: 16),
        _buildDescriptionField(), // 调用: 描述
        const SizedBox(height: 16),
        _buildMusicUrlField(), // 调用: 音乐链接
        const SizedBox(height: 16),
        _buildCategorySection(), // 调用: 分类区域
        const SizedBox(height: 16),
        _buildTagsField(), // 调用: 标签
        const SizedBox(height: 16),
        _buildDownloadLinksField(), // 调用: 下载链接
        const SizedBox(height: 16),
        _buildGameImagesSection(), // 调用: 截图区域
        const SizedBox(height: 24),
        _buildPreviewButton(), // 调用: 预览按钮 (移动端单独一行)
        const SizedBox(height: 16),
        _buildSubmitButton(), // 调用: 提交按钮 (移动端单独一行)
        const SizedBox(height: 16), // 底部留白
      ],
    );
  }

  // --- Reusable Field Builders ---

  // 新增: 分区标题构建方法
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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

  // 构建封面图区域 (包含错误提示)
  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoverImageField(
          coverImageSource: _coverImageSource,
          onChanged: _handleCoverImageChange,
          isLoading: _isLoading,
        ),
        if (_coverImageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_coverImageError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  // 构建标题字段
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '游戏标题',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.games)),
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入游戏标题' : null,
    );
  }

  // 构建简介字段
  Widget _buildSummaryField() {
    return TextFormField(
      controller: _summaryController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '游戏简介',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.short_text)),
      maxLines: 2,
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入游戏简介' : null,
    );
  }

  // 构建描述字段
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '详细描述',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
          prefixIcon: Icon(Icons.description)),
      maxLines: DeviceUtils.isDesktop ? 6 : 5, // 保持原有的行数差异
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入详细描述' : null,
    );
  }

  // 构建音乐链接字段
  Widget _buildMusicUrlField() {
    return TextFormField(
      controller: _musicUrlController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '背景音乐链接(可选)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.music_note)),
      // 可选字段通常不需要 validator
    );
  }

  // 构建分类区域 (包含错误提示)
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryField(
          selectedCategories: _selectedCategories,
          onChanged: (categories) => setState(() {
            _selectedCategories = categories;
            if (categories.isNotEmpty) _categoryError = null;
          }),
        ),
        if (_categoryError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_categoryError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  // 构建标签字段
  Widget _buildTagsField() {
    return TagsField(
      tags: _selectedTags,
      onChanged: (tags) => setState(() => _selectedTags = tags),
    );
  }

  // 构建下载链接字段
  Widget _buildDownloadLinksField() {
    return DownloadLinksField(
      downloadLinks: _downloadLinks,
      onChanged: (links) => setState(() => _downloadLinks = links),
    );
  }

  // 构建游戏截图区域
  Widget _buildGameImagesSection() {
    return GameImagesField(
      gameImagesSources: _gameImagesSources,
      onChanged: _handleGameImagesChange,
      isLoading: _isLoading,
    );
  }

  Widget _buildSubmitButton() {
    return AppButton(
      onPressed: _submitForm,
      isLoading: _isLoading,
      text: widget.game == null ? '添加游戏' : '保存修改',
      isPrimaryAction: true,
      icon: Icon(widget.game == null
          ? Icons.add_circle_outline
          : Icons.save_alt_outlined),
      isMini: false, // 保持原有设置
    );
  }

  Widget _buildPreviewButton() {
    // 准备给预览组件的数据，预览通常只能显示 URL

    // 1. 处理封面图用于预览
    String? previewCoverUrl;
    if (_coverImageSource is String && (_coverImageSource as String).isNotEmpty) {
      // 如果是有效的 URL 字符串，直接用
      previewCoverUrl = _coverImageSource as String;
    }
    // 如果是 XFile 或 null/空字符串，则不传递 URL 给预览 (预览组件需处理 null 情况)

    // 2. 处理游戏截图用于预览
    List<String> previewImageUrls = _gameImagesSources
        .whereType<String>() // 只筛选出 String 类型的 URL
        .where((url) => url.isNotEmpty) // 确保 URL 非空
        .toList();
    // 本地选择的 XFile 不会包含在预览的图片列表中

    // 3. 构建预览按钮，传递处理后的数据
    return GamePreviewButton(
      // 基本信息控制器
      titleController: _titleController,
      summaryController: _summaryController,
      descriptionController: _descriptionController,
      // 图像信息 (只传 URL)
      coverImageUrl: previewCoverUrl,   // 可能为 null
      gameImages: previewImageUrls,     // 只包含 URL 的列表
      // 其他信息
      selectedCategories: _selectedCategories,
      selectedTags: _selectedTags,
      rating: widget.game?.rating ?? 0.0, // 使用现有评分或默认值
      downloadLinks: _downloadLinks,
      musicUrl: _musicUrlController.text.trim(),
      existingGame: widget.game,
      // 可选: 告知预览组件是否有本地文件未显示
      // hasLocalImages: _coverImageSource is XFile || _gameImagesSources.any((s) => s is XFile),
    );
  }
}
