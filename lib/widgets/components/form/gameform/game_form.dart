import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// --- 核心依赖 ---
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/form/game_form_cache_service.dart';
import 'package:suxingchahui/services/utils/request_lock_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

// --- UI 和辅助组件 ---
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'package:uuid/uuid.dart';
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
    super.key,
    this.game,
    required this.onSubmit,
  });

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
  final _bvidController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _summaryFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _musicUrlFocusNode = FocusNode();
  final _bvidFocusNode = FocusNode();

  // --- 图片状态 ---
  // dynamic 可以是 String (URL), XFile (本地文件), 或 null (未选择/草稿占位符恢复)
  dynamic _coverImageSource;
  List<dynamic> _gameImagesSources = []; // List 元素可以是 String, XFile, 或 null

  // --- 其他表单状态 ---
  List<DownloadLink> _downloadLinks = [];
  String? _selectedCategory;
  List<String> _selectedTags = [];

  // --- 状态标志 ---
  bool _isProcessing = false; // 控制 UI 加载和按钮禁用
  bool _isDraftRestored = false; // 标记草稿是否已恢复过一次，避免重复询问

  // --- 验证错误信息 ---
  String? _coverImageError;
  String? _categoryError;

  // --- 草稿相关 ---
  final GameFormCacheService _cacheService = GameFormCacheService();
  String? _draftKey; // 当前表单使用的草稿 Key (add_draft 或 edit_game_draft_ID)
  // 特殊字符串，用于在草稿中标记本地文件位置

  // --- 编辑模式下的初始状态，用于比较变更 ---
  // 保存 widget.game 的初始副本，用于判断是否有修改
  Game? _initialGameData;
  // 保存从 widget.game 加载的初始图片 URL 列表副本，用于比较
  String? _initialCoverImageUrl;
  List<String> _initialGameImageUrls = [];
  String? _initialCategory;

  @override
  void initState() {
    super.initState();
    _draftKey = _getDraftKey(); // 获取当前模式的草稿 Key
    WidgetsBinding.instance.addObserver(this);
    _initializeFormData(); // 初始化（会设置 _initialGameData 如果是编辑）
    // initState 完成后检查草稿，避免在 build 前 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 再次检查 mounted
        _checkAndRestoreDraft(); // 检查并恢复草稿
      }
    });
  }

  // 获取当前表单对应的草稿 Key
  String _getDraftKey() {
    if (widget.game != null && widget.game!.id.isNotEmpty) {
      try {
        return _cacheService.getEditDraftKey(widget.game!.id);
      } catch (e) {
        // 异常情况，比如 ID 无效，退回到使用添加草稿的 key，或者返回 null
        // return null; // 或者返回 null 更好，这样不会误操作草稿
        return GameFormCacheService.addDraftKey; // 或者用添加key作为后备
      }
    } else {
      return GameFormCacheService.addDraftKey;
    }
  }

  @override
  void dispose() {
    _saveDraftIfNecessary();

    WidgetsBinding.instance.removeObserver(this); // 先移除监听器
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _musicUrlController.dispose();
    _bvidController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 在应用暂停或后台时根据条件保存草稿
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 使用 Future.microtask 确保在生命周期变化处理完成后执行保存
      Future.microtask(() async {
        // 检查 mounted 状态，因为异步操作可能在 widget unmount 后执行
        if (mounted) {
          await _saveDraftIfNecessary();
        }
      });
    }
  }

  Future<void> _saveDraftAndExit() async {
    // 直接调用执行保存的方法
    try {
      // 必须确保 draftKey 有效
      if (_draftKey == null) {
        if (mounted) AppSnackBar.showError(context, "无法保存草稿：内部错误");
        return; // 无法保存，不退出
      }

      // 调用实际的保存逻辑
      await _performSaveDraft(); // 这个方法会处理图片占位符等

      // 保存成功后提示并退出
      if (mounted) {
        AppSnackBar.showSuccess(context, '草稿已保存');
        // 延迟一小段时间再 pop，确保 SnackBar 能显示出来
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context); // 退出当前页面
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '保存草稿失败: ${e.toString()}');
      // 保存失败，暂时不退出，让用户看到错误信息
    }
  }

  // --- 初始化表单数据 ---
  void _initializeFormData() {
    // 重置所有状态
    _coverImageSource = null;
    _gameImagesSources = [];
    _downloadLinks = [];
    _selectedCategory = null;
    _selectedTags = [];
    _isProcessing = false;
    _coverImageError = null;
    _categoryError = null;
    _titleController.clear();
    _summaryController.clear();
    _descriptionController.clear();
    _musicUrlController.clear();
    _bvidController.clear();
    _initialGameData = null; // 重置初始数据
    _initialCoverImageUrl = null;
    _initialGameImageUrls = [];

    // 如果是编辑模式，加载现有数据并存储初始状态
    if (widget.game != null) {
      final game = widget.game!;
      // 创建一个副本用于比较，避免直接修改 widget.game
      // 注意：Game 对象的 copyWith 方法需要正确实现深拷贝（特别是 List 和 Map）
      // 如果 copyWith 实现不完善，这里的比较可能不准确
      try {
        _initialGameData = game.copyWith(); // 假设 copyWith 存在且正确
      } catch (e) {
        print(
            "Error creating initial game data copy: $e. Comparisons might be inaccurate.");
        _initialGameData = game; // Fallback to shallow copy (less reliable)
      }

      _titleController.text = game.title;
      _summaryController.text = game.summary;
      _descriptionController.text = game.description;
      _musicUrlController.text = game.musicUrl ?? '';
      _bvidController.text = game.bvid ?? '';

      // 图片处理：只保存 URL 作为初始状态
      _initialCoverImageUrl =
          game.coverImage.isNotEmpty ? game.coverImage : null;
      _coverImageSource = _initialCoverImageUrl; // 表单状态也初始化为 URL 或 null

      _initialGameImageUrls = List<String>.from(game.images); // 初始 URL 列表副本
      _gameImagesSources = List<dynamic>.from(game.images); // 表单状态初始化为 URL 列表

      // 下载链接：需要深拷贝，避免引用同一个列表
      _downloadLinks = List<DownloadLink>.from(game.downloadLinks
          .map((link) => DownloadLink.fromJson(link.toJson())));
      final categoriesList = game.category // <--- 新的
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _selectedCategory =
          categoriesList.isNotEmpty ? categoriesList.first : null;
      _initialCategory = _selectedCategory; // <--- 保存初始分类

      _selectedTags = List<String>.from(game.tags); // 初始标签列表副本
    }

    if (widget.game != null) {
      // print(
      //     "Initial Cover: $_initialCoverImageUrl, Initial Images: $_initialGameImageUrls");
    }
  }

  // --- 草稿相关方法 ---

  // 检查并恢复草稿 (使用 CustomConfirmDialog)
  Future<void> _checkAndRestoreDraft() async {
    if (_isDraftRestored || _draftKey == null || _isProcessing || !mounted) {
      return;
    }

    bool hasDraft = await _cacheService.hasDraft(_draftKey!);
    if (hasDraft && mounted) {
      // 再次检查 mounted
      try {
        // *** 使用 CustomConfirmDialog.show 替换 AlertDialog ***
        await CustomConfirmDialog.show(
          context: context,
          title: '恢复草稿',
          message: widget.game != null
              ? '检测到游戏 "${widget.game!.title}" 上次未完成的编辑，是否恢复？'
              : '检测到上次未完成的游戏添加草稿，是否恢复？',
          confirmButtonText: '恢复',
          cancelButtonText: '丢弃',
          iconData: Icons.history, // 换个历史图标
          iconColor: Colors.orange, // 橙色图标
          confirmButtonColor: Theme.of(context).primaryColor, // 使用主题色
          barrierDismissible: false, // 不允许点击外部关闭

          // --- 确认回调：恢复草稿 ---
          onConfirm: () async {
            // 注意：这里的 await 会在 CustomConfirmDialog 内部处理
            await _loadAndApplyDraft(); // 加载并应用
            // 确认操作完成后，检查组件是否还在树上
            if (mounted) {
              setState(() {
                _isDraftRestored = true;
              }); // 标记已恢复
              AppSnackBar.showSuccess(context, '草稿已恢复');
            }
          },

          // --- 取消回调：清除草稿 ---
          onCancel: () async {
            if (_draftKey == null) {
              return; // Key 无效，无法操作
            }

            GameFormDraft? draftToDiscard; // 用来保存文件路径
            try {
              // 关键步骤 1: 加载要丢弃的草稿数据
              draftToDiscard = await _cacheService.loadDraft(_draftKey!);

              if (draftToDiscard != null) {
                // print("Loaded draft data before discarding for file cleanup.");
              } else {
                // print(
                //     "Warning: Could not load draft data before discarding. File cleanup might be incomplete. Key: $_draftKey");
              }

              // 关键步骤 2: 从 Hive 中清除
              await _cacheService.clearDraft(_draftKey!);

              // 关键步骤 3: 删除关联的文件
              await _deleteDraftFiles(draftToDiscard);

              // 丢弃成功后，可以给个提示（如果需要）
              if (mounted) {
                // AppSnackBar.showInfo(context, '草稿已丢弃'); // 暂时不需要，对话框关闭即可
              }
            } catch (e) {
              // print(
              //     "Error discarding draft (load, clear Hive, or delete files) for key $_draftKey: $e");
              if (mounted) {
                AppSnackBar.showError(context, '丢弃草稿时出错');
              }
              // 即使出错，也要确保 onCancel 回调结束，对话框能正常关闭
            }
            // onCancel 通常只是关闭对话框，不需要在这里 pop 页面等
          },
        );
        // CustomConfirmDialog.show 返回 Future<void>，await 它会等待 onConfirm 完成
        // 如果 onConfirm 出错，错误会从这里抛出
      } catch (e) {
        if (mounted) AppSnackBar.showError(context, '处理草稿时出错: ${e.toString()}');
        // 即使对话框处理出错，也尝试清除草稿避免死循环
        try {
          await _cacheService.clearDraft(_draftKey!);
        } catch (clearError) {
          // print("Failed to clear draft after dialog error: $clearError");
        }
      }
    }
  }

  // 加载并应用草稿
  Future<void> _loadAndApplyDraft() async {
    if (_draftKey == null) return;
    setState(() => _isProcessing = true);

    try {
      final draft = await _cacheService.loadDraft(_draftKey!);
      if (draft != null && mounted) {
        _titleController.text = draft.title;
        _summaryController.text = draft.summary;
        _descriptionController.text = draft.description;
        _musicUrlController.text = draft.musicUrl ?? '';
        _bvidController.text = draft.bvid ?? '';
        _selectedCategory = draft.selectedCategory;
        _selectedTags = List<String>.from(draft.selectedTags);
        _downloadLinks = draft.downloadLinks
            .map((map) => DownloadLink.fromJson(map))
            .toList();

        // --- Restore Cover Image ---
        dynamic restoredCoverSource;
        final coverPathOrUrl = draft.coverImageUrl;
        if (coverPathOrUrl != null && coverPathOrUrl.isNotEmpty) {
          // Check if it looks like a persistent path (adjust check if needed)
          final appDocDir =
              await getApplicationDocumentsDirectory(); // Get base path
          if (coverPathOrUrl.startsWith(appDocDir.path) &&
              await File(coverPathOrUrl).exists()) {
            restoredCoverSource = File(coverPathOrUrl); // Use the File object
          } else if (coverPathOrUrl.startsWith('http')) {
            restoredCoverSource = coverPathOrUrl; // It's a URL
          } else {
            restoredCoverSource = null; // Path invalid or file deleted
          }
        } else {
          restoredCoverSource = null; // No image saved
        }
        _coverImageSource = restoredCoverSource; // Update state

        // --- Restore Game Images ---
        List<dynamic> restoredGameImageSources = [];
        final appDocDir =
            await getApplicationDocumentsDirectory(); // Get base path again
        for (final pathOrUrl in draft.gameImageUrls) {
          if (pathOrUrl.isNotEmpty) {
            if (pathOrUrl.startsWith(appDocDir.path) &&
                await File(pathOrUrl).exists()) {
              restoredGameImageSources.add(File(pathOrUrl)); // Use File object
            } else if (pathOrUrl.startsWith('http')) {
              restoredGameImageSources.add(pathOrUrl); // Use URL String
            } else {
              // Optionally add null or a placeholder if needed, but skipping is cleaner
            }
          }
        }
        _gameImagesSources = restoredGameImageSources; // Update state

        _coverImageError = null;
        _categoryError = null;
        setState(() {}); // Trigger UI update after async operations
      } else if (draft == null && mounted) {
        // print("Could not load draft or draft was null for key: $_draftKey.");
      }
    } catch (e) {
      // print("Error applying draft for key $_draftKey: $e");
      if (mounted) AppSnackBar.showError(context, '应用草稿时出错');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteDraftFiles(GameFormDraft? draft) async {
    if (draft == null) return;

    List<String> pathsToDelete = [];
    final Directory appDocDir =
        await getApplicationDocumentsDirectory(); // 获取应用文档目录
    final String draftImageBasePath =
        '${appDocDir.path}/suxingchahui/draft_images'; // 确定草稿图片的基础路径

    // --- 检查封面图路径 ---
    if (draft.coverImageUrl != null &&
        !draft.coverImageUrl!.startsWith('http') && // 确认不是 URL
        draft.coverImageUrl!.startsWith(draftImageBasePath)) // 确认是我们自己存的路径
    {
      pathsToDelete.add(draft.coverImageUrl!);
    }

    // --- 检查游戏截图路径 ---
    pathsToDelete.addAll(draft.gameImageUrls.where((path) =>
            !path.startsWith('http') && // 确认不是 URL
            path.startsWith(draftImageBasePath) // 确认是我们自己存的路径
        ));

    if (pathsToDelete.isEmpty) {
      // print("No local draft files found in draft data to delete.");
      return;
    }

    for (String path in pathsToDelete) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        } else {
          // print("Draft file not found for deletion (already deleted?): $path");
        }
      } catch (e) {
        // print("Error deleting draft file $path: $e");
        // 可以考虑是否需要上报这个错误
      }
    }
  }

  // 决定是否需要保存草稿，并在需要时保存
  Future<void> _saveDraftIfNecessary() async {
    // 如果正在提交、草稿 Key 无效或 widget 已不存在，则不保存
    if (_isProcessing || _draftKey == null || !mounted) {
      return;
    }

    bool shouldSave = false;
    try {
      if (widget.game != null) {
        // 编辑模式
        if (_hasChanges()) {
          // 检查是否有改动

          shouldSave = true;
        } else {
          //print(
          //    "No changes detected in edit mode. Skipping draft save for key: $_draftKey");
          // 如果没有改动，可以选择清除旧的草稿（如果存在）
          // await _cacheService.clearDraft(_draftKey!);
        }
      } else {
        // 添加模式
        if (!_isFormEmpty()) {
          // 检查表单是否为空

          shouldSave = true;
        } else {
          // 如果表单为空，也清除可能存在的旧草稿
          await _cacheService.clearDraft(_draftKey!);
        }
      }

      if (shouldSave) {
        await _performSaveDraft();
      }
    } catch (e) {
      // print("Error during saveDraftIfNecessary for key $_draftKey: $e");
      // 保存草稿出错，可以选择通知用户
      // if (mounted) AppSnackBar.showError(context, '保存草稿失败');
    }
  }

  // Helper function to get file extension
  String _getFileExtension(String filePath) {
    try {
      return filePath.substring(filePath.lastIndexOf('.'));
    } catch (e) {
      return '.jpg'; // Provide a default extension if parsing fails
    }
  }

  // Helper function to copy file and return persistent path
  Future<String?> _copyDraftImage(XFile sourceFile) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String draftImagesDirPath =
          '${appDocDir.path}/suxingchahui/draft_images';
      // Ensure the directory exists
      await Directory(draftImagesDirPath).create(recursive: true);

      final String uniqueFileName =
          '${const Uuid().v4()}${_getFileExtension(sourceFile.path)}';
      final String persistentPath = '$draftImagesDirPath/$uniqueFileName';

      // Perform the copy operation
      final File sourceIoFile = File(sourceFile.path);
      await sourceIoFile.copy(persistentPath);

      return persistentPath; // Return the new persistent path
    } catch (e) {
      // print('Error copying draft image ${sourceFile.path}: $e');
      // Handle error, maybe return null or rethrow
      return null; // Indicate failure
    }
  }

  // 执行保存草稿的操作
  Future<void> _performSaveDraft() async {
    if (_draftKey == null || !mounted) return;

    String? coverImageToSave;
    // --- Cover Image Handling ---
    if (_coverImageSource is String) {
      coverImageToSave = _coverImageSource as String; // Existing URL
    } else if (_coverImageSource is XFile) {
      // Copy XFile to persistent storage
      coverImageToSave = await _copyDraftImage(_coverImageSource as XFile);
      // If copy failed, coverImageToSave will be null
    } else if (_coverImageSource is File) {
      // If it's already a File (from a previous draft restore), save its path
      coverImageToSave = (_coverImageSource as File).path;
    } else {
      coverImageToSave = null; // No image
    }

    // --- Game Images Handling ---
    List<String> gameImagesToSave = [];
    for (final source in _gameImagesSources) {
      String? imagePath;
      if (source is String) {
        imagePath = source; // Existing URL
      } else if (source is XFile) {
        // Copy XFile to persistent storage
        imagePath = await _copyDraftImage(source);
        // If copy failed, imagePath will be null, and won't be added below
      } else if (source is File) {
        // If it's already a File, save its path
        imagePath = (source).path;
      }

      // Only add valid URLs or persistent paths to the list
      if (imagePath != null && imagePath.isNotEmpty) {
        gameImagesToSave.add(imagePath);
      }
    }

    // --- Create and Save Draft ---
    final draft = GameFormDraft(
      draftKey: _draftKey!,
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      description: _descriptionController.text.trim(),
      musicUrl: _musicUrlController.text.trim().isEmpty
          ? null
          : _musicUrlController.text.trim(),
      bvid: _bvidController.text.trim().isEmpty
          ? null
          : _bvidController.text.trim(),
      coverImageUrl:
          coverImageToSave, // Now contains URL or persistent File path
      gameImageUrls:
          gameImagesToSave, // Now contains URLs or persistent File paths
      downloadLinks: _downloadLinks.map((link) => link.toJson()).toList(),
      selectedCategory: _selectedCategory,
      selectedTags: List<String>.from(_selectedTags),
      lastSaved: DateTime.now(),
    );

    try {
      await _cacheService.saveDraft(_draftKey!, draft);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '保存草稿时发生错误');
      // print("Error in _cacheService.saveDraft: $e");
    }
  }

  // 检查表单是否为空 (用于添加模式)
  bool _isFormEmpty() {
    // 检查所有文本控制器是否为空
    bool textFieldsEmpty = _titleController.text.trim().isEmpty &&
        _summaryController.text.trim().isEmpty &&
        _descriptionController.text.trim().isEmpty &&
        _musicUrlController.text.trim().isEmpty &&
        _bvidController.text.trim().isEmpty;

    // 检查图片是否都为空 (null 且没有 XFile)
    bool coverEmpty = _coverImageSource == null;
    // 检查游戏截图列表是否为空（只包含 null）
    bool gameImagesEmpty = _gameImagesSources.nonNulls as bool;

    // 检查列表是否为空
    bool listsEmpty = _downloadLinks.isEmpty &&
        // _selectedCategories.isEmpty && // 旧的
        _selectedCategory == null && // <--- 新的
        _selectedTags.isEmpty;

    return textFieldsEmpty && coverEmpty && gameImagesEmpty && listsEmpty;
  }

  // 检查表单内容是否已更改 (用于编辑模式)
  bool _hasChanges() {
    // 如果不是编辑模式，或者初始数据丢失，不算更改
    if (widget.game == null || _initialGameData == null) {
      return false;
    }
    final initial = _initialGameData!;
    final eq = const DeepCollectionEquality(); // 用于深度比较 List<Map>

    // 1. 比较文本字段 (trim 后比较)
    if (_titleController.text.trim() != initial.title ||
        _summaryController.text.trim() != initial.summary ||
        _descriptionController.text.trim() != initial.description ||
        (_musicUrlController.text.trim().isEmpty
                ? null
                : _musicUrlController.text.trim()) !=
            initial.musicUrl ||
        (_bvidController.text.trim().isEmpty
                ? null
                : _bvidController.text.trim()) !=
            initial.bvid) {
      return true;
    }

    // 2. 比较封面图片
    if (_coverImageSource is XFile) {
      return true; // 新选了本地文件，肯定是更改
    }
    // 当前是 URL 或 null，与初始 URL (_initialCoverImageUrl) 比较
    final currentCoverUrl =
        (_coverImageSource is String) ? _coverImageSource as String : null;
    if (currentCoverUrl != _initialCoverImageUrl) {
      return true;
    }

    // 3. 比较游戏截图 (最复杂)
    // a) 检查是否有新添加的本地文件 (XFile)
    if (_gameImagesSources.any((s) => s is XFile)) {
      return true;
    }
    // b) 如果没有 XFile，比较当前 URL 列表和初始 URL 列表
    //    当前 URL 列表只包含 _gameImagesSources 中的 String
    final currentGameImageUrls =
        _gameImagesSources.whereType<String>().toList();
    //    使用 ListEquality 比较（顺序敏感）
    if (!const ListEquality()
        .equals(currentGameImageUrls, _initialGameImageUrls)) {
      return true;
    }

    // 比较单个分类，注意 null 情况
    if (_selectedCategory != _initialCategory) {
      // <--- 新的比较

      return true;
    }

    final currentTagsSet = _selectedTags.toSet();
    final initialTagsSet =
        initial.tags.toSet(); // 假设 initial.tags 是 List<String>
    if (!const SetEquality().equals(currentTagsSet, initialTagsSet)) {
      return true;
    }

    // 5. 比较下载链接 (需要深度比较 List<Map>)
    // 先转成 List<Map<String, dynamic>> 再比较
    final currentLinksJson = _downloadLinks.map((l) => l.toJson()).toList();
    final initialLinksJson =
        initial.downloadLinks.map((l) => l.toJson()).toList();
    if (!eq.equals(currentLinksJson, initialLinksJson)) {
      return true;
    }

    // 所有检查都通过，说明没有更改
    return false;
  }

  // --- 表单验证 ---
  bool _validateForm() {
    /// -------------------------------------------------------------------------------
    /// var req struct {
    /// 		Title         string   `json:"title" binding:"required"`       // 标题必需
    /// 		Summary       string   `json:"summary" binding:"required"`     // 摘要必需
    /// 		Description   string   `json:"description" binding:"required"` // 详细描述必须
    /// 		CoverImage    string   `json:"coverImage" binding:"required"`  // 封面必需
    /// 		Category      string   `json:"category" binding:"required"`    // 分类必需
    ///  -------------------------------------------------------------------------------
    /// 参照后端的验证
    bool isTextValid = _formKey.currentState?.validate() ?? false;

    /// 标题必需 <- 在表单ui组件已经验证
    /// 摘要必需 <- 在表单ui组件已经验证
    /// 详细描述必须 <- 在表单ui组件已经验证
    /// 封面必需
    /// 分类必需
    /// ↓ ↓ ↓ ↓ 二次验证

    // 再手动验证图片和分类
    bool hasCover = _coverImageSource != null; // 必须有来源 (URL 或 XFile)
    bool hasCategory = _selectedCategory != null;

    // 更新错误提示状态，触发 UI 重绘
    setState(() {
      _coverImageError = hasCover ? null : '请添加封面图片';
      _categoryError = hasCategory ? null : '请选择一个分类';
    });

    return isTextValid && hasCover && hasCategory;
  }

  // --- 图片处理回调 ---
  void _handleCoverImageChange(dynamic newSource) {
    setState(() {
      _coverImageSource = newSource; // newSource 可以是 XFile 或 null (如果用户取消选择)
      // 如果选择了有效的图片来源 (XFile 或非空 String URL)，清除错误
      if (_coverImageSource is XFile ||
          (_coverImageSource is String &&
              (_coverImageSource as String).isNotEmpty)) {
        _coverImageError = null;
      }
      // 如果用户取消选择变回 null，验证时会重新提示错误
    });
  }

  void _handleGameImagesChange(List<dynamic> newSourcesList) {
    setState(() {
      // newSourcesList 是 GameImagesField 返回的列表，可能包含 String, XFile, null
      _gameImagesSources = newSourcesList;
      // 游戏截图不是必填项，所以这里不需要清除错误
    });
  }

  // --- 核心提交逻辑 ---
  Future<void> _submitForm(String userId) async {
    // 1. 表单验证
    if (!_validateForm()) {
      if (mounted) AppSnackBar.showError(context, '请检查表单中的错误并修正');
      return;
    }

    // 2. 获取操作锁的 Key (编辑用 ID，添加用固定 Key)
    final operationKey = widget.game?.id != null && widget.game!.id.isNotEmpty
        ? 'edit_game_${widget.game!.id}'
        : 'add_game';

    // 3. 设置处理状态，请求锁
    if (mounted) setState(() => _isProcessing = true);
    final uploadService = context.read<RateLimitedFileUpload>();

    bool actionExecuted = await RequestLockService.instance.tryLockAsync(
      operationKey,
      action: () async {
        // ================== 核心操作开始 ==================
        String? finalCoverImageUrl; // 最终封面图 URL
        List<String> finalGameImagesUrls = []; // 最终截图 URL 列表

        try {
          // 3a. 处理封面图上传 (XFile -> 上传, String -> 使用)
          final dynamic currentCoverSource = _coverImageSource;
          if (currentCoverSource is XFile) {
            //print("Uploading new cover image...");
            final fileToUpload = File(currentCoverSource.path);

            // 注意：FileUpload.uploadImage 需要处理可能发生的异常
            finalCoverImageUrl = await uploadService.uploadImage(fileToUpload,
                folder: 'games/covers');
            //print("New cover URL: $finalCoverImageUrl");
            if (finalCoverImageUrl.isEmpty) {
              throw Exception(
                  "Cover image upload failed or returned empty URL.");
            }
          } else if (currentCoverSource is String &&
              currentCoverSource.isNotEmpty) {
            finalCoverImageUrl = currentCoverSource; // 使用现有 URL
          } else {
            // 理论上 _validateForm 已经阻止了这种情况，但加个保险
            throw Exception("Cover image source is invalid or missing!");
          }

          // 3b. 处理游戏截图上传 (XFile -> 上传, String -> 使用, null -> 忽略)
          final List<dynamic> currentImageSources =
              List.from(_gameImagesSources);
          final List<File> filesToUpload = []; // 需要上传的文件
          final List<int> xFileIndices = []; // 记录 XFile 在原列表中的索引
          final List<String?> tempFinalUrls =
              List.filled(currentImageSources.length, null); // 临时列表，保持顺序

          // 第一次遍历：识别需要上传的文件和已有的 URL
          for (int i = 0; i < currentImageSources.length; i++) {
            final source = currentImageSources[i];
            if (source is XFile) {
              filesToUpload.add(File(source.path));
              xFileIndices.add(i); // 记录索引
            } else if (source is String && source.isNotEmpty) {
              tempFinalUrls[i] = source; // 直接放入临时列表
            }
            // source 为 null 的情况，tempFinalUrls[i] 保持 null
          }

          // 如果有文件需要上传
          List<String> uploadedUrls = [];
          if (filesToUpload.isNotEmpty) {
            //print("Uploading ${filesToUpload.length} new screenshots...");
            // 注意：FileUpload.uploadFiles 需要处理异常
            uploadedUrls = await uploadService.uploadImages(filesToUpload,
                folder: 'games/screenshots');
            if (uploadedUrls.length != filesToUpload.length) {
              // 上传数量不匹配，是个严重问题
              throw Exception(
                  "Screenshot upload count mismatch! Expected ${filesToUpload.length}, got ${uploadedUrls.length}");
            }
            //print("New screenshot URLs: $uploadedUrls");

            // 第二次遍历：将上传后的 URL 填回 tempFinalUrls 的对应位置
            int uploadedIndex = 0;
            for (int originalIndex in xFileIndices) {
              if (uploadedIndex < uploadedUrls.length) {
                tempFinalUrls[originalIndex] = uploadedUrls[uploadedIndex];
                uploadedIndex++;
              } else {
                // 这理论上不应该发生，因为前面检查了数量匹配
                // print(
                //     "Warning: Ran out of uploaded URLs while mapping back. Index: $originalIndex");
              }
            }
          }

          // 从临时列表过滤掉 null，得到最终的 URL 列表
          finalGameImagesUrls = tempFinalUrls.whereType<String>().toList();

          // 3c. 构建 Game 对象
          final game = Game(
            // ID: 编辑时用 widget.game.id，添加时生成新 ID
            id: widget.game?.id ?? mongo.ObjectId().oid,
            // Author ID: 需要从当前登录用户获取，这里用占位符
            authorId: widget.game?.authorId ?? userId,
            title: _titleController.text.trim(),
            summary: _summaryController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory ?? '',
            coverImage: finalCoverImageUrl, // 已确保非空
            images: finalGameImagesUrls, // 最终 URL 列表
            tags: List<String>.from(_selectedTags), // 确保是副本
            // 评分相关字段：添加时不设置，编辑时保留原值，由评分系统更新
            rating: widget.game?.rating ?? 0.0,
            totalRatingSum: widget.game?.totalRatingSum ?? 0.0,
            ratingCount: widget.game?.ratingCount ?? 0,
            // 时间戳：添加时用当前时间，编辑时用旧的创建时间，更新时间总是当前时间
            createTime: widget.game?.createTime ?? DateTime.now(),
            updateTime: DateTime.now(),
            // 计数器：添加时为 0，编辑时保留原值
            viewCount: widget.game?.viewCount ?? 0,
            likeCount: widget.game?.likeCount ?? 0,
            likedBy: widget.game?.likedBy ?? [], // 编辑时保留
            // 收藏计数器：同上
            wantToPlayCount: widget.game?.wantToPlayCount ?? 0,
            playingCount: widget.game?.playingCount ?? 0,
            playedCount: widget.game?.playedCount ?? 0,
            totalCollections: widget.game?.totalCollections ?? 0,
            // 下载链接
            downloadLinks: List<DownloadLink>.from(// 确保是副本
                _downloadLinks
                    .map((link) => DownloadLink.fromJson(link.toJson()))),
            // 可选字段
            musicUrl: _musicUrlController.text.trim().isEmpty
                ? null
                : _musicUrlController.text.trim(),
            bvid: _bvidController.text.trim().isEmpty
                ? null
                : _bvidController.text.trim(),
            lastViewedAt: widget.game?.lastViewedAt, // 编辑时保留
          );

          // 3d. 调用外部 onSubmit 回调 (执行 API 请求)
          await widget.onSubmit(game); // 等待 API 调用完成

          // 3e. 清除当前模式的草稿 (只有在 action 完全成功后才清除)
          if (_draftKey != null) {
            GameFormDraft? draftBeforeDeletion; // 用来保存包含文件路径的旧草稿数据
            try {
              // 关键步骤 1: 在删除 Hive 条目之前，先加载它！
              // 使用正确的 Service 方法 loadDraft
              draftBeforeDeletion = await _cacheService.loadDraft(_draftKey!);

              if (draftBeforeDeletion != null) {
                //print("Loaded draft data before deletion for file cleanup.");
              } else {
                //print(
                //    "Warning: Could not load draft data before deletion. File cleanup might be incomplete. Key: $_draftKey");
              }

              // 关键步骤 2: 清除 Hive 中的草稿条目
              await _cacheService.clearDraft(_draftKey!);
              //print("Local draft cleared from Hive for key: $_draftKey.");

              // 关键步骤 3: 使用刚才加载出来的数据去删除对应的文件
              await _deleteDraftFiles(draftBeforeDeletion); // 传入加载出来的旧数据
            } catch (e) {
              //print(
              //    "Error during draft cleanup (load, clear Hive, or delete files) for key $_draftKey after submission: $e");
              // 即使清理失败，提交本身是成功的，所以一般不需要打断用户流程，记录错误即可
              if (mounted) {
                // 可以选择性地给用户一个提示，说明后台清理可能有点问题
                // AppSnackBar.showWarning(context, '提交成功，但后台草稿清理可能遇到问题。');
              }
            }
          } else {
            //print(
            //    "Warning: Draft key was null, cannot clear draft after submission.");
          }

          // ================== 核心操作结束 ==================
        } catch (e) {
          // action 内部错误处理
          //print('Error during submission action ($operationKey): $e');
          // 确保在 mounted 状态下显示 SnackBar
          if (mounted) {
            // 提取更友好的错误信息，避免显示整个堆栈
            String errorMessage = e.toString();
            if (e is Exception) {
              errorMessage = e
                  .toString()
                  .replaceFirst("Exception: ", ""); // 移除 "Exception: " 前缀
            }
            AppSnackBar.showError(context, '提交处理失败: $errorMessage');
          }
          // 必须重新抛出，让 tryLockAsync 知道出错了
          rethrow;
        }
      },
      onLockFailed: () {
        // 锁定时（操作已在进行中）的回调
        //print("Operation ($operationKey) is already in progress.");
        if (mounted) {
          AppSnackBar.showInfo(context, '操作正在进行中，请稍候...');
        }
        // 锁获取失败时，应该重置 processing 状态，因为当前实例并未执行操作
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      },
    );

    // 4. 无论 tryLockAsync 结果如何（除非 onLockFailed 提前重置了），
    //    如果 action 被执行了（无论成功或失败），最终都重置本地处理状态
    //    注意：如果 action 抛出异常，这里依然会执行
    //    如果 onLockFailed 被调用，它内部已经重置了状态，这里就不需要再重置
    if (actionExecuted && mounted) {
      setState(() => _isProcessing = false);
    }

    // actionExecuted 会告诉你 action 是否真的被执行了
    if (actionExecuted) {
      //print("Submission action attempt finished for $operationKey.");
      // 成功的 SnackBar 应该由调用方 (Add/Edit Screen) 在 onSubmit 回调成功后显示
    }
  }

  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 950;

    // --- NEW: Determine canPop value ---
    // Block pop initially if processing OR if there are unsaved changes requiring confirmation
    bool hasUnsavedChanges = widget.game != null && _hasChanges();
    bool isAddModeWithContent = widget.game == null && !_isFormEmpty();
    // If processing, OR if there are changes that need confirmation, set canPop to false initially.
    final bool allowImmediatePop =
        !(_isProcessing || hasUnsavedChanges || isAddModeWithContent);

    final String? currentUserId = authProvider.currentUserId;

    if (currentUserId == null) return LoginPromptWidget();

    // 使用 Stack 包裹，方便显示全局加载指示器
    return Stack(
      children: [
        // *** REPLACE WillPopScope WITH PopScope ***
        PopScope<Object?>(
          // <-- 1. 添加泛型 (Object? 因为 GameForm 本身不pop带特定结果)
          canPop: allowImmediatePop,
          // <-- 2. 使用 onPopInvokedWithResult 并更新签名
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              _handleBlockedPopAttempt(); // Call the handler logic
            }
          },
          child: Form(
            key: _formKey,
            // autovalidateMode: AutovalidateMode.onUserInteraction,
            child: useDesktopLayout
                ? _buildDesktopLayout(context, currentUserId)
                : _buildMobileLayout(context, currentUserId),
          ),
        ),
        // 使用 _isProcessing 控制 LoadingWidget.inline 的显示
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withSafeOpacity(0.1), // 半透明遮罩
              child: LoadingWidget.inline(), // 居中显示
            ),
          ),
      ],
    );
  }

  // --- NEW: Handler for pop attempts blocked by canPop: false ---
  Future<void> _handleBlockedPopAttempt() async {
    // First, check if it was blocked due to processing
    if (_isProcessing) {
      if (mounted) AppSnackBar.showInfo(context, '正在处理中，请稍候...');
      return; // Do nothing more, pop remains blocked
    }

    // If not processing, it was blocked due to unsaved changes/content.
    // Re-check the condition just in case state changed rapidly.
    bool hasUnsavedChanges = widget.game != null && _hasChanges();
    bool isAddModeWithContent = widget.game == null && !_isFormEmpty();

    if (hasUnsavedChanges || isAddModeWithContent) {
      // Show the confirmation dialog
      CustomConfirmDialog.show(
        context: context,
        title: '离开页面?',
        message: hasUnsavedChanges
            ? '您有未保存的修改。如果离开，修改将丢失，但会尝试保存为草稿。确定离开吗？'
            : '您填写的内容尚未提交。如果离开，会尝试保存为草稿。确定离开吗？',
        confirmButtonText: '确定离开',
        cancelButtonText: '取消',
        iconData: Icons.warning_amber_rounded,
        iconColor: Colors.amber,
        confirmButtonColor: Colors.red,
        barrierDismissible: false,

        // --- Confirm Leave Callback ---
        onConfirm: () async {
          try {
            // Try saving the draft
            await _saveDraftIfNecessary();
          } catch (e) {
            print("Error saving draft during PopScope confirmation: $e");
            // Saving draft failed, but user chose to leave anyway.
          } finally {
            // IMPORTANT: Manually trigger the pop now!
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        },

        // --- Cancel Leave Callback ---
        onCancel: () {
          // User cancelled. Do nothing. The pop remains blocked.
        },
      ).catchError((error) {
        // Handle potential errors showing the dialog itself
        // Pop remains blocked if dialog fails.
      });
    }
    // If, somehow, this method is called but there are no unsaved changes
    // and not processing (e.g., state changed), do nothing, pop remains blocked.
  }

  // --- 桌面布局构建 ---
  Widget _buildDesktopLayout(BuildContext context, String userId) {
    // 稍微调整高度限制
    final desktopCardMaxHeight =
        MediaQuery.of(context).size.height - 120; // 留出更多边距
    return SingleChildScrollView(
      // 允许外部滚动
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 增大桌面边距
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧卡片：图片和链接
            Expanded(
              flex: 4, // 可以调整比例
              child: Card(
                elevation: 3, // 稍微增加阴影
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ConstrainedBox(
                  // 限制最大高度
                  constraints: BoxConstraints(maxHeight: desktopCardMaxHeight),
                  child: SingleChildScrollView(
                    // 允许卡片内部滚动
                    padding: const EdgeInsets.all(20.0), // 增大卡片内边距
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('媒体与链接'),
                        const SizedBox(height: 20),
                        _buildCoverImageSection(),
                        const SizedBox(height: 28),
                        _buildGameImagesSection(),
                        const SizedBox(height: 28),
                        _buildDownloadLinksField(),
                        const SizedBox(height: 28),
                        _buildMusicUrlField(),
                        const SizedBox(height: 20),
                        _buildBvidField(),
                        const SizedBox(height: 20), // 底部留白
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24), // 增大卡片间距
            // 右侧卡片：游戏信息和操作
            Expanded(
              flex: 6, // 可以调整比例
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ConstrainedBox(
                  // 限制最大高度
                  constraints: BoxConstraints(maxHeight: desktopCardMaxHeight),
                  child: SingleChildScrollView(
                    // 允许卡片内部滚动
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('基础信息'),
                        const SizedBox(height: 20),
                        _buildTitleField(),
                        const SizedBox(height: 20),
                        _buildSummaryField(),
                        const SizedBox(height: 20),
                        _buildDescriptionField(),
                        const SizedBox(height: 28),
                        _buildSectionTitle('分类与标签'),
                        const SizedBox(height: 20),
                        _buildCategorySection(),
                        const SizedBox(height: 28),
                        _buildTagsField(),
                        const SizedBox(height: 40), // 增大与按钮的间距
                        // 操作按钮居中
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // 按钮靠右
                          children: [
                            _buildPreviewButton(), // 预览按钮
                            const SizedBox(width: 16),
                            _buildExitAndSaveDraftButton(),
                            const SizedBox(width: 16),
                            _buildSubmitButton(userId), // 提交按钮
                          ],
                        ),
                        const SizedBox(height: 20), // 底部留白
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

  // --- 移动布局构建 ---
  Widget _buildMobileLayout(BuildContext context, String userId) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        color: Colors.white,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('封面图 *'), // 标记必填
            const SizedBox(height: 8),
            _buildCoverImageSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('基础信息 *'), // 标记必填
            const SizedBox(height: 8),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildSummaryField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),

            _buildSectionTitle('媒体链接 (可选)'),
            const SizedBox(height: 8),
            _buildMusicUrlField(),
            const SizedBox(height: 16),
            _buildBvidField(),
            const SizedBox(height: 24),

            _buildSectionTitle('分类 * 与标签 (可选)'),
            const SizedBox(height: 8),
            _buildCategorySection(),
            const SizedBox(height: 16),
            _buildTagsField(),
            const SizedBox(height: 24),

            _buildSectionTitle('下载链接 (可选)'),
            const SizedBox(height: 8),
            _buildDownloadLinksField(),
            const SizedBox(height: 24),

            _buildSectionTitle('游戏截图 (可选)'),
            const SizedBox(height: 8),
            _buildGameImagesSection(),
            const SizedBox(height: 32), // 增大按钮前间距

            // 操作按钮
            _buildPreviewButton(), // 预览按钮放上面
            const SizedBox(height: 16),
            _buildExitAndSaveDraftButton(),
            const SizedBox(height: 16),
            _buildSubmitButton(userId), // 提交按钮放下面
            const SizedBox(height: 24), // 底部额外留白
          ],
        ),
      ),
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
            fontSize: DeviceUtils.isDesktop ? 18 : 16, // 桌面端字号稍大
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.color
                    ?.withSafeOpacity(0.85) ??
                Colors.black87, // 使用主题颜色
          ),
        ),
        const Divider(height: 12, thickness: 1, endIndent: 16), // 短一点的分割线
      ],
    );
  }

  // 封面图区域 (带错误提示)
  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CoverImageField 应该能处理 String, XFile, null
        CoverImageField(
          coverImageSource: _coverImageSource,
          onChanged: _handleCoverImageChange,
          isLoading: _isProcessing,
        ),
        // 显示验证错误
        if (_coverImageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0), // 左侧留一点空隙
            child: Text(
              _coverImageError!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, // 使用主题错误颜色
                  fontSize: 12),
            ),
          ),
      ],
    );
  }

  // 标题字段
  Widget _buildTitleField() {
    return FormTextInputField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: const InputDecoration(
        labelText: '游戏标题 *',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(), // 可以把基础样式放在这里
      ),
      maxLines: 1,
      maxLength: 50,
      isEnabled: !_isProcessing,
      textInputAction: TextInputAction.next,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入游戏标题' : null,
    );
  }

  // 简介字段
  Widget _buildSummaryField() {
    return FormTextInputField(
      controller: _summaryController,
      focusNode: _summaryFocusNode,
      decoration: const InputDecoration(
        labelText: '游戏简介 *',
        hintText: '一句话概括游戏简要内容',
        prefixIcon: Icon(Icons.short_text),
        border: OutlineInputBorder(),
      ),
      maxLength: 100,
      minLines: 2,
      maxLines: 3,
      isEnabled: !_isProcessing,
      textInputAction: TextInputAction.newline,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入游戏简介' : null,
    );
  }

  // 描述字段
  Widget _buildDescriptionField() {
    return FormTextInputField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      decoration: InputDecoration(
        labelText: '详细描述 *',
        hintText: '详细介绍游戏背景、玩法、特色等...',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Icon(Icons.description_outlined),
        ),
      ),
      minLines: DeviceUtils.isDesktop ? 5 : 4,
      maxLength: 500,
      maxLines: DeviceUtils.isDesktop ? 10 : 8,
      isEnabled: !_isProcessing,
      textInputAction: TextInputAction.newline,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入详细描述' : null,
    );
  }

  // 音乐链接字段
  Widget _buildMusicUrlField() {
    return FormTextInputField(
      controller: _musicUrlController,
      focusNode: _musicUrlFocusNode,
      decoration: const InputDecoration(
        labelText: '网易云音乐链接',
        hintText: '例如: https://music.163.com/#/song?id=...',
        prefixIcon: Icon(Icons.music_note_outlined),
        border: OutlineInputBorder(),
      ),
      maxLines: 1,
      isEnabled: !_isProcessing,
      keyboardType: TextInputType.url, // 指定键盘类型
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        if (!_validateMusic(value.trim())) return '请输入有效的网易云音乐链接';
        return null;
      },
    );
  }

  // BVID 字段
  Widget _buildBvidField() {
    return FormTextInputField(
      controller: _bvidController,
      focusNode: _bvidFocusNode,
      decoration: const InputDecoration(
        labelText: 'B站视频 BV号',
        hintText: '例如: BV1fx411u7pM',
        prefixIcon: Icon(Icons.smart_display_outlined),
        border: OutlineInputBorder(),
      ),
      maxLines: 1,
      isEnabled: !_isProcessing,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        if (!_validateBV(value.trim())) return '请输入有效的 BV 号 (以 BV 开头)';
        return null;
      },
    );
  }

  // --- 辅助验证函数 ---
  bool _validateBV(String text) {
    // 简单检查 BV 号格式 (以 BV 开头，后面跟数字和字母组合)
    final bvPattern = RegExp(r'^BV[1-9A-HJ-NP-Za-km-z]+$');
    // 还需要检查长度，一般是 10 位字符 + BV 前缀 = 12 位
    return text.startsWith('BV') &&
        text.length > 10 &&
        bvPattern.hasMatch(text);
  }

  bool _validateMusic(String text) {
    // 检查是否是 music.163.com 的链接
    return text.startsWith('http://music.163.com') ||
        text.startsWith('https://music.163.com');
  }

  // 分类区域 (带错误提示)
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryField(
          selectedCategory: _selectedCategory,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
              // 如果选择了分类或取消选择，更新错误状态
              _categoryError = (_selectedCategory == null) ? '请选择一个分类' : null;
            });
          },
        ),
        // 显示验证错误
        if (_categoryError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              _categoryError!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
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
    // GameImagesField 应该能处理 List<String or XFile or null>
    return GameImagesField(
      gameImagesSources: _gameImagesSources,
      onChanged: _handleGameImagesChange,
      isLoading: _isProcessing,
    );
  }

  Widget _buildExitAndSaveDraftButton() {
    return FunctionalButton(
      label: '保存草稿并退出',
      onPressed:
          !_isProcessing ? () => _saveDraftAndExit() : () => {}, // 非处理中才可点
      isEnabled: !_isProcessing,
      icon: Icons.drafts_outlined, // 草稿图标
      isLoading: false, // 这个按钮本身不触发长时间处理
    );
  }

  // --- 构建提交按钮 ---
  Widget _buildSubmitButton(String userId) {
    // 按钮是否可用: 未处于处理状态
    bool canPress = !_isProcessing;

    return FunctionalButton(
        onPressed: canPress
            ? () => _submitForm(userId)
            : () => {}, // 禁用时 onPressed 为 null
        isEnabled: canPress,
        isLoading: _isProcessing, // 控制按钮内是否显示加载指示器
        label: widget.game == null ? '添加游戏' : '保存修改',
        icon: widget.game == null
            ? Icons.add_circle_outline // 添加图标
            : Icons.save_alt_outlined // 保存图标
        );
  }

  // --- 构建预览按钮 ---
  Widget _buildPreviewButton() {
    // 预览时，本地文件(XFile)无法直接显示，所以只传递 URL
    String? previewCoverUrl;
    if (_coverImageSource is String &&
        (_coverImageSource as String).isNotEmpty) {
      previewCoverUrl = _coverImageSource as String;
    }

    // 预览的游戏截图也只包括 URL
    List<String> previewImageUrls = _gameImagesSources
        .whereType<String>() // 只取 String 类型的 URL
        .where((url) => url.isNotEmpty)
        .toList();

    return GamePreviewButton(
      // 传递控制器和当前状态给预览按钮
      titleController: _titleController,
      summaryController: _summaryController,
      descriptionController: _descriptionController,
      coverImageUrl: previewCoverUrl, // 可能为 null
      gameImages: previewImageUrls, // 只包含 URL 的列表
      selectedCategory: _selectedCategory,
      selectedTags: _selectedTags,
      rating: widget.game?.rating ?? 0.0, // 预览用现有评分或 0
      downloadLinks: _downloadLinks,
      musicUrlController: _musicUrlController,
      bvidController: _bvidController,
      existingGame: widget.game, // 传递原始 game 对象，预览时可能有用
    );
  }
} // _GameFormState 结束
