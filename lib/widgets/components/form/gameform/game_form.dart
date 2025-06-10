// lib/widgets/components/form/gameform/game_form.dart
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
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/form/game_form_cache_service.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/services/utils/request_lock_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

// --- UI 和辅助组件 ---
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:uuid/uuid.dart';
import 'field/game_category_field.dart';
import 'field/game_cover_image_field.dart';
import 'field/game_download_links_field.dart';
import 'field/game_images_field.dart';
import 'field/game_tags_field.dart';
import 'preview/game_preview_button.dart';

class GameForm extends StatefulWidget {
  final WindowStateProvider windowStateProvider;
  final GameService gameService;
  final RateLimitedFileUpload fileUpload;
  final SidebarProvider sidebarProvider;
  final GameCollectionService gameCollectionService;
  final GameListFilterProvider gameListFilterProvider;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final Game? game; // 编辑时传入的游戏对象
  final User? currentUser;
  final Function(Game) onSubmit; // 提交成功后的回调

  const GameForm({
    super.key,
    this.game,
    required this.windowStateProvider,
    required this.sidebarProvider,
    required this.authProvider,
    required this.followService,
    required this.inputStateService,
    required this.fileUpload,
    required this.infoProvider,
    required this.gameService,
    required this.gameListFilterProvider,
    required this.gameCollectionService,
    required this.currentUser,
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
  List<GameDownloadLink> _downloadLinks = [];
  String? _selectedCategory;
  List<String> _selectedTags = [];

  // --- 状态标志 ---
  bool _isProcessing = false; // 控制 UI 加载和按钮禁用
  bool _isDraftRestored = false; // 标记草稿是否已恢复过一次，避免重复询问

  // --- 验证错误信息 ---
  String? _coverImageError;
  String? _categoryError;

  // --- 草稿相关 ---
  String? _draftKey; // 当前表单使用的草稿 Key (add_draft 或 edit_game_draft_ID)
  // 特殊字符串，用于在草稿中标记本地文件位置

  // --- 编辑模式下的初始状态，用于比较变更 ---
  // 保存 widget.game 的初始副本，用于判断是否有修改
  Game? _initialGameData;
  // 保存从 widget.game 加载的初始图片 URL 列表副本，用于比较
  String? _initialCoverImageUrl;
  List<String> _initialGameImageUrls = [];
  String? _initialCategory;
  bool _hasInitializedDependencies = false;
  late final GameFormCacheService _cacheService;
  User? _currentUser;

  late Size _screenSize;
  late bool _isDesktop;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _cacheService = context.read<GameFormCacheService>();
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _screenSize = DeviceUtils.getScreenSize(context);
      _isDesktop = DeviceUtils.isDesktopInThisWidth(_screenSize.width);
      _draftKey = _getDraftKey(); // 获取当前模式的草稿 Key
      WidgetsBinding.instance.addObserver(this);
      _initializeFormData(); // 初始化（会设置 _initialGameData 如果是编辑）
      // initState 完成后检查草稿，避免在 build 前 setState
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            // 再次检查 mounted
            _checkAndRestoreDraft(); // 检查并恢复草稿
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant GameForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
    setState(() {
      _screenSize = DeviceUtils.getScreenSize(context);
      _isDesktop = DeviceUtils.isDesktopInThisWidth(_screenSize.width);
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
        if (mounted) AppSnackBar.showError("无法保存草稿");
        return; // 无法保存，不退出
      }

      // 调用实际的保存逻辑
      await _performSaveDraft(); // 这个方法会处理图片占位符等

      // 保存成功后提示并退出

      AppSnackBar.showSuccess('草稿已保存');
      // 延迟一小段时间再 pop，确保 SnackBar 能显示出来
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context); // 退出当前页面
      }
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}");
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
      try {
        _initialGameData = game.copyWith(); // 假设 copyWith 存在且正确
      } catch (e) {
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
      _downloadLinks = List<GameDownloadLink>.from(game.downloadLinks
          .map((link) => GameDownloadLink.fromJson(link.toJson())));
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
  }

  Future<void> _handleCancelRestoreDraft() async {
    if (_draftKey == null) {
      return; // Key 无效，无法操作
    }

    GameFormDraft? draftToDiscard; // 用来保存文件路径
    try {
      // 关键步骤 1: 加载要丢弃的草稿数据
      draftToDiscard = await _cacheService.loadDraft(_draftKey!);

      // 关键步骤 2: 从 Hive 中清除
      await _cacheService.clearDraft(_draftKey!);

      // 关键步骤 3: 删除关联的文件
      await _deleteDraftFiles(draftToDiscard);

      // 丢弃成功后，可以给个提示（如果需要）
      if (mounted) {
        // AppSnackBar.showInfo(context, '草稿已丢弃'); // 暂时不需要，对话框关闭即可
      }
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}");
    }
    // onCancel 通常只是关闭对话框，不需要在这里 pop 页面等
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

            setState(() {
              _isDraftRestored = true;
            }); // 标记已恢复
            AppSnackBar.showSuccess('草稿已恢复');
          },

          // --- 取消回调：清除草稿 ---
          onCancel: _handleCancelRestoreDraft,
        );

        // CustomConfirmDialog.show 返回 Future<void>，await 它会等待 onConfirm 完成
        // 如果 onConfirm 出错，错误会从这里抛出
      } catch (e) {
        AppSnackBar.showError("操作失败,${e.toString()}");
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
            .map((map) => GameDownloadLink.fromJson(map))
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
      AppSnackBar.showError("操作失败,${e.toString()}");
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
      AppSnackBar.showError("操作失败,${e.toString()}");
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
    bool gameImagesEmpty = _gameImagesSources.nonNulls.isEmpty;

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
    /// 		Title         string                `json:"title" binding:"required,min=2,max=100"`        // 标题必需，2-100字
    /// 		Summary       string                `json:"summary" binding:"required,min=2,max=500"`      // 摘要必需，2-500字
    /// 		Description   string                `json:"description" binding:"required,min=2,max=1000"` // 详细描述必须，2-1000字
    /// 		CoverImage    string                `json:"coverImage" binding:"required,url"`             // 封面必需，且是 URL
    /// 		Category      string                `json:"category" binding:"required,min=1,max=50"`      // 分类必需，1-50字
    ///  -------------------------------------------------------------------------------
    /// 参照后端的验证
    bool isTextValid = _formKey.currentState?.validate() ?? false;

    /// 标题必需 <- 在表单ui组件已经验证
    /// 摘要必需 <- 在表单ui组件已经验证
    /// 详细描述必须 <- 在表单ui组件已经验证
    /// 封面必需
    /// 分类必需
    /// ↓ ↓ ↓ ↓ 二次验证
    ///

    bool isValid;
    final isValidMes = _validateGameFieldsBeforeRequest();
    if (isValidMes != null) {
      isValid = false;
      if (context.mounted) {
        AppSnackBar.showWarning(isValidMes);
      }
    } else {
      isValid = true;
    }

    return isTextValid && isValid;
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

  // 校验函数：接收 Game 对象，如果校验通过返回 null，否则返回错误信息字符串
  String? _validateGameFieldsBeforeRequest() {
    // 校验标题：不能为空，长度需在2到100字之间
    final title = _titleController.text.trim();
    if (title.isEmpty || title.length < 2 || title.length > 100) {
      return '标题不能为空，且长度需在2到100字之间。';
    }

    final summary = _titleController.text.trim();
    // 校验摘要：不能为空，长度需在2到500字之间
    if (summary.isEmpty || summary.length < 2 || summary.length > 500) {
      return '摘要不能为空，且长度需在2到500字之间。';
    }

    final description = _descriptionController.text.trim();
    // 校验详细描述：不能为空，长度需在2到1000字之间
    if (description.isEmpty ||
        description.length < 2 ||
        description.length > 1000) {
      return '详细描述不能为空，且长度需在2到1000字之间。';
    }

    final tags = _selectedTags;
    // 校验标签数量：不能超过5个
    if (tags.length > 5) {
      return '标签数量不能超过5个。';
    }

    // 校验每个标签的长度：不能超过8个字
    for (final tag in tags) {
      if (tag.length > 8) {
        return '每个标签的长度不能超过8个字，标签: $tag。';
      }
    }

    final musicUrl = _musicUrlController.text.trim();
    // 校验音乐URL：如果存在，必须是网易云音乐域名下的有效URL
    if (musicUrl.isNotEmpty) {
      final parsedUri = Uri.tryParse(musicUrl);
      // 校验URL结构是否有效（是否有协议和主机）
      if (parsedUri == null ||
          !parsedUri.hasScheme ||
          !parsedUri.hasAuthority) {
        return '音乐URL格式非法，无法解析。';
      }
      // 校验域名是否为 "music.163.com"
      if (parsedUri.host != 'music.163.com') {
        return '音乐URL域名不正确，请提供网易云音乐域名下的链接。';
      }
    }
    final bvid = _bvidController.text.trim();
    // 校验B站BV号：如果存在，必须以"BV"开头且长度为12位字母数字
    if (bvid.isNotEmpty) {
      // BV号正则：BV开头，后接10位字母或数字
      final bvidRegex = RegExp(r'^BV[0-9a-zA-Z]{10}$');
      if (!bvidRegex.hasMatch(bvid)) {
        return 'B站视频BV号格式不正确，应为"BV"开头加10位字母数字。';
      }
    }

    // 再手动验证图片和分类
    bool hasCover = _coverImageSource != null; // 必须有来源 (URL 或 XFile)
    bool hasCategory = _selectedCategory != null;
    int imagesLength = _gameImagesSources.length;

    if (!hasCover) {
      // 更新错误提示状态，触发 UI 重绘
      setState(() {
        _coverImageError = hasCover ? null : '请添加封面图片';
      });
      return '请添加封面图片';
    }

    if (imagesLength > 3) {
      return '图片太多，最多3张';
    }

    if (!hasCategory) {
      // 更新错误提示状态，触发 UI 重绘
      setState(() {
        _categoryError = hasCategory ? null : '请选择一个分类';
      });
      return '请选择一个分类';
    }

    // 所有校验通过，返回null
    return null;
  }

  // --- 核心提交逻辑 ---
  Future<void> _submitForm(String userId) async {
    List<String> uploadedImageUrls = []; // 用于收集本次上传的所有图片URL
    // 1. 表单验证
    if (!_validateForm()) {
      return;
    }

    // 2. 获取操作锁的 Key (编辑用 ID，添加用固定 Key)
    final operationKey = widget.game?.id != null && widget.game!.id.isNotEmpty
        ? 'edit_game_${widget.game!.id}'
        : 'add_game';

    // 3. 设置处理状态，请求锁
    if (mounted) setState(() => _isProcessing = true);

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
            finalCoverImageUrl = await widget.fileUpload
                .uploadImage(fileToUpload, folder: 'games/covers');
            //print("New cover URL: $finalCoverImageUrl");
            if (finalCoverImageUrl.isEmpty) {
              throw Exception("上传失败");
            }
          } else if (currentCoverSource is File) {
            // 这是从草稿恢复的 File 对象，也需要上传
            finalCoverImageUrl = await widget.fileUpload.uploadImage(
                currentCoverSource,
                folder: 'games/covers'); // 直接传递 File 对象
            if (finalCoverImageUrl.isEmpty) {
              throw Exception("封面图上传失败 (草稿恢复)");
            }
          } else if (currentCoverSource is String &&
              currentCoverSource.isNotEmpty) {
            finalCoverImageUrl = currentCoverSource; // 使用现有 URL
          } else {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
            throw Exception("图片不合法");
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
            } else if (source is File) {
              // <--- 新增对 File 类型的处理
              filesToUpload.add(source); // 直接添加 File 对象
              xFileIndices.add(i);
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
            uploadedUrls = await widget.fileUpload
                .uploadImages(filesToUpload, folder: 'games/screenshots');
            if (uploadedUrls.length != filesToUpload.length) {
              // 上传数量不匹配，是个严重问题
              throw Exception("图片上传部分失败");
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
          if (finalCoverImageUrl.isNotEmpty) {
            uploadedImageUrls.add(finalCoverImageUrl);
          }
          uploadedImageUrls.addAll(
              finalGameImagesUrls); // finalGameImagesUrls 已经是 List<String>

          final game = Game(
            // ID: 编辑时用 widget.game.id，添加时生成新 ID
            id: widget.game?.id ?? mongo.ObjectId().oid,
            // Author ID: 需要从当前登录用户获取，这里用占位符
            authorId: widget.game?.authorId ?? userId,
            title: _titleController.text.trim(),
            summary: _summaryController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory ?? '',
            coverImage: finalCoverImageUrl,
            images: finalGameImagesUrls,
            tags: List<String>.from(_selectedTags),
            rating: widget.game?.rating ?? 0.0,
            totalRatingSum: widget.game?.totalRatingSum ?? 0.0,
            ratingCount: widget.game?.ratingCount ?? 0,
            createTime: widget.game?.createTime ?? DateTime.now(),
            updateTime: DateTime.now(),
            viewCount: widget.game?.viewCount ?? 0,
            likeCount: widget.game?.likeCount ?? 0,
            likedBy: widget.game?.likedBy ?? [], // 编辑时保留
            wantToPlayCount: widget.game?.wantToPlayCount ?? 0,
            playingCount: widget.game?.playingCount ?? 0,
            playedCount: widget.game?.playedCount ?? 0,
            totalCollections: widget.game?.totalCollections ?? 0,
            collectionUpdateTime: DateTime.now(),
            // 下载链接
            downloadLinks: _downloadLinks,
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
          if (mounted) {
            AppSnackBar.showError("操作失败,${e.toString()}");
          }

          // 新增：核心业务逻辑失败，触发异步删除已上传的图片
          // 不等待删除完成，防止阻塞用户界面
          widget.fileUpload.deleteUploadedImagesOnError(uploadedImageUrls);
          // 必须重新抛出，让 tryLockAsync 知道出错了
          rethrow;
        }
      },
      onLockFailed: () {
        // 锁定时（操作已在进行中）的回调
        //print("Operation ($operationKey) is already in progress.");
        if (mounted) {
          AppSnackBar.showInfo('操作正在进行中，请稍候...');
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
    // --- NEW: Determine canPop value ---
    // Block pop initially if processing OR if there are unsaved changes requiring confirmation
    bool hasUnsavedChanges = widget.game != null && _hasChanges();
    bool isAddModeWithContent = widget.game == null && !_isFormEmpty();
    // If processing, OR if there are changes that need confirmation, set canPop to false initially.
    final bool allowImmediatePop =
        !(_isProcessing || hasUnsavedChanges || isAddModeWithContent);

    final String? currentUserId = widget.currentUser?.id;

    if (currentUserId == null) {
      return const LoginPromptWidget();
    }

    // 使用 Stack 包裹，方便显示全局加载指示器
    return Stack(
      children: [
        PopScope<Object?>(
          canPop: allowImmediatePop,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              _handleBlockedPopAttempt();
            }
          },
          child: Form(
            key: _formKey,
            child: LazyLayoutBuilder(
              windowStateProvider: widget.windowStateProvider,
              builder: (context, constraints) {
                final screenSize = constraints.biggest;
                final isDesktop =
                    DeviceUtils.isDesktopInThisWidth(screenSize.width);
                _screenSize = screenSize;
                _isDesktop = isDesktop;
                return _isDesktop
                    ? _buildDesktopLayout(context, currentUserId)
                    : _buildMobileLayout(context, currentUserId);
              },
            ),
          ),
        ),
        // 使用 _isProcessing 控制 LoadingWidget.inline 的显示
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withSafeOpacity(0.1), // 半透明遮罩
              child: const LoadingWidget(), // 居中显示
            ),
          ),
      ],
    );
  }

  // --- NEW: Handler for pop attempts blocked by canPop: false ---
  Future<void> _handleBlockedPopAttempt() async {
    // First, check if it was blocked due to processing
    if (_isProcessing) {
      AppSnackBar.showInfo('正在处理中，请稍候...');

      return; // Do nothing more, pop remains blocked
    }

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
            await _saveDraftIfNecessary();
          } catch (e) {
            //
          } finally {
            // IMPORTANT: Manually trigger the pop now!
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        },

        onCancel: () {},
      );
    }
  }

  // --- 桌面布局构建 ---
  Widget _buildDesktopLayout(BuildContext context, String userId) {
    final desktopCardMaxHeight =
        MediaQuery.of(context).size.height - 120; // 留出更多边距
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 增大桌面边距
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
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
    return Container(
      color: Colors.white.withSafeOpacity(0.9),
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
    );
  }

  // --- 可重用字段构建器 ---

  // 分区标题
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: TextStyle(
            fontSize: _isDesktop ? 18 : 16, // 桌面端字号稍大
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
        GameCoverImageField(
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
      inputStateService: widget.inputStateService,
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: const InputDecoration(
        labelText: '游戏标题 *',
        hintText: '[会社名]游戏名',
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
      inputStateService: widget.inputStateService,
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
      inputStateService: widget.inputStateService,
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      decoration: InputDecoration(
        labelText: '详细描述 *',
        hintText: '详细介绍游戏背景等...',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Icon(Icons.description_outlined),
        ),
      ),
      minLines: _isDesktop ? 5 : 4,
      maxLength: 500,
      maxLines: _isDesktop ? 10 : 8,
      isEnabled: !_isProcessing,
      textInputAction: TextInputAction.newline,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入详细描述' : null,
    );
  }

  // 音乐链接字段
  Widget _buildMusicUrlField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
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
      inputStateService: widget.inputStateService,
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
        GameCategoryField(
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
    return GameTagsField(
      tags: _selectedTags,
      onChanged: (tags) => setState(() => _selectedTags = tags),
    );
  }

  // 下载链接字段
  Widget _buildDownloadLinksField() {
    return GameDownloadLinksField(
      inputStateService: widget.inputStateService,
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
      windowStateProvider: widget.windowStateProvider,
      sidebarProvider: widget.sidebarProvider,
      gameListFilterProvider: widget.gameListFilterProvider,
      gameCollectionService: widget.gameCollectionService,
      authProvider: widget.authProvider,
      gameService: widget.gameService,
      infoProvider: widget.infoProvider,
      inputStateService: widget.inputStateService,
      followService: widget.followService,
      currentUser: widget.currentUser,
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
}
