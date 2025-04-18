// lib/widgets/components/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

// --- 核心依赖 ---
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/form/game_form_cache_service.dart';
import 'package:suxingchahui/services/common/upload/file_upload_service.dart';
import 'package:suxingchahui/services/utils/request_lock_service.dart'; // <--- 引入全局锁服务
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // <--- 引入提示框

// --- UI 和辅助组件 ---
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'field/category_field.dart';
import 'field/cover_image_field.dart';
import 'field/download_links_field.dart';
import 'field/game_images_field.dart';
import 'field/tags_field.dart';
import 'preview/game_preview_button.dart';

class GameForm extends StatefulWidget {
  final Game? game; // 编辑时传入的游戏对象
  final Function(Game) onSubmit; // 提交成功后的回调

  const GameForm({
    Key? key,
    this.game,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _GameFormState createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> with WidgetsBindingObserver {
  // --- 表单和控制器 ---
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musicUrlController = TextEditingController();

  // --- 图片状态 ---
  dynamic _coverImageSource; // String? (URL) 或 XFile? (本地文件)
  List<dynamic> _gameImagesSources = []; // List<String or XFile>
  // final Set<String> _deletedOriginalImageUrls = {}; // 如果你需要跟踪删除的旧图，保留这个

  // --- 其他表单状态 ---
  List<DownloadLink> _downloadLinks = [];
  double _rating = 0.0; // 评分可能不需要在这里处理，除非表单内有评分组件
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];

  // --- 状态标志 ---
  bool _isProcessing = false; // <--- 本地状态：控制 UI 加载指示和按钮禁用
  bool _isDraftRestored = false;
  // 移除 _isLoading 和 _isSubmitting，统一使用 _isProcessing

  // --- 验证错误信息 ---
  String? _coverImageError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFormData();
    _checkAndRestoreDraft();
  }

  @override
  void dispose() {
    // 只有在非处理状态下才保存草稿
    if (!_isProcessing) {
      _saveDraft();
    }
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _musicUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_isProcessing) {
        _saveDraft();
      }
    }
  }

  // --- 初始化表单数据 (编辑或空表单) ---
  void _initializeFormData() {
    // 重置所有状态
    _coverImageSource = null;
    _gameImagesSources = [];
    // _deletedOriginalImageUrls.clear();
    _downloadLinks = [];
    _rating = 0.0;
    _selectedCategories = [];
    _selectedTags = [];
    _isProcessing = false; // 确保初始状态不是处理中
    _coverImageError = null;
    _categoryError = null;
    _titleController.clear();
    _summaryController.clear();
    _descriptionController.clear();
    _musicUrlController.clear();

    // 如果是编辑模式，加载现有数据
    if (widget.game != null) {
      final game = widget.game!;
      _titleController.text = game.title;
      _summaryController.text = game.summary;
      _descriptionController.text = game.description;
      _musicUrlController.text = game.musicUrl ?? '';
      _coverImageSource = game.coverImage;
      _gameImagesSources = List.from(game.images); // 确保是可修改列表
      _downloadLinks = List.from(game.downloadLinks); // 确保是可修改列表
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
        print('初始化标签时出错: $e');
      }
    }
  }

  // --- 草稿相关方法 (保持不变) ---
  Future<void> _checkAndRestoreDraft() async {
    if (widget.game != null || _isDraftRestored) return;
    bool hasDraft = await GameFormCacheService().hasDraft();
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
                _isDraftRestored = true;
              });
              AppSnackBar.showSuccess(context, '草稿已恢复');
            }
            // CustomConfirmDialog 内部会自动 pop
          },
          onCancel: () async {
            await GameFormCacheService().clearDraft();
            print("User chose to discard the draft.");
            // CustomConfirmDialog 内部会自动 pop
          },
        );
      } catch (e) {
        print("Error showing/handling restore draft dialog: $e");
        if (mounted) AppSnackBar.showError(context, '处理草稿时出错');
        await GameFormCacheService().clearDraft();
      }
    }
  }

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
            .map((map) => DownloadLink.fromJson(map))
            .toList();
        _coverImageSource = draft.coverImageUrl; // 只恢复 URL
        _gameImagesSources = List<dynamic>.from(draft.gameImageUrls); // 只恢复 URL
        _coverImageError = null;
        _categoryError = null;
      });
      print("Draft applied to form state.");
    } else if (draft == null) {
      print("Could not load draft or draft was null.");
    }
  }

  Future<void> _saveDraft() async {
    if (_isFormEmpty() || _isProcessing) {
      // 正在处理时不保存
      print("Form is empty or processing, skipping draft save.");
      return;
    }
    String? coverImageUrl;
    if (_coverImageSource is String)
      coverImageUrl = _coverImageSource as String;
    List<String> gameImageUrls =
        _gameImagesSources.whereType<String>().toList();

    final draft = GameFormDraft(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      description: _descriptionController.text.trim(),
      musicUrl: _musicUrlController.text.trim().isEmpty
          ? null
          : _musicUrlController.text.trim(),
      coverImageUrl: coverImageUrl,
      gameImageUrls: gameImageUrls,
      downloadLinks: _downloadLinks.map((link) => link.toJson()).toList(),
      selectedCategories: _selectedCategories,
      selectedTags: _selectedTags,
      lastSaved: DateTime.now(),
    );
    await GameFormCacheService().saveDraft(draft);
    print("Draft saved on dispose/pause.");
  }

  bool _isFormEmpty() {
    return _titleController.text.trim().isEmpty &&
        _summaryController.text.trim().isEmpty &&
        _descriptionController.text.trim().isEmpty &&
        _musicUrlController.text.trim().isEmpty &&
        (_coverImageSource == null ||
            (_coverImageSource is String &&
                (_coverImageSource as String).isEmpty)) &&
        _gameImagesSources
            .where((s) => (s is String && s.isNotEmpty) || s is XFile)
            .isEmpty &&
        _downloadLinks.isEmpty &&
        _selectedCategories.isEmpty &&
        _selectedTags.isEmpty;
  }

  // --- 表单验证 ---
  bool _validateForm() {
    bool isValid = _formKey.currentState?.validate() ?? false;
    bool hasCover = _coverImageSource != null &&
        !(_coverImageSource is String && (_coverImageSource as String).isEmpty);
    bool hasCategory = _selectedCategories.isNotEmpty;

    // 使用 setState 更新错误信息，这样 UI 会响应
    setState(() {
      _coverImageError = hasCover ? null : '请添加封面图片';
      _categoryError = hasCategory ? null : '请选择至少一个分类';
    });

    return isValid && hasCover && hasCategory;
  }

  // --- 图片处理回调 (保持不变) ---
  void _handleCoverImageChange(dynamic newSource) {
    setState(() {
      _coverImageSource = newSource;
      if (_coverImageSource != null &&
          !(_coverImageSource is String &&
              (_coverImageSource as String).isEmpty)) {
        _coverImageError = null; // 清除错误提示
      }
    });
  }

  void _handleGameImagesChange(List<dynamic> newSourcesList) {
    setState(() {
      _gameImagesSources = newSourcesList;
    });
  }

  // --- 辅助方法：获取操作 Key ---
  String? _getOperationKey() {
    if (widget.game == null) {
      return 'add_game'; // 添加操作
    } else if (widget.game?.id != null) {
      return 'edit_game_${widget.game!.id}'; // 编辑操作，带 ID
    } else {
      print(
          "Error: Cannot determine operation key, game ID is null in edit mode.");
      return null; // 异常情况
    }
  }

  // --- 核心提交逻辑 ---
  Future<void> _submitForm() async {
    // 1. 表单验证
    if (!_validateForm()) {
      if (mounted) AppSnackBar.showError(context, '请检查表单中的错误并修正');
      return;
    }

    final operationKey = _getOperationKey();
    if (operationKey == null) {
      if (mounted) AppSnackBar.showError(context, '内部错误：无法提交');
      return;
    }

    // 2. 设置本地处理状态，用于 UI 反馈
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    // 3. 使用全局锁执行实际操作
    bool actionExecuted = await RequestLockService.instance.tryLockAsync(
      operationKey,
      action: () async {
        // ============================================
        // 开始核心操作 (上传文件、构建对象、调用回调)
        // ============================================
        String? finalCoverImageUrl;
        List<String> finalGameImagesUrls = [];

        try {
          // 3a. 处理封面图上传 (如果需要)
          final dynamic currentCoverSource = _coverImageSource;
          if (currentCoverSource is XFile) {
            print("Uploading new cover image...");
            final fileToUpload = File(currentCoverSource.path);
            // 假设 FileUpload.uploadImage 是异步的
            finalCoverImageUrl = await FileUpload.uploadImage(
              fileToUpload,
              folder: 'games/covers',
              // oldImageUrl: (widget.game?.coverImage?.startsWith('http') ?? false) ? widget.game!.coverImage : null, // 如果需要传递旧 URL 给后端
            );
            print("New cover URL: $finalCoverImageUrl");
          } else if (currentCoverSource is String &&
              currentCoverSource.isNotEmpty) {
            finalCoverImageUrl = currentCoverSource; // 使用现有 URL
          } else {
            finalCoverImageUrl = ''; // 没有封面图
          }

          // 3b. 处理游戏截图上传 (如果需要)
          final List<dynamic> currentImageSources =
              List.from(_gameImagesSources);
          final List<File> filesToUpload = [];
          final List<int> xFileIndices = [];
          final List<String> existingUrls = []; // 保留现有 URL

          for (int i = 0; i < currentImageSources.length; i++) {
            if (currentImageSources[i] is XFile) {
              filesToUpload.add(File((currentImageSources[i] as XFile).path));
              xFileIndices.add(i); // 记下 XFile 的位置
            } else if (currentImageSources[i] is String &&
                (currentImageSources[i] as String).isNotEmpty) {
              // existingUrls.add(currentImageSources[i] as String); // 不需要单独收集，后面直接用
            }
          }

          List<String> uploadedUrls = [];
          if (filesToUpload.isNotEmpty) {
            print("Uploading ${filesToUpload.length} new screenshots...");
            // 假设 FileUpload.uploadFiles 是异步的
            uploadedUrls = await FileUpload.uploadFiles(
              filesToUpload,
              folder: 'games/screenshots',
            );
            if (uploadedUrls.length != filesToUpload.length) {
              throw Exception("Screenshot upload count mismatch!");
            }
            print("New screenshot URLs: $uploadedUrls");
          }

          // 构建最终 URL 列表，保持原始顺序
          List<String?> orderedUrlsPlaceholder =
              List.filled(currentImageSources.length, null);
          int uploadedUrlIndex = 0;
          for (int i = 0; i < currentImageSources.length; i++) {
            final source = currentImageSources[i];
            if (xFileIndices.contains(i)) {
              if (uploadedUrlIndex < uploadedUrls.length) {
                orderedUrlsPlaceholder[i] = uploadedUrls[uploadedUrlIndex++];
              }
            } else if (source is String && source.isNotEmpty) {
              orderedUrlsPlaceholder[i] = source;
            }
          }
          finalGameImagesUrls =
              orderedUrlsPlaceholder.whereType<String>().toList();
          print(
              "Final submitted screenshot URLs (${finalGameImagesUrls.length}): $finalGameImagesUrls");

          // 3c. 构建 Game 对象
          final game = Game(
            id: widget.game?.id ?? mongo.ObjectId().toHexString(),
            authorId: widget.game?.authorId ??
                'GET_CURRENT_USER_ID()', // TODO: 替换为实际用户ID
            title: _titleController.text.trim(),
            summary: _summaryController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategories.join(', '),
            coverImage: finalCoverImageUrl ?? '',
            images: finalGameImagesUrls,
            tags: _selectedTags,
            rating: widget.game?.rating ?? 0.0,
            createTime: widget.game?.createTime ?? DateTime.now(),
            updateTime: DateTime.now(), // 总是更新时间
            viewCount: widget.game?.viewCount ?? 0,
            likeCount: widget.game?.likeCount ?? 0,
            likedBy: widget.game?.likedBy ?? [],
            downloadLinks: _downloadLinks,
            musicUrl: _musicUrlController.text.trim().isEmpty
                ? null
                : _musicUrlController.text.trim(),
            lastViewedAt: widget.game?.lastViewedAt,
            // approvalStatus 等由后端处理
          );

          // 3d. 调用外部 onSubmit 回调 (执行 API 请求)
          print("Calling widget.onSubmit for operation $operationKey...");
          await widget.onSubmit(game); // 等待 API 调用完成
          print("widget.onSubmit for $operationKey completed.");

          // 3e. 清除草稿 (只有在 action 完全成功后才清除)
          await GameFormCacheService().clearDraft();
          print(
              "Local draft cleared after successful submission of $operationKey.");
        } catch (e) {
          // action 内部错误处理
          print('Error during submission action ($operationKey): $e');
          if (mounted) {
            AppSnackBar.showError(context, '提交处理失败: ${e.toString()}');
          }
          // 必须重新抛出，让 tryLockAsync 知道出错了
          rethrow;
        }
        // ============================================
        // 核心操作结束
        // ============================================
      },
      onLockFailed: () {
        // 锁定时（操作已在进行中）的回调
        print("Operation ($operationKey) is already in progress.");
        if (mounted) {
          AppSnackBar.showInfo(context, '操作正在进行中，请稍候...');
        }
      },
    );

    // 4. 无论 tryLockAsync 结果如何，最后都重置本地处理状态
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    // actionExecuted 会告诉你 action 是否被执行（即是否成功获取到锁）
    if (actionExecuted) {
      print("Submission action attempt finished for $operationKey.");
      // 成功的 SnackBar 应该由调用方 (Add/Edit Screen) 在 onSubmit 回调成功后显示
    }
  }

  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    // 使用 Stack 包裹，方便显示全局加载指示器
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: useDesktopLayout
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
        // 使用 _isProcessing 控制 LoadingWidget.inline 的显示
        if (_isProcessing) LoadingWidget.inline(),
      ],
    );
  }

  // --- 桌面布局构建 (保持不变，但调用修改后的字段构建器) ---
  Widget _buildDesktopLayout(BuildContext context) {
    final desktopCardHeight = MediaQuery.of(context).size.height - 100;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: desktopCardHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('图片和链接'),
                        const SizedBox(height: 16),
                        _buildCoverImageSection(), // 使用带错误提示的版本
                        const SizedBox(height: 24),
                        _buildGameImagesSection(),
                        const SizedBox(height: 24),
                        _buildDownloadLinksField(),
                        const SizedBox(height: 24),
                        _buildMusicUrlField(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(maxHeight: desktopCardHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('游戏信息'),
                        const SizedBox(height: 16),
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildSummaryField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),
                        _buildCategorySection(), // 使用带错误提示的版本
                        const SizedBox(height: 24),
                        _buildTagsField(),
                        const SizedBox(height: 32),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPreviewButton(), // 预览按钮
                              const SizedBox(width: 16),
                              _buildSubmitButton(), // 提交按钮
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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

  // --- 移动布局构建 (保持不变，但调用修改后的字段构建器) ---
  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 16),
        _buildCoverImageSection(), // 使用带错误提示的版本
        const SizedBox(height: 16),
        _buildTitleField(),
        const SizedBox(height: 16),
        _buildSummaryField(),
        const SizedBox(height: 16),
        _buildDescriptionField(),
        const SizedBox(height: 16),
        _buildMusicUrlField(),
        const SizedBox(height: 16),
        _buildCategorySection(), // 使用带错误提示的版本
        const SizedBox(height: 16),
        _buildTagsField(),
        const SizedBox(height: 16),
        _buildDownloadLinksField(),
        const SizedBox(height: 16),
        _buildGameImagesSection(),
        const SizedBox(height: 24),
        _buildPreviewButton(), // 预览按钮
        const SizedBox(height: 16),
        _buildSubmitButton(), // 提交按钮
        const SizedBox(height: 16),
      ],
    );
  }

  // --- 可重用字段构建器 ---

  // 分区标题
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

  // 封面图区域 (带错误提示)
  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoverImageField(
          coverImageSource: _coverImageSource,
          onChanged: _handleCoverImageChange,
          isLoading: _isProcessing, // 使用 _isProcessing
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

  // 标题字段
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

  // 简介字段
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

  // 描述字段
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '详细描述',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
          prefixIcon: Icon(Icons.description)),
      maxLines: DeviceUtils.isDesktop ? 6 : 5,
      validator: (value) => value?.trim().isEmpty ?? true ? '请输入详细描述' : null,
    );
  }

  // 音乐链接字段
  Widget _buildMusicUrlField() {
    return TextFormField(
      controller: _musicUrlController,
      style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
      decoration: const InputDecoration(
          labelText: '背景音乐链接(可选)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.music_note)),
    );
  }

  // 分类区域 (带错误提示)
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryField(
          selectedCategories: _selectedCategories,
          onChanged: (categories) => setState(() {
            _selectedCategories = categories;
            if (categories.isNotEmpty) _categoryError = null; // 清除错误
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

  // 标签字段
  Widget _buildTagsField() {
    return TagsField(
      tags: _selectedTags,
      onChanged: (tags) => setState(() => _selectedTags = tags),
    );
  }

  // 下载链接字段
  Widget _buildDownloadLinksField() {
    return DownloadLinksField(
      downloadLinks: _downloadLinks,
      onChanged: (links) => setState(() => _downloadLinks = links),
    );
  }

  // 游戏截图区域
  Widget _buildGameImagesSection() {
    return GameImagesField(
      gameImagesSources: _gameImagesSources,
      onChanged: _handleGameImagesChange,
      isLoading: _isProcessing, // 使用 _isProcessing
    );
  }

  // --- 构建提交按钮 (使用 _isProcessing 控制状态) ---
  Widget _buildSubmitButton() {
    // 按钮是否可用取决于本地 _isProcessing 状态
    bool canPress = !_isProcessing;

    return AppButton(
      // 当 _isProcessing 为 true 时，onPressed 为 null 来禁用
      onPressed: canPress ? _submitForm : null,
      // isLoading 控制按钮内部是否显示加载指示器
      isLoading: _isProcessing,
      text: widget.game == null ? '添加游戏' : '保存修改',
      isPrimaryAction: true,
      icon: Icon(widget.game == null
          ? Icons.add_circle_outline
          : Icons.save_alt_outlined),
      isMini: false,
    );
  }

  // --- 构建预览按钮 (逻辑不变) ---
  Widget _buildPreviewButton() {
    String? previewCoverUrl;
    if (_coverImageSource is String &&
        (_coverImageSource as String).isNotEmpty) {
      previewCoverUrl = _coverImageSource as String;
    }
    List<String> previewImageUrls = _gameImagesSources
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();

    return GamePreviewButton(
      titleController: _titleController,
      summaryController: _summaryController,
      descriptionController: _descriptionController,
      coverImageUrl: previewCoverUrl,
      gameImages: previewImageUrls,
      selectedCategories: _selectedCategories,
      selectedTags: _selectedTags,
      rating: widget.game?.rating ?? 0.0,
      downloadLinks: _downloadLinks,
      musicUrl: _musicUrlController.text.trim(),
      existingGame: widget.game,
    );
  }
} // _GameFormState 结束
