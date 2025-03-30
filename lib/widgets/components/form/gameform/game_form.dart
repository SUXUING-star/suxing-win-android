// lib/widgets/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart'; // 确保路径正确
import 'dart:async';

import '../../../../models/game/game.dart'; // 确保路径正确
import '../../../../services/common/upload/file_upload_service.dart'; // 确保路径正确
import '../../../../utils/device/device_utils.dart'; // 确保路径正确
import '../../../../utils/font/font_config.dart'; // 确保路径正确
import 'common/loading_overlay.dart'; // 确保路径正确
import 'field/category_field.dart'; // 确保路径正确
import 'field/cover_image_field.dart'; // 确保路径正确
import 'field/download_links_field.dart'; // 确保路径正确
import 'field/game_images_field.dart'; // 确保路径正确
import 'field/rating_field.dart'; // 确保路径正确
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

class _GameFormState extends State<GameForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musicUrlController = TextEditingController();

  // --- 图片状态变量 ---
  dynamic _coverImageSource; // String? (URL) 或 XFile? (本地文件)
  List<dynamic> _gameImagesSources = []; // List<String or XFile>
  String? _originalCoverImageUrl;
  List<String> _originalGameImagesUrls = [];
  final Set<String> _deletedOriginalImageUrls = {};
  // --- 图片状态变量结束 ---

  List<DownloadLink> _downloadLinks = [];
  double _rating = 0.0;
  bool _isLoading = false;
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];

  String? _coverImageError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _musicUrlController.dispose();
    _runDeferredDeletion();
    super.dispose();
  }

  Future<void> _runDeferredDeletion() async {
    // (保持不变)
    final urlsToDelete = Set<String>.from(_deletedOriginalImageUrls);
    if (urlsToDelete.isNotEmpty) {
      print("[GameForm Cleanup] Deleting ${urlsToDelete.length} original URLs marked for deletion.");
      List<Future<void>> deleteFutures = [];
      for (String url in urlsToDelete) {
        deleteFutures.add(FileUpload.deleteFile(url).catchError((e) {
          print("[GameForm Cleanup] Error deleting $url: $e");
        }));
      }
      try {
        await Future.wait(deleteFutures);
        print("[GameForm Cleanup] Finished deletion attempts.");
      } catch (e) {
        print("[GameForm Cleanup] Error during waiting for deletions: $e");
      }
      _deletedOriginalImageUrls.clear();
    }
  }

  void _initializeFormData() {
    // (保持不变)
    _coverImageSource = null;
    _gameImagesSources = [];
    _originalCoverImageUrl = null;
    _originalGameImagesUrls = [];
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
      _originalCoverImageUrl = game.coverImage;
      _coverImageSource = game.coverImage;
      _originalGameImagesUrls = List.from(game.images);
      _gameImagesSources = List.from(game.images);
      _downloadLinks = List.from(game.downloadLinks);
      _rating = game.rating;
      _selectedCategories = game.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      try {
        _selectedTags = game.tags != null ? List.from(game.tags!) : [];
      } catch (e) { _selectedTags = []; print('初始化标签时出错: $e'); }
    }
  }

  bool _validateForm() {
    // (保持不变)
    bool isValid = _formKey.currentState?.validate() ?? false;

    if (_coverImageSource == null || (_coverImageSource is String && (_coverImageSource as String).isEmpty)) {
      setState(() { _coverImageError = '请添加封面图片'; });
      isValid = false;
    } else {
      setState(() { _coverImageError = null; });
    }

    if (_selectedCategories.isEmpty) {
      setState(() { _categoryError = '请选择至少一个分类'; });
      isValid = false;
    } else {
      setState(() { _categoryError = null; });
    }

    return isValid;
  }

  Future<void> _submitForm() async {
    // (保持不变 - 核心逻辑与之前相同)
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请检查表单中的错误并修正'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() { _isLoading = true; });

    String? finalCoverImageUrl;
    List<String> finalGameImagesUrls = [];
    String? errorMessage;

    try {
      // 2. 处理封面图片上传
      if (_coverImageSource is XFile) {
        final fileToUpload = File((_coverImageSource as XFile).path);
        String? oldUrlToReplace;
        if (_originalCoverImageUrl != null && _originalCoverImageUrl!.isNotEmpty && _coverImageSource != _originalCoverImageUrl) {
          oldUrlToReplace = _originalCoverImageUrl;
          _deletedOriginalImageUrls.remove(oldUrlToReplace);
        }
        finalCoverImageUrl = await FileUpload.uploadImage(
          fileToUpload,
          folder: 'games/covers',
          oldImageUrl: oldUrlToReplace,
        );
      } else if (_coverImageSource is String) {
        finalCoverImageUrl = _coverImageSource as String;
      } else { throw Exception("封面图片源无效"); }

      // 3. 处理游戏截图上传
      List<File> screenshotFilesToUpload = [];
      List<int> uploadIndices = [];
      for (int i = 0; i < _gameImagesSources.length; i++) {
        if (_gameImagesSources[i] is XFile) {
          screenshotFilesToUpload.add(File((_gameImagesSources[i] as XFile).path));
          uploadIndices.add(i);
        }
      }

      List<String> uploadedScreenshotUrls = [];
      if (screenshotFilesToUpload.isNotEmpty) {
        uploadedScreenshotUrls = await FileUpload.uploadFiles(
          screenshotFilesToUpload,
          folder: 'games/screenshots',
        );
        if (uploadedScreenshotUrls.length != screenshotFilesToUpload.length) {
          throw Exception("上传截图数量与返回URL数量不匹配");
        }
      }

      // 合并URL列表
      List<String?> tempUrls = List<String?>.filled(_gameImagesSources.length, null);
      int uploadedIdx = 0;
      for (int i = 0; i < _gameImagesSources.length; i++) {
        if (uploadIndices.contains(i)) {
          if (uploadedIdx < uploadedScreenshotUrls.length) {
            tempUrls[i] = uploadedScreenshotUrls[uploadedIdx++];
          }
        } else if (_gameImagesSources[i] is String) {
          tempUrls[i] = _gameImagesSources[i] as String;
        }
      }
      finalGameImagesUrls = tempUrls.whereType<String>().toList();

      // 4. 处理已标记删除的原始图片
      final urlsToDeleteImmediately = Set<String>.from(_deletedOriginalImageUrls);
      if (urlsToDeleteImmediately.isNotEmpty) {
        print("正在删除 ${urlsToDeleteImmediately.length} 个标记为删除的原始图片...");
        List<Future<bool>> deleteFutures = [];
        for (final url in urlsToDeleteImmediately) {
          deleteFutures.add(FileUpload.deleteFile(url));
        }
        await Future.wait(deleteFutures);
        _deletedOriginalImageUrls.clear();
        print("删除完成。");
      }

      // 5. 构建最终的 Game 对象
      final game = Game(
        id: widget.game?.id ?? mongo.ObjectId().toHexString(),
        authorId: widget.game?.authorId ?? '', // TODO: 确保 authorId 在实际使用中有来源
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategories.join(', '),
        coverImage: finalCoverImageUrl ?? '',
        images: finalGameImagesUrls,
        tags: _selectedTags,
        rating: _rating,
        viewCount: widget.game?.viewCount ?? 0,
        createTime: widget.game?.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
        likeCount: widget.game?.likeCount ?? 0,
        likedBy: widget.game?.likedBy ?? [],
        downloadLinks: _downloadLinks,
        musicUrl: _musicUrlController.text.trim().isEmpty ? null : _musicUrlController.text.trim(),
        lastViewedAt: widget.game?.lastViewedAt,
      );

      // 6. 调用外部提交函数
      widget.onSubmit(game);
      _deletedOriginalImageUrls.clear(); // 确保清理
      print("表单数据提交成功！");

    } catch (e) {
      errorMessage = '处理图片或提交表单时出错: $e';
      print(errorMessage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }


  void _handleCoverImageChange(dynamic newSource) {
    // (保持不变)
    setState(() {
      final previousSource = _coverImageSource;
      _coverImageSource = newSource;

      if (_originalCoverImageUrl != null && _originalCoverImageUrl!.isNotEmpty) {
        if (previousSource == _originalCoverImageUrl && newSource != _originalCoverImageUrl) {
          _deletedOriginalImageUrls.add(_originalCoverImageUrl!);
        } else if (newSource == _originalCoverImageUrl) {
          _deletedOriginalImageUrls.remove(_originalCoverImageUrl!);
        }
      }
      if (_coverImageSource != null && !(_coverImageSource is String && (_coverImageSource as String).isEmpty)) {
        _coverImageError = null;
      }
    });
  }


  void _handleGameImagesChange(List<dynamic> newSourcesList) {
    // (保持不变)
    setState(() {
      final Set<String> currentUrlsInNewList = newSourcesList.whereType<String>().toSet();
      for (final originalUrl in _originalGameImagesUrls) {
        if (!currentUrlsInNewList.contains(originalUrl)) {
          if (!_deletedOriginalImageUrls.contains(originalUrl)) {
            _deletedOriginalImageUrls.add(originalUrl);
          }
        } else {
          if (_deletedOriginalImageUrls.contains(originalUrl)) {
            _deletedOriginalImageUrls.remove(originalUrl);
          }
        }
      }
      _gameImagesSources = newSourcesList;
    });
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
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  // --- 桌面布局构建方法 (Refactored) ---
  Widget _buildDesktopLayout(BuildContext context) {
    final desktopCardHeight = MediaQuery.of(context).size.height - 100; // 保持原有计算方式
    return SingleChildScrollView( // 使用 SingleChildScrollView 替代 ListView 保持桌面原有滚动行为
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
                  child: SingleChildScrollView( // 内层滚动
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('图片和链接'), // 新增: 分区标题
                        const SizedBox(height: 16),
                        _buildCoverImageSection(),     // 调用: 封面图区域
                        const SizedBox(height: 24),
                        _buildGameImagesSection(),     // 调用: 截图区域
                        const SizedBox(height: 24),
                        _buildDownloadLinksField(),    // 调用: 下载链接
                        const SizedBox(height: 24),
                        _buildMusicUrlField(),         // 调用: 音乐链接
                        const SizedBox(height: 16),    // 底部留白
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
                  child: SingleChildScrollView( // 内层滚动
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('游戏信息'), // 新增: 分区标题
                        const SizedBox(height: 16),
                        _buildTitleField(),            // 调用: 标题
                        const SizedBox(height: 16),
                        _buildSummaryField(),          // 调用: 简介
                        const SizedBox(height: 16),
                        _buildDescriptionField(),      // 调用: 描述
                        const SizedBox(height: 24),
                        Row( // 分类和评分 (保持行布局)
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildCategorySection()), // 调用: 分类区域
                            const SizedBox(width: 16),
                            Expanded(child: _buildRatingField()),     // 调用: 评分
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTagsField(),             // 调用: 标签
                        const SizedBox(height: 32),
                        Center( // 预览和提交按钮 (保持居中和行布局)
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
    return ListView( // 使用 ListView 保持移动端原有滚动行为
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 16), // 顶部留白
        _buildCoverImageSection(),     // 调用: 封面图区域
        const SizedBox(height: 16),
        _buildTitleField(),            // 调用: 标题
        const SizedBox(height: 16),
        _buildSummaryField(),          // 调用: 简介
        const SizedBox(height: 16),
        _buildDescriptionField(),      // 调用: 描述
        const SizedBox(height: 16),
        _buildMusicUrlField(),         // 调用: 音乐链接
        const SizedBox(height: 16),
        _buildCategorySection(),       // 调用: 分类区域
        const SizedBox(height: 16),
        _buildTagsField(),             // 调用: 标签
        const SizedBox(height: 16),
        _buildDownloadLinksField(),    // 调用: 下载链接
        const SizedBox(height: 16),
        _buildRatingField(),           // 调用: 评分
        const SizedBox(height: 16),
        _buildGameImagesSection(),     // 调用: 截图区域
        const SizedBox(height: 24),
        _buildPreviewButton(),         // 调用: 预览按钮 (移动端单独一行)
        const SizedBox(height: 16),
        _buildSubmitButton(),          // 调用: 提交按钮 (移动端单独一行)
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
        if (_coverImageError != null) Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(_coverImageError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
      ],
    );
  }

  // 构建标题字段
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(labelText: '游戏标题', border: OutlineInputBorder(), prefixIcon: Icon(Icons.games)),
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入游戏标题' : null,
    );
  }

  // 构建简介字段
  Widget _buildSummaryField() {
    return TextFormField(
      controller: _summaryController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(labelText: '游戏简介', border: OutlineInputBorder(), prefixIcon: Icon(Icons.short_text)),
      maxLines: 2,
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入游戏简介' : null,
    );
  }

  // 构建描述字段
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(labelText: '详细描述', border: OutlineInputBorder(), alignLabelWithHint: true, prefixIcon: Icon(Icons.description)),
      maxLines: DeviceUtils.isDesktop ? 6 : 5, // 保持原有的行数差异
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入详细描述' : null,
    );
  }

  // 构建音乐链接字段
  Widget _buildMusicUrlField() {
    return TextFormField(
      controller: _musicUrlController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(labelText: '背景音乐链接(可选)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.music_note)),
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
        if (_categoryError != null) Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(_categoryError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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

  // 构建评分字段
  Widget _buildRatingField() {
    return RatingField(
      rating: _rating,
      onChanged: (value) => setState(() => _rating = value),
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

  // --- Button Builders (保持不变) ---

  Widget _buildSubmitButton() {
    return AppButton(
      onPressed: _submitForm,
      isLoading: _isLoading,
      text: widget.game == null ? '添加游戏' : '保存修改',
      isPrimaryAction: true,
      icon: Icon(widget.game == null ? Icons.add_circle_outline : Icons.save_alt_outlined),
      isMini: false, // 保持原有设置
    );
  }

  Widget _buildPreviewButton() {
    String? previewCoverUrl = _coverImageSource is String ? _coverImageSource as String : null;
    List<String> previewImageUrls = _gameImagesSources.whereType<String>().toList();

    return GamePreviewButton(
      titleController: _titleController,
      summaryController: _summaryController,
      descriptionController: _descriptionController,
      coverImageUrl: previewCoverUrl,
      gameImages: previewImageUrls,
      selectedCategories: _selectedCategories,
      selectedTags: _selectedTags,
      rating: _rating,
      downloadLinks: _downloadLinks,
      musicUrl: _musicUrlController.text,
      existingGame: widget.game,
    );
  }
}