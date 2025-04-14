// lib/widgets/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart'; // 确保路径正确
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
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

class _GameFormState extends State<GameForm> {
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
    super.dispose();
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
      _selectedCategories = game.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      try {
        _selectedTags = game.tags != null ? List.from(game.tags!) : [];
      } catch (e) { _selectedTags = []; print('初始化标签时出错: $e'); }
    }
  }

  bool _validateForm() {
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
    if (!_validateForm()) {
      AppSnackBar.showError(context, '请检查表单中的错误并修正');
      return;
    }

    setState(() { _isLoading = true; });

    String? finalCoverImageUrl; // 最终提交给后端的封面图 URL
    List<String> finalGameImagesUrls = []; // 最终提交给后端的截图 URL 列表
    String? errorMessage;

    try {
      // 1. 处理封面图片
      // 检查 _coverImageSource 的类型
      if (_coverImageSource is XFile) {
        // 如果是 XFile，表示是新选择/修改的本地文件，需要上传
        final fileToUpload = File((_coverImageSource as XFile).path);
        print("准备上传新的封面图片...");
        // 调用上传服务，不再传递 oldImageUrl 用于前端删除
        finalCoverImageUrl = await FileUpload.uploadImage(
          fileToUpload,
          folder: 'games/covers',
          oldImageUrl: widget.game?.coverImage, // 可选：如果上传服务需要旧URL来替换
        );
        print("新封面图片上传成功，URL: $finalCoverImageUrl");
      } else if (_coverImageSource is String && (_coverImageSource as String).isNotEmpty) {
        // 如果是 String 且非空，表示用户保留了原来的封面图 URL，或选择了一个已存在的 URL
        finalCoverImageUrl = _coverImageSource as String;
        print("保留现有封面图片 URL: $finalCoverImageUrl");
      } else {
        // 如果是 null 或空字符串，表示用户移除了封面图
        finalCoverImageUrl = ''; // 提交空字符串给后端，表示没有封面图
        print("封面图片已被移除");
      }

      // 2. 处理游戏截图
      List<File> screenshotFilesToUpload = []; // 收集需要上传的 XFile
      List<String> existingScreenshotUrls = []; // 收集保留的 String URL
      List<int> sourceIndicesOfFiles = []; // 记录 XFile 在 _gameImagesSources 中的原始索引

      for (int i = 0; i < _gameImagesSources.length; i++) {
        final source = _gameImagesSources[i];
        if (source is XFile) {
          screenshotFilesToUpload.add(File(source.path));
          sourceIndicesOfFiles.add(i); // 记录这个索引对应的是一个待上传文件
        } else if (source is String && source.isNotEmpty) {
          existingScreenshotUrls.add(source); // 收集已存在的有效 URL
        }
        // 忽略 null 或空字符串的情况
      }

      List<String> uploadedScreenshotUrls = []; // 存储新上传成功的 URL
      if (screenshotFilesToUpload.isNotEmpty) {
        print("准备上传 ${screenshotFilesToUpload.length} 张新的游戏截图...");
        // 调用批量上传服务
        uploadedScreenshotUrls = await FileUpload.uploadFiles(
          screenshotFilesToUpload,
          folder: 'games/screenshots',
        );
        if (uploadedScreenshotUrls.length != screenshotFilesToUpload.length) {
          throw Exception("上传截图数量与返回URL数量不匹配");
        }
        print("新截图上传成功，返回 ${uploadedScreenshotUrls.length} 个 URL.");
      } else {
        print("没有新的游戏截图需要上传。");
      }

      // 3. 构建最终的游戏截图 URL 列表 (保持顺序)
      // 创建一个与 _gameImagesSources 同样大小的列表，用于按原始顺序填充 URL
      List<String?> orderedFinalUrls = List<String?>.filled(_gameImagesSources.length, null);
      int uploadedUrlIndex = 0; // 用于从 uploadedScreenshotUrls 中取值

      for (int i = 0; i < _gameImagesSources.length; i++) {
        final source = _gameImagesSources[i];
        if (source is XFile) {
          // 这个位置原来是 XFile，现在应该填充对应的已上传 URL
          if (sourceIndicesOfFiles.contains(i) && uploadedUrlIndex < uploadedScreenshotUrls.length) {
            orderedFinalUrls[i] = uploadedScreenshotUrls[uploadedUrlIndex++];
          }
        } else if (source is String && source.isNotEmpty) {
          // 这个位置原来是 String URL，直接使用
          orderedFinalUrls[i] = source;
        }
      }
      // 过滤掉可能存在的 null 值（例如，如果上传失败或原始状态就是空的）
      finalGameImagesUrls = orderedFinalUrls.whereType<String>().toList();
      print("最终提交的游戏截图 URL 列表 (${finalGameImagesUrls.length} 个): $finalGameImagesUrls");

      // 4. 构建最终的 Game 对象，使用处理后的图片 URL
      final game = Game(
        id: widget.game?.id ?? mongo.ObjectId().toHexString(), // 保留现有ID或生成新ID
        authorId: widget.game?.authorId ?? '', // 确保 authorId 有来源
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategories.join(', '),
        coverImage: finalCoverImageUrl ?? '', // 使用最终封面URL
        images: finalGameImagesUrls,        // 使用最终截图URL列表
        tags: _selectedTags,
        rating: _rating,
        viewCount: widget.game?.viewCount ?? 0,
        createTime: widget.game?.createTime ?? DateTime.now(), // 保留创建时间或用现在
        updateTime: DateTime.now(), // 标记更新时间 (后端也会更新)
        likeCount: widget.game?.likeCount ?? 0,
        likedBy: widget.game?.likedBy ?? [],
        downloadLinks: _downloadLinks,
        musicUrl: _musicUrlController.text.trim().isEmpty ? null : _musicUrlController.text.trim(),
        lastViewedAt: widget.game?.lastViewedAt,
        // 注意: approvalStatus, reviewedAt, reviewedBy 等字段由后端处理，前端不提交
      );

      // 5. 调用外部提交函数，将构建好的 game 对象传递出去
      //print("准备调用 onSubmit 回调函数...");
      widget.onSubmit(game);
      //print("表单数据已提交！");

    } catch (e) {
      errorMessage = '处理图片或提交表单时出错: $e';
      print("发生错误: $errorMessage");
      if (mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } finally {
      // 确保 loading 状态被重置
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  // 当封面图片选择变化时调用
  void _handleCoverImageChange(dynamic newSource) {
    setState(() {
      _coverImageSource = newSource; // 直接更新状态
      // 如果新来源有效，清除错误提示
      if (_coverImageSource != null && !(_coverImageSource is String && (_coverImageSource as String).isEmpty)) {
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