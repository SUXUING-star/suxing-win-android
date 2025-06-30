// lib/widgets/components/form/gameform/game_form.dart

/// 该文件定义了 GameForm 组件，用于添加或编辑游戏信息。
/// GameForm 封装了游戏表单的输入、验证、图片上传和草稿管理功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:image_picker/image_picker.dart'; // 图片选择器所需
import 'dart:io'; // 文件操作所需
import 'dart:async'; // 异步操作所需
import 'package:mongo_dart/mongo_dart.dart' as mongo; // MongoDB 对象ID生成所需
import 'package:collection/collection.dart'; // 集合比较工具所需
import 'package:path_provider/path_provider.dart'; // 路径提供者所需
import 'package:provider/provider.dart'; // Provider 状态管理所需

// --- 核心依赖 ---
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/models/game/game/game_download_link.dart';
import 'package:suxingchahui/models/game/game/game_external_link.dart';
import 'package:suxingchahui/models/game/game/game_form_data.dart'; // 游戏表单数据模型所需
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider 所需
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart'; // 游戏列表筛选 Provider 所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 侧边栏 Provider 所需
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务所需
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 窗口状态 Provider 所需
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart'; // 限速文件上传服务所需
import 'package:suxingchahui/services/form/game_form_cache_service.dart'; // 游戏表单缓存服务所需
import 'package:suxingchahui/services/main/game/game_collection_service.dart'; // 游戏收藏服务所需
import 'package:suxingchahui/services/main/game/game_service.dart'; // 游戏服务所需
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务所需
import 'package:suxingchahui/services/utils/request_lock_service.dart'; // 请求锁服务所需
import 'package:suxingchahui/widgets/components/form/gameform/field/game_external_links_form_field.dart'; // 游戏外部链接表单字段所需
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮所需
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart'; // 登录提示组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // 懒加载布局构建器所需
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 表单文本输入框所需
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 提示条组件所需

// --- UI 和辅助组件 ---
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件所需
import 'package:uuid/uuid.dart'; // UUID 生成器所需
import 'field/game_category_form_field.dart'; // 游戏分类表单字段所需
import 'field/game_cover_image_form_field.dart'; // 游戏封面图片表单字段所需
import 'field/game_download_links_form_field.dart'; // 游戏下载链接表单字段所需
import 'field/game_images_form_field.dart'; // 游戏图片表单字段所需
import 'field/game_tags_form_field.dart'; // 游戏标签表单字段所需
import 'preview/game_preview_button.dart'; // 游戏预览按钮所需

/// `GameForm` 类：游戏信息表单的 StatefulWidget。
///
/// 该组件用于添加或编辑游戏信息，并处理表单数据、图片上传和草稿管理。
class GameForm extends StatefulWidget {
  final WindowStateProvider windowStateProvider; // 窗口状态 Provider
  final GameService gameService; // 游戏服务
  final RateLimitedFileUpload fileUpload; // 文件上传服务
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final GameCollectionService gameCollectionService; // 游戏收藏服务
  final GameListFilterProvider gameListFilterProvider; // 游戏列表筛选 Provider
  final AuthProvider authProvider; // 认证 Provider
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息服务
  final InputStateService inputStateService; // 输入状态服务
  final Game? game; // 编辑时传入的游戏对象
  final User? currentUser; // 当前登录用户
  final Function(Game) onSubmit; // 提交成功后的回调

  /// 构造函数。
  const GameForm({
    super.key,
    this.game,
    required this.windowStateProvider,
    required this.sidebarProvider,
    required this.authProvider,
    required this.followService,
    required this.inputStateService,
    required this.fileUpload,
    required this.infoService,
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
  final _formKey = GlobalKey<FormState>(); // 表单全局键
  final _titleController = TextEditingController(); // 标题文本控制器
  final _summaryController = TextEditingController(); // 摘要文本控制器
  final _descriptionController = TextEditingController(); // 描述文本控制器
  final _musicUrlController = TextEditingController(); // 音乐 URL 文本控制器
  final _bvidController = TextEditingController(); // BV 号文本控制器

  final _titleFocusNode = FocusNode(); // 标题输入框焦点节点
  final _summaryFocusNode = FocusNode(); // 摘要输入框焦点节点
  final _descriptionFocusNode = FocusNode(); // 描述输入框焦点节点
  final _musicUrlFocusNode = FocusNode(); // 音乐 URL 输入框焦点节点
  final _bvidFocusNode = FocusNode(); // BV 号输入框焦点节点

  // --- 图片状态 ---
  dynamic _coverImageSource; // 封面图片来源
  List<dynamic> _gameImagesSources = []; // 游戏图片来源列表

  // --- 其他表单状态 ---
  List<GameDownloadLink> _downloadLinks = []; // 下载链接列表
  List<GameExternalLink> _externalLinks = []; // 外部链接列表
  String? _selectedCategory; // 选中分类
  List<String> _selectedTags = []; // 选中标签列表

  // --- 状态标志 ---
  bool _isProcessing = false; // 处理中状态
  bool _isDraftRestored = false; // 草稿是否已恢复标记

  // --- 验证错误信息 ---
  String? _coverImageError; // 封面图片错误信息
  String? _categoryError; // 分类错误信息

  // --- 草稿相关 ---
  String? _draftKey; // 当前表单使用的草稿键

  // --- 编辑模式下的初始状态，用于比较变更 ---
  Game? _initialGameData; // 初始游戏数据副本
  String? _initialCoverImageUrl; // 初始封面图片 URL
  List<String> _initialGameImageUrls = []; // 初始游戏图片 URL 列表
  String? _initialCategory; // 初始分类
  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记
  late final GameFormCacheService _cacheService; // 游戏表单缓存服务实例
  User? _currentUser; // 当前用户

  List<String> _availableTags = []; // 可用游戏标签列表

  bool _isTagsLoading = false; // 标签加载状态
  String? _tagsErrMsg; // 标签加载错误信息

  late Size _screenSize; // 屏幕尺寸
  late bool _isDesktop; // 是否为桌面布局

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    _currentUser = widget.currentUser; // 初始化当前用户
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies(); // 调用父类 didChangeDependencies
    if (!_hasInitializedDependencies) {
      _cacheService = context.read<GameFormCacheService>(); // 获取缓存服务
      _hasInitializedDependencies = true; // 标记依赖已初始化
    }
    if (_hasInitializedDependencies) {
      _screenSize = DeviceUtils.getScreenSize(context); // 获取屏幕尺寸
      _isDesktop =
          DeviceUtils.isDesktopInThisWidth(_screenSize.width); // 判断是否为桌面布局
      _draftKey = _getDraftKey(); // 获取当前模式的草稿键
      WidgetsBinding.instance.addObserver(this); // 添加 WidgetsBinding 观察者
      _initializeFormData(); // 初始化表单数据
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            // 检查组件是否挂载
            _loadTags(); // 加载标签
            _checkAndRestoreDraft(); // 检查并恢复草稿
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant GameForm oldWidget) {
    super.didUpdateWidget(oldWidget); // 调用父类 didUpdateWidget
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      // 当前用户变化时
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户
      });
    }
  }

  /// 获取当前表单对应的草稿键。
  ///
  /// 如果是编辑模式，则使用游戏ID生成草稿键；否则使用添加模式的固定草稿键。
  /// 返回草稿键字符串。
  String _getDraftKey() {
    if (widget.game != null && widget.game!.id.isNotEmpty) {
      // 编辑模式
      try {
        return _cacheService.getEditDraftKey(widget.game!.id); // 使用游戏ID生成编辑草稿键
      } catch (e) {
        return GameFormCacheService.addDraftKey; // 出现异常时使用添加模式的固定草稿键作为后备
      }
    } else {
      // 添加模式
      return GameFormCacheService.addDraftKey; // 使用添加模式的固定草稿键
    }
  }

  @override
  void dispose() {
    _saveDraftIfNecessary(); // 必要时保存草稿

    WidgetsBinding.instance.removeObserver(this); // 移除 WidgetsBinding 观察者
    _titleController.dispose(); // 销毁标题文本控制器
    _summaryController.dispose(); // 销毁摘要文本控制器
    _descriptionController.dispose(); // 销毁描述文本控制器
    _musicUrlController.dispose(); // 销毁音乐 URL 文本控制器
    _bvidController.dispose(); // 销毁 BV 号文本控制器
    super.dispose(); // 调用父类 dispose
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); // 调用父类 didChangeAppLifecycleState
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 应用暂停或分离时
      Future.microtask(() async {
        // 异步执行草稿保存
        if (mounted) {
          // 检查组件是否挂载
          await _saveDraftIfNecessary(); // 必要时保存草稿
        }
      });
    }
  }

  /// 加载标签。
  Future<void> _loadTags() async {
    if (_isTagsLoading) {
      // 标签正在加载中时退出
      return;
    }
    setState(() {
      _isTagsLoading = true; // 设置为标签加载中状态
      _tagsErrMsg = null; // 清除标签错误消息
    });
    try {
      final tags =
          await widget.gameService.getAllAvailableGameTags(); // 获取所有可用游戏标签
      if (mounted) setState(() => _availableTags = tags); // 更新可用标签列表
    } catch (e) {
      if (mounted) {
        // 检查组件是否挂载
        setState(() {
          _availableTags = []; // 错误时清空标签列表
          _tagsErrMsg = e.toString(); // 设置标签错误消息
        });
      }
    } finally {
      setState(() {
        _isTagsLoading = false; // 清除标签加载状态
      });
    }
  }

  /// 保存草稿并退出页面。
  Future<void> _saveDraftAndExit() async {
    if (_draftKey == null) {
      // 草稿键无效时退出
      if (mounted) AppSnackBar.showError("无法保存草稿"); // 显示错误提示
      return;
    }

    try {
      await _performSaveDraft(); // 执行草稿保存操作

      AppSnackBar.showSuccess('草稿已保存'); // 显示保存成功提示
      await Future.delayed(const Duration(milliseconds: 500)); // 延迟一段时间
      if (mounted) {
        // 检查组件是否挂载
        Navigator.pop(context); // 退出当前页面
      }
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    }
  }

  /// 初始化表单数据。
  ///
  /// 重置所有表单状态，如果为编辑模式，则加载现有游戏数据。
  void _initializeFormData() {
    // 重置所有状态
    _coverImageSource = null;
    _gameImagesSources = [];
    _downloadLinks = [];
    _externalLinks = [];
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
    _initialGameData = null; // 重置初始游戏数据
    _initialCoverImageUrl = null;
    _initialGameImageUrls = [];

    if (widget.game != null) {
      // 编辑模式，加载现有数据
      final game = widget.game!;
      _initialGameData = game.copyWith(); // 复制初始游戏数据

      _titleController.text = game.title; // 设置标题
      _summaryController.text = game.summary; // 设置摘要
      _descriptionController.text = game.description; // 设置描述
      _musicUrlController.text = game.musicUrl ?? ''; // 设置音乐 URL
      _bvidController.text = game.bvid ?? ''; // 设置 BV 号

      _initialCoverImageUrl =
          game.coverImage.isNotEmpty ? game.coverImage : null; // 初始封面图片 URL
      _coverImageSource = _initialCoverImageUrl; // 表单状态也初始化为 URL 或 null

      _initialGameImageUrls = List<String>.from(game.images); // 初始游戏图片 URL 列表
      _gameImagesSources = List<dynamic>.from(game.images); // 表单状态初始化为 URL 列表

      _downloadLinks = List<GameDownloadLink>.from(game.downloadLinks
          .map((link) => GameDownloadLink.fromJson(link.toJson()))); // 复制下载链接
      _externalLinks = List<GameExternalLink>.from(game.externalLinks
          .map((link) => GameExternalLink.fromJson(link.toJson()))); // 复制外部链接
      final categoriesList = game.category
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _selectedCategory =
          categoriesList.isNotEmpty ? categoriesList.first : null; // 设置选中分类
      _initialCategory = _selectedCategory; // 保存初始分类

      _selectedTags = List<String>.from(game.tags); // 复制选中标签列表
    }
  }

  /// 处理取消恢复草稿操作。
  ///
  /// 清除 Hive 中的草稿数据和关联的本地文件。
  Future<void> _handleCancelRestoreDraft() async {
    if (_draftKey == null) {
      // 草稿键无效时退出
      return;
    }

    GameFormDraft? draftToDiscard; // 待丢弃的草稿数据
    try {
      draftToDiscard = await _cacheService.loadDraft(_draftKey!); // 加载待丢弃的草稿数据

      await _cacheService.clearDraft(_draftKey!); // 清除 Hive 中的草稿

      await _deleteDraftFiles(draftToDiscard); // 删除关联的本地文件
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    }
  }

  /// 检查并恢复草稿。
  ///
  /// 如果存在草稿，则显示确认对话框，允许用户恢复或丢弃草稿。
  Future<void> _checkAndRestoreDraft() async {
    if (_isDraftRestored || _draftKey == null || _isProcessing || !mounted) {
      // 不满足条件时退出
      return;
    }

    bool hasDraft = await _cacheService.hasDraft(_draftKey!); // 检查是否存在草稿
    if (hasDraft && mounted) {
      // 存在草稿且组件挂载时
      try {
        await CustomConfirmDialog.show(
          context: context,
          title: '恢复草稿', // 对话框标题
          message: widget.game != null
              ? '检测到游戏 "${widget.game!.title}" 上次未完成的编辑，是否恢复？'
              : '检测到上次未完成的游戏添加草稿，是否恢复？', // 对话框消息
          confirmButtonText: '恢复', // 确认按钮文本
          cancelButtonText: '丢弃', // 取消按钮文本
          iconData: Icons.history, // 图标
          iconColor: Colors.orange, // 图标颜色
          confirmButtonColor: Theme.of(context).primaryColor, // 确认按钮颜色
          barrierDismissible: false, // 不允许点击外部关闭

          onConfirm: () async {
            // 确认回调：恢复草稿
            await _loadAndApplyDraft(); // 加载并应用草稿
            setState(() {
              _isDraftRestored = true; // 标记草稿已恢复
            });
            AppSnackBar.showSuccess('草稿已恢复'); // 显示成功提示
          },

          onCancel: _handleCancelRestoreDraft, // 取消回调：清除草稿
        );
      } catch (e) {
        // 捕获对话框处理异常
        AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
        try {
          await _cacheService.clearDraft(_draftKey!); // 尝试清除草稿
        } catch (clearError) {
          // 清除草稿失败
        }
      }
    }
  }

  /// 加载并应用草稿数据到表单。
  Future<void> _loadAndApplyDraft() async {
    if (_draftKey == null) return; // 草稿键无效时退出
    setState(() => _isProcessing = true); // 设置为处理中状态

    try {
      final draft = await _cacheService.loadDraft(_draftKey!); // 加载草稿数据
      if (draft != null && mounted) {
        // 存在草稿且组件挂载时
        _titleController.text = draft.title; // 设置标题
        _summaryController.text = draft.summary; // 设置摘要
        _descriptionController.text = draft.description; // 设置描述
        _musicUrlController.text = draft.musicUrl ?? ''; // 设置音乐 URL
        _bvidController.text = draft.bvid ?? ''; // 设置 BV 号
        _selectedCategory = draft.selectedCategory; // 设置选中分类
        _selectedTags = List<String>.from(draft.selectedTags); // 设置选中标签
        _downloadLinks = draft.downloadLinks
            .map((map) => GameDownloadLink.fromJson(map))
            .toList(); // 设置下载链接
        _externalLinks = draft.externalLinks
            .map((map) => GameExternalLink.fromJson(map))
            .toList(); // 设置外部链接

        dynamic restoredCoverSource; // 恢复的封面图片来源
        final coverPathOrUrl = draft.coverImageUrl; // 草稿中的封面图片路径或 URL
        if (coverPathOrUrl != null && coverPathOrUrl.isNotEmpty) {
          final appDocDir =
              await getApplicationDocumentsDirectory(); // 获取应用文档目录
          if (coverPathOrUrl.startsWith(appDocDir.path) &&
              await File(coverPathOrUrl).exists()) {
            restoredCoverSource = File(coverPathOrUrl); // 恢复为 File 对象
          } else if (coverPathOrUrl.startsWith('http')) {
            restoredCoverSource = coverPathOrUrl; // 恢复为 URL 字符串
          } else {
            restoredCoverSource = null; // 路径无效或文件不存在
          }
        } else {
          restoredCoverSource = null; // 未保存图片
        }
        _coverImageSource = restoredCoverSource; // 更新封面图片来源

        List<dynamic> restoredGameImageSources = []; // 恢复的游戏图片来源列表
        final appDocDir = await getApplicationDocumentsDirectory(); // 获取应用文档目录
        for (final pathOrUrl in draft.gameImageUrls) {
          if (pathOrUrl.isNotEmpty) {
            if (pathOrUrl.startsWith(appDocDir.path) &&
                await File(pathOrUrl).exists()) {
              restoredGameImageSources.add(File(pathOrUrl)); // 恢复为 File 对象
            } else if (pathOrUrl.startsWith('http')) {
              restoredGameImageSources.add(pathOrUrl); // 恢复为 URL 字符串
            }
          }
        }
        _gameImagesSources = restoredGameImageSources; // 更新游戏图片来源列表

        _coverImageError = null; // 清除封面图片错误
        _categoryError = null; // 清除分类错误
        setState(() {}); // 触发 UI 更新
      }
    } catch (e) {
      // 捕获加载草稿异常
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    } finally {
      if (mounted) {
        // 检查组件是否挂载
        setState(() => _isProcessing = false); // 清除处理中状态
      }
    }
  }

  /// 删除草稿关联的本地文件。
  ///
  /// [draft]：草稿数据对象，包含文件路径。
  Future<void> _deleteDraftFiles(GameFormDraft? draft) async {
    if (draft == null) return; // 草稿数据为空时退出

    List<String> pathsToDelete = []; // 待删除文件路径列表
    final Directory appDocDir =
        await getApplicationDocumentsDirectory(); // 获取应用文档目录
    final String draftImageBasePath =
        '${appDocDir.path}/suxingchahui/draft_images'; // 草稿图片基础路径

    if (draft.coverImageUrl != null &&
        !draft.coverImageUrl!.startsWith('http') &&
        draft.coverImageUrl!.startsWith(draftImageBasePath)) {
      pathsToDelete.add(draft.coverImageUrl!); // 添加封面图片路径
    }

    pathsToDelete.addAll(draft.gameImageUrls.where((path) =>
        !path.startsWith('http') &&
        path.startsWith(draftImageBasePath))); // 添加游戏截图路径

    if (pathsToDelete.isEmpty) {
      return; // 没有本地草稿文件可删除时退出
    }

    for (String path in pathsToDelete) {
      try {
        final file = File(path);
        if (await file.exists()) {
          // 文件存在时删除
          await file.delete();
        }
      } catch (e) {
        // 捕获文件删除异常
      }
    }
  }

  /// 必要时保存草稿。
  ///
  /// 根据模式（添加/编辑）和表单内容决定是否保存草稿。
  Future<void> _saveDraftIfNecessary() async {
    if (_isProcessing || _draftKey == null || !mounted) {
      // 正在处理、草稿键无效或组件未挂载时退出
      return;
    }

    bool shouldSave = false; // 是否应该保存草稿
    try {
      if (widget.game != null) {
        // 编辑模式
        if (_hasChanges()) {
          // 存在改动时保存
          shouldSave = true;
        }
      } else {
        // 添加模式
        if (!_isFormEmpty()) {
          // 表单非空时保存
          shouldSave = true;
        } else {
          await _cacheService.clearDraft(_draftKey!); // 表单为空时清除旧草稿
        }
      }

      if (shouldSave) {
        // 如果应该保存草稿
        await _performSaveDraft(); // 执行草稿保存操作
      }
    } catch (e) {
      // 捕获保存草稿异常
    }
  }

  /// 获取文件扩展名。
  String _getFileExtension(String filePath) {
    try {
      return filePath.substring(filePath.lastIndexOf('.')); // 从文件路径中提取扩展名
    } catch (e) {
      return '.jpg'; // 解析失败时返回默认扩展名
    }
  }

  /// 复制草稿图片到持久化存储。
  ///
  /// [sourceFile]：源图片文件。
  /// 返回持久化存储路径。
  Future<String?> _copyDraftImage(XFile sourceFile) async {
    try {
      final Directory appDocDir =
          await getApplicationDocumentsDirectory(); // 获取应用文档目录
      final String draftImagesDirPath =
          '${appDocDir.path}/suxingchahui/draft_images'; // 草稿图片目录
      await Directory(draftImagesDirPath).create(recursive: true); // 创建目录

      final String uniqueFileName =
          '${const Uuid().v4()}${_getFileExtension(sourceFile.path)}'; // 生成唯一文件名
      final String persistentPath =
          '$draftImagesDirPath/$uniqueFileName'; // 构建持久化路径

      final File sourceIoFile = File(sourceFile.path); // 创建 File 对象
      await sourceIoFile.copy(persistentPath); // 复制文件

      return persistentPath; // 返回新的持久化路径
    } catch (e) {
      // 捕获复制图片异常
      return null; // 复制失败时返回 null
    }
  }

  /// 执行草稿保存操作。
  Future<void> _performSaveDraft() async {
    if (_draftKey == null || !mounted) return; // 草稿键无效或组件未挂载时退出

    String? coverImageToSave; // 待保存的封面图片路径或 URL
    if (_coverImageSource is String) {
      coverImageToSave = _coverImageSource as String; // 现有 URL
    } else if (_coverImageSource is XFile) {
      coverImageToSave =
          await _copyDraftImage(_coverImageSource as XFile); // 复制 XFile 到持久存储
    } else if (_coverImageSource is File) {
      coverImageToSave = (_coverImageSource as File).path; // 已是 File 对象时保存其路径
    } else {
      coverImageToSave = null; // 无图片
    }

    List<String> gameImagesToSave = []; // 待保存的游戏图片路径或 URL 列表
    for (final source in _gameImagesSources) {
      String? imagePath;
      if (source is String) {
        imagePath = source; // 现有 URL
      } else if (source is XFile) {
        imagePath = await _copyDraftImage(source); // 复制 XFile 到持久存储
      } else if (source is File) {
        imagePath = (source).path; // 已是 File 对象时保存其路径
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        gameImagesToSave.add(imagePath); // 添加有效的图片路径或 URL
      }
    }

    final draft = GameFormDraft(
      draftKey: _draftKey!, // 草稿键
      title: _titleController.text.trim(), // 标题
      summary: _summaryController.text.trim(), // 摘要
      description: _descriptionController.text.trim(), // 描述
      musicUrl: _musicUrlController.text.trim().isEmpty
          ? null
          : _musicUrlController.text.trim(), // 音乐 URL
      bvid: _bvidController.text.trim().isEmpty
          ? null
          : _bvidController.text.trim(), // BV 号
      coverImageUrl: coverImageToSave, // 封面图片 URL 或路径
      gameImageUrls: gameImagesToSave, // 游戏图片 URL 或路径列表
      downloadLinks:
          _downloadLinks.map((link) => link.toJson()).toList(), // 下载链接列表
      externalLinks:
          _externalLinks.map((link) => link.toJson()).toList(), // 外部链接列表
      selectedCategory: _selectedCategory, // 选中分类
      selectedTags: List<String>.from(_selectedTags), // 选中标签列表
      lastSaved: DateTime.now(), // 最后保存时间
    );

    try {
      await _cacheService.saveDraft(_draftKey!, draft); // 保存草稿
    } catch (e) {
      // 捕获保存草稿异常
      AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
    }
  }

  /// 检查表单是否为空。
  ///
  /// 用于添加模式，判断表单是否没有任何有效输入。
  bool _isFormEmpty() {
    bool textFieldsEmpty = _titleController.text.trim().isEmpty && // 检查文本字段是否为空
        _summaryController.text.trim().isEmpty &&
        _descriptionController.text.trim().isEmpty &&
        _musicUrlController.text.trim().isEmpty &&
        _bvidController.text.trim().isEmpty;

    bool coverEmpty = _coverImageSource == null; // 检查封面图片是否为空
    bool gameImagesEmpty = _gameImagesSources.nonNulls.isEmpty; // 检查游戏截图列表是否为空

    bool listsEmpty = _downloadLinks.isEmpty && // 检查列表是否为空
        _externalLinks.isEmpty &&
        _selectedCategory == null &&
        _selectedTags.isEmpty;

    return textFieldsEmpty &&
        coverEmpty &&
        gameImagesEmpty &&
        listsEmpty; // 所有字段都为空时返回 true
  }

  /// 检查表单内容是否已更改。
  ///
  /// 用于编辑模式，比较当前表单内容与初始游戏数据。
  bool _hasChanges() {
    if (widget.game == null || _initialGameData == null) {
      // 非编辑模式或初始数据丢失时返回 false
      return false;
    }
    final initial = _initialGameData!; // 初始游戏数据
    final eq = const DeepCollectionEquality(); // 用于深度比较 List<Map>

    if (_titleController.text.trim() != initial.title || // 比较标题
        _summaryController.text.trim() != initial.summary || // 比较摘要
        _descriptionController.text.trim() != initial.description || // 比较描述
        (_musicUrlController.text.trim().isEmpty
                ? null
                : _musicUrlController.text.trim()) !=
            initial.musicUrl || // 比较音乐 URL
        (_bvidController.text.trim().isEmpty
                ? null
                : _bvidController.text.trim()) !=
            initial.bvid) {
      // 比较 BV 号
      return true;
    }

    if (_coverImageSource is XFile) {
      // 新选了本地文件，表示更改
      return true;
    }
    final currentCoverUrl = (_coverImageSource is String)
        ? _coverImageSource as String
        : null; // 获取当前封面图片 URL
    if (currentCoverUrl != _initialCoverImageUrl) {
      // 比较当前封面 URL 与初始 URL
      return true;
    }

    if (_gameImagesSources.any((s) => s is XFile)) {
      // 检查是否有新添加的本地文件
      return true;
    }
    final currentGameImageUrls =
        _gameImagesSources.whereType<String>().toList(); // 获取当前图片 URL 列表
    if (!const ListEquality()
        .equals(currentGameImageUrls, _initialGameImageUrls)) {
      // 比较当前图片 URL 列表与初始列表
      return true;
    }

    if (_selectedCategory != _initialCategory) {
      // 比较选中分类与初始分类
      return true;
    }

    final currentTagsSet = _selectedTags.toSet(); // 当前标签集合
    final initialTagsSet = initial.tags.toSet(); // 初始标签集合
    if (!const SetEquality().equals(currentTagsSet, initialTagsSet)) {
      // 比较标签集合
      return true;
    }

    final currentLinksJson =
        _downloadLinks.map((l) => l.toJson()).toList(); // 当前下载链接 JSON 列表
    final initialLinksJson =
        initial.downloadLinks.map((l) => l.toJson()).toList(); // 初始下载链接 JSON 列表
    if (!eq.equals(currentLinksJson, initialLinksJson)) {
      // 比较下载链接 JSON 列表
      return true;
    }
    final currentExternalLinksJson =
        _externalLinks.map((l) => l.toJson()).toList(); // 当前外部链接 JSON 列表
    final initialExternalLinksJson =
        initial.externalLinks.map((l) => l.toJson()).toList(); // 初始外部链接 JSON 列表
    if (!eq.equals(currentExternalLinksJson, initialExternalLinksJson)) {
      // 比较外部链接 JSON 列表
      return true;
    }

    return false; // 没有更改时返回 false
  }

  /// 验证表单内容。
  ///
  /// 返回 true 表示验证通过，false 表示验证失败。
  bool _validateForm() {
    bool isTextValid = _formKey.currentState?.validate() ?? false; // 验证文本字段

    bool isValid; // 整体验证结果
    final isValidMes = _validateGameFieldsBeforeRequest(); // 执行额外字段验证
    if (isValidMes != null) {
      // 存在验证错误
      isValid = false;
      if (context.mounted) {
        // 检查组件是否挂载
        AppSnackBar.showWarning(isValidMes); // 显示警告提示
      }
    } else {
      isValid = true;
    }

    return isTextValid && isValid; // 返回最终验证结果
  }

  /// 处理封面图片变化。
  ///
  /// [newSource]：新的图片来源。
  void _handleCoverImageChange(dynamic newSource) {
    setState(() {
      _coverImageSource = newSource; // 更新封面图片来源
      if (_coverImageSource is XFile ||
          (_coverImageSource is String &&
              (_coverImageSource as String).isNotEmpty)) {
        _coverImageError = null; // 清除错误信息
      }
    });
  }

  /// 处理游戏图片列表变化。
  ///
  /// [newSourcesList]：新的图片来源列表。
  void _handleGameImagesChange(List<dynamic> newSourcesList) {
    setState(() {
      _gameImagesSources = newSourcesList; // 更新游戏图片来源列表
    });
  }

  /// 验证游戏字段。
  ///
  /// 返回 null 表示验证通过，否则返回错误信息字符串。
  String? _validateGameFieldsBeforeRequest() {
    final title = _titleController.text.trim(); // 获取标题
    if (title.isEmpty || title.length < 2 || title.length > 100) {
      // 验证标题长度
      return '标题不能为空，且长度需在2到100字之间。';
    }

    final summary = _summaryController.text.trim(); // 获取摘要
    if (summary.isEmpty || summary.length < 2 || summary.length > 500) {
      // 验证摘要长度
      return '摘要不能为空，且长度需在2到500字之间。';
    }

    final description = _descriptionController.text.trim(); // 获取详细描述
    if (description.isEmpty ||
        description.length < 2 ||
        description.length > 1000) {
      // 验证详细描述长度
      return '详细描述不能为空，且长度需在2到1000字之间。';
    }

    final tags = _selectedTags; // 获取选中标签
    if (tags.length > 5) {
      // 验证标签数量
      return '标签数量不能超过5个。';
    }

    for (final tag in tags) {
      // 验证每个标签的长度
      if (tag.length > 8) {
        return '每个标签的长度不能超过8个字，标签: $tag。';
      }
    }

    final musicUrl = _musicUrlController.text.trim(); // 获取音乐 URL
    if (musicUrl.isNotEmpty) {
      final parsedUri = Uri.tryParse(musicUrl); // 解析 URL
      if (parsedUri == null ||
          !parsedUri.hasScheme ||
          !parsedUri.hasAuthority) {
        // 验证 URL 结构
        return '音乐URL格式非法，无法解析。';
      }
      if (parsedUri.host != 'music.163.com') {
        // 验证域名
        return '音乐URL域名不正确，请提供网易云音乐域名下的链接。';
      }
    }
    final bvid = _bvidController.text.trim(); // 获取 BV 号
    if (bvid.isNotEmpty) {
      final bvidRegex = RegExp(r'^BV[0-9a-zA-Z]{10}$'); // BV 号正则表达式
      if (!bvidRegex.hasMatch(bvid)) {
        // 验证 BV 号格式
        return 'B站视频BV号格式不正确，应为"BV"开头加10位字母数字。';
      }
    }

    bool hasCover = _coverImageSource != null; // 检查是否存在封面图片
    bool hasCategory = _selectedCategory != null; // 检查是否选择了分类
    int imagesLength = _gameImagesSources.length; // 获取游戏图片数量

    if (!hasCover) {
      // 封面图片缺失时设置错误
      setState(() {
        _coverImageError = hasCover ? null : '请添加封面图片';
      });
      return '请添加封面图片';
    }

    if (imagesLength > 3) {
      // 游戏图片数量超过限制
      return '图片太多，最多3张';
    }

    if (!hasCategory) {
      // 分类缺失时设置错误
      setState(() {
        _categoryError = hasCategory ? null : '请选择一个分类';
      });
      return '请选择一个分类';
    }

    return null; // 验证通过
  }

  /// 提交表单数据。
  ///
  /// [userId]：当前用户ID。
  /// 处理图片上传、构建游戏对象并调用提交回调。
  Future<void> _submitForm(String userId) async {
    List<String> uploadedImageUrls = []; // 已上传的图片 URL 列表
    if (!_validateForm()) {
      // 表单验证失败时退出
      return;
    }

    final operationKey = widget.game?.id != null && widget.game!.id.isNotEmpty
        ? 'edit_game_${widget.game!.id}'
        : 'add_game'; // 操作锁键

    if (mounted) setState(() => _isProcessing = true); // 设置为处理中状态

    bool actionExecuted = await RequestLockService.instance.tryLockAsync(
      // 尝试获取操作锁
      operationKey,
      action: () async {
        // 锁获取成功后执行的操作
        String? finalCoverImageUrl; // 最终封面图片 URL
        List<String> finalGameImagesUrls = []; // 最终游戏图片 URL 列表

        try {
          final dynamic currentCoverSource = _coverImageSource; // 当前封面图片来源
          if (currentCoverSource is XFile) {
            // XFile 类型，需要上传
            final fileToUpload = File(currentCoverSource.path);
            finalCoverImageUrl = await widget.fileUpload
                .uploadImage(fileToUpload, folder: 'games/covers'); // 上传封面图片
            if (finalCoverImageUrl.isEmpty) {
              // 上传失败
              throw Exception("上传失败");
            }
          } else if (currentCoverSource is File) {
            // File 类型，需要上传
            finalCoverImageUrl = await widget.fileUpload.uploadImage(
                currentCoverSource,
                folder: 'games/covers'); // 上传封面图片
            if (finalCoverImageUrl.isEmpty) {
              // 上传失败
              throw Exception("封面图上传失败");
            }
          } else if (currentCoverSource is String &&
              currentCoverSource.isNotEmpty) {
            // String 类型，直接使用
            finalCoverImageUrl = currentCoverSource; // 使用现有 URL
          } else {
            // 图片不合法
            if (mounted) {
              // 检查组件是否挂载
              setState(() {
                _isProcessing = false; // 清除处理中状态
              });
            }
            throw Exception("图片不合法");
          }

          final List<dynamic> currentImageSources =
              List.from(_gameImagesSources); // 当前游戏图片来源列表
          final List<File> filesToUpload = []; // 待上传文件列表
          final List<int> xFileIndices = []; // 记录 XFile 在原列表中的索引
          final List<String?> tempFinalUrls =
              List.filled(currentImageSources.length, null); // 临时 URL 列表

          for (int i = 0; i < currentImageSources.length; i++) {
            // 遍历图片来源
            final source = currentImageSources[i];
            if (source is XFile) {
              // XFile 类型
              filesToUpload.add(File(source.path)); // 添加到待上传列表
              xFileIndices.add(i); // 记录索引
            } else if (source is File) {
              // File 类型
              filesToUpload.add(source); // 添加到待上传列表
              xFileIndices.add(i); // 记录索引
            } else if (source is String && source.isNotEmpty) {
              // String 类型
              tempFinalUrls[i] = source; // 直接放入临时列表
            }
          }

          List<String> uploadedUrls = []; // 已上传的图片 URL 列表
          if (filesToUpload.isNotEmpty) {
            // 存在待上传文件
            uploadedUrls = await widget.fileUpload.uploadImages(filesToUpload,
                folder: 'games/screenshots'); // 上传图片
            if (uploadedUrls.length != filesToUpload.length) {
              // 上传数量不匹配
              throw Exception("图片上传部分失败");
            }
            int uploadedIndex = 0;
            for (int originalIndex in xFileIndices) {
              // 将上传后的 URL 填回临时列表
              if (uploadedIndex < uploadedUrls.length) {
                tempFinalUrls[originalIndex] = uploadedUrls[uploadedIndex];
                uploadedIndex++;
              }
            }
          }

          finalGameImagesUrls =
              tempFinalUrls.whereType<String>().toList(); // 最终游戏图片 URL 列表

          if (finalCoverImageUrl.isNotEmpty) {
            // 添加封面图片 URL
            uploadedImageUrls.add(finalCoverImageUrl);
          }
          uploadedImageUrls.addAll(finalGameImagesUrls); // 添加游戏图片 URL

          final game = Game(
            // 构建 Game 对象
            id: widget.game?.id ?? mongo.ObjectId().oid, // 游戏 ID
            authorId: widget.game?.authorId ?? userId, // 作者 ID
            title: _titleController.text.trim(), // 标题
            summary: _summaryController.text.trim(), // 摘要
            description: _descriptionController.text.trim(), // 描述
            category: _selectedCategory ?? '', // 分类
            coverImage: finalCoverImageUrl, // 封面图片
            images: finalGameImagesUrls, // 游戏图片
            tags: List<String>.from(_selectedTags), // 标签
            rating: widget.game?.rating ?? 0.0, // 评分
            totalRatingSum: widget.game?.totalRatingSum ?? 0.0, // 总评分和
            ratingCount: widget.game?.ratingCount ?? 0, // 评分人数
            createTime: widget.game?.createTime ?? DateTime.now(), // 创建时间
            updateTime: DateTime.now(), // 更新时间
            viewCount: widget.game?.viewCount ?? 0, // 浏览次数
            likeCount: widget.game?.likeCount ?? 0, // 点赞数
            wantToPlayCount: widget.game?.wantToPlayCount ?? 0, // 想玩数量
            playingCount: widget.game?.playingCount ?? 0, // 正在玩数量
            playedCount: widget.game?.playedCount ?? 0, // 已玩数量
            totalCollections: widget.game?.totalCollections ?? 0, // 总收藏数量
            collectionUpdateTime: DateTime.now(), // 收藏更新时间
            downloadLinks: _downloadLinks, // 下载链接
            externalLinks: _externalLinks, // 外部链接
            musicUrl: _musicUrlController.text.trim().isEmpty
                ? null
                : _musicUrlController.text.trim(), // 音乐 URL
            bvid: _bvidController.text.trim().isEmpty
                ? null
                : _bvidController.text.trim(), // BV 号
            lastViewedAt: widget.game?.lastViewedAt, // 最后查看时间
          );

          await widget.onSubmit(game); // 调用外部提交回调

          if (_draftKey != null) {
            // 清除草稿
            GameFormDraft? draftBeforeDeletion; // 删除前的草稿数据
            try {
              draftBeforeDeletion =
                  await _cacheService.loadDraft(_draftKey!); // 加载草稿数据

              await _cacheService.clearDraft(_draftKey!); // 清除 Hive 中的草稿

              await _deleteDraftFiles(draftBeforeDeletion); // 删除对应的文件
            } catch (e) {
              // 捕获草稿清理异常
              if (mounted) {}
            }
          }
        } catch (e) {
          // 捕获操作内部错误
          if (mounted) {
            // 检查组件是否挂载
            AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
          }

          widget.fileUpload
              .deleteUploadedImagesOnError(uploadedImageUrls); // 异步删除已上传的图片
          rethrow; // 重新抛出异常
        }
      },
      onLockFailed: () {
        // 获取锁失败时的回调
        if (mounted) {
          // 检查组件是否挂载
          AppSnackBar.showInfo('操作正在进行中，请稍候'); // 显示提示
        }
        if (mounted) {
          // 检查组件是否挂载
          setState(() => _isProcessing = false); // 重置处理中状态
        }
      },
    );

    if (actionExecuted && mounted) {
      // 操作执行完毕且组件挂载时
      setState(() => _isProcessing = false); // 清除处理中状态
    }
  }

  /// 构建 UI。
  @override
  Widget build(BuildContext context) {
    bool hasUnsavedChanges = widget.game != null && _hasChanges(); // 是否存在未保存的修改
    bool isAddModeWithContent =
        widget.game == null && !_isFormEmpty(); // 添加模式下表单是否有内容
    final bool allowImmediatePop = !(_isProcessing ||
        hasUnsavedChanges ||
        isAddModeWithContent); // 是否允许立即弹出页面

    final String? currentUserId = widget.currentUser?.id; // 当前用户ID

    if (currentUserId == null) {
      // 无用户ID时显示登录提示
      return const LoginPromptWidget();
    }

    return Stack(
      // 使用 Stack 包裹，方便显示全局加载指示器
      children: [
        PopScope<Object?>(
          canPop: allowImmediatePop, // 控制是否允许弹出页面
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              // 页面未弹出时
              _handleBlockedPopAttempt(); // 处理被阻止的弹出尝试
            }
          },
          child: Form(
            key: _formKey, // 表单键
            child: LazyLayoutBuilder(
              windowStateProvider: widget.windowStateProvider, // 窗口状态 Provider
              builder: (context, constraints) {
                final screenSize = constraints.biggest; // 屏幕尺寸
                final isDesktop = DeviceUtils.isDesktopInThisWidth(
                    screenSize.width); // 判断是否为桌面布局
                _screenSize = screenSize; // 更新屏幕尺寸
                _isDesktop = isDesktop; // 更新桌面布局标记
                return _isDesktop
                    ? _buildDesktopLayout(context, currentUserId) // 桌面布局
                    : _buildMobileLayout(context, currentUserId); // 移动布局
              },
            ),
          ),
        ),
        if (_isProcessing) // 正在处理时显示加载指示器
          Positioned.fill(
            child: Container(
              color: Colors.black.withSafeOpacity(0.1), // 半透明遮罩
              child: const LoadingWidget(), // 居中显示加载指示器
            ),
          ),
      ],
    );
  }

  /// 处理被阻止的弹出尝试。
  Future<void> _handleBlockedPopAttempt() async {
    if (_isProcessing) {
      // 正在处理时显示提示
      AppSnackBar.showInfo('正在处理中，请稍候');
      return;
    }

    bool hasUnsavedChanges = widget.game != null && _hasChanges(); // 是否有未保存的修改
    bool isAddModeWithContent =
        widget.game == null && !_isFormEmpty(); // 添加模式下表单是否有内容

    if (hasUnsavedChanges || isAddModeWithContent) {
      // 存在未保存修改或表单有内容时显示确认对话框
      CustomConfirmDialog.show(
        context: context,
        title: '离开页面?', // 对话框标题
        message: hasUnsavedChanges
            ? '您有未保存的修改。如果离开，修改将丢失，但会尝试保存为草稿。确定离开吗？'
            : '您填写的内容尚未提交。如果离开，会尝试保存为草稿。确定离开吗？', // 对话框消息
        confirmButtonText: '确定离开', // 确认按钮文本
        cancelButtonText: '取消', // 取消按钮文本
        iconData: Icons.warning_amber_rounded, // 警告图标
        iconColor: Colors.amber, // 图标颜色
        confirmButtonColor: Colors.red, // 确认按钮颜色
        barrierDismissible: false, // 不允许点击外部关闭

        onConfirm: () async {
          // 确认离开回调
          try {
            await _saveDraftIfNecessary(); // 必要时保存草稿
          } catch (e) {
            // 捕获保存草稿异常
          } finally {
            if (mounted && Navigator.canPop(context)) {
              // 页面可弹出时手动弹出
              Navigator.of(context).pop();
            }
          }
        },

        onCancel: () {}, // 取消回调
      );
    }
  }

  /// 构建桌面布局。
  ///
  /// [context]：Build 上下文。
  /// [userId]：用户ID。
  /// 返回一个包含媒体与链接和基础信息与分类标签部分的桌面布局。
  Widget _buildDesktopLayout(BuildContext context, String userId) {
    final desktopCardMaxHeight =
        MediaQuery.of(context).size.height - 120; // 桌面卡片最大高度
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 桌面边距
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Card(
                // 左侧卡片：媒体与链接
                elevation: 3, // 阴影
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ConstrainedBox(
                  // 限制最大高度
                  constraints: BoxConstraints(maxHeight: desktopCardMaxHeight),
                  child: SingleChildScrollView(
                    // 允许卡片内部滚动
                    padding: const EdgeInsets.all(20.0), // 内边距
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('媒体与链接'), // 标题
                        const SizedBox(height: 20), // 垂直间距
                        _buildCoverImageSection(), // 封面图片部分
                        const SizedBox(height: 28), // 垂直间距
                        _buildGameImagesSection(), // 游戏图片部分
                        const SizedBox(height: 28), // 垂直间距
                        _buildDownloadLinksField(), // 下载链接字段
                        const SizedBox(height: 28), // 垂直间距
                        _buildExternalLinksField(), // 外部链接字段
                        const SizedBox(height: 28), // 垂直间距
                        _buildMusicUrlField(), // 音乐 URL 字段
                        const SizedBox(height: 20), // 垂直间距
                        _buildBvidField(), // BV 号字段
                        const SizedBox(height: 20), // 底部留白
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24), // 卡片间距
            Expanded(
              flex: 6, // 调整比例
              child: Card(
                // 右侧卡片：游戏信息和操作
                elevation: 3, // 阴影
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ConstrainedBox(
                  // 限制最大高度
                  constraints: BoxConstraints(maxHeight: desktopCardMaxHeight),
                  child: SingleChildScrollView(
                    // 允许卡片内部滚动
                    padding: const EdgeInsets.all(20.0), // 内边距
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('基础信息'), // 标题
                        const SizedBox(height: 20), // 垂直间距
                        _buildTitleField(), // 标题字段
                        const SizedBox(height: 20), // 垂直间距
                        _buildSummaryField(), // 摘要字段
                        const SizedBox(height: 20), // 垂直间距
                        _buildDescriptionField(), // 描述字段
                        const SizedBox(height: 28), // 垂直间距
                        _buildSectionTitle('分类与标签'), // 标题
                        const SizedBox(height: 20), // 垂直间距
                        _buildCategorySection(), // 分类部分
                        const SizedBox(height: 28), // 垂直间距
                        _buildTagsField(), // 标签字段
                        const SizedBox(height: 40), // 垂直间距
                        Row(
                          // 操作按钮
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildPreviewButton(), // 预览按钮
                            const SizedBox(width: 16), // 水平间距
                            _buildExitAndSaveDraftButton(), // 保存草稿并退出按钮
                            const SizedBox(width: 16), // 水平间距
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

  /// 构建移动布局。
  ///
  /// [context]：Build 上下文。
  /// [userId]：用户ID。
  /// 返回一个包含所有表单字段的移动布局。
  Widget _buildMobileLayout(BuildContext context, String userId) {
    return Container(
      color: Colors.white.withSafeOpacity(0.9),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0), // 内边距
        children: [
          _buildSectionTitle('封面图 *'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildCoverImageSection(), // 封面图片部分
          const SizedBox(height: 24), // 垂直间距

          _buildSectionTitle('基础信息 *'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildTitleField(), // 标题字段
          const SizedBox(height: 16), // 垂直间距
          _buildSummaryField(), // 摘要字段
          const SizedBox(height: 16), // 垂直间距
          _buildDescriptionField(), // 描述字段
          const SizedBox(height: 24), // 垂直间距

          _buildSectionTitle('媒体链接 (可选)'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildMusicUrlField(), // 音乐 URL 字段
          const SizedBox(height: 16), // 垂直间距
          _buildBvidField(), // BV 号字段
          const SizedBox(height: 24), // 垂直间距

          _buildSectionTitle('分类 * 与标签 (可选)'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildCategorySection(), // 分类部分
          const SizedBox(height: 16), // 垂直间距
          _buildTagsField(), // 标签字段
          const SizedBox(height: 24), // 垂直间距

          _buildSectionTitle('下载链接 (可选)'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildDownloadLinksField(), // 下载链接字段
          const SizedBox(height: 24), // 垂直间距
          _buildSectionTitle('其他关联链接 (可选)'), // 标题
          const SizedBox(height: 8), // 垂直间距

          _buildSectionTitle('游戏截图 (可选)'), // 标题
          const SizedBox(height: 8), // 垂直间距
          _buildGameImagesSection(), // 游戏截图部分
          const SizedBox(height: 32), // 垂直间距

          _buildPreviewButton(), // 预览按钮
          const SizedBox(height: 16), // 垂直间距
          _buildExitAndSaveDraftButton(), // 保存草稿并退出按钮
          const SizedBox(height: 16), // 垂直间距
          _buildSubmitButton(userId), // 提交按钮
          const SizedBox(height: 24), // 底部留白
        ],
      ),
    );
  }

  /// 构建分区标题。
  ///
  /// [title]：标题文本。
  /// 返回一个包含标题和分割线的 Column Widget。
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: TextStyle(
            fontSize: _isDesktop ? 18 : 16, // 根据桌面端调整字号
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.color
                    ?.withSafeOpacity(0.85) ??
                Colors.black87,
          ),
        ),
        const Divider(height: 12, thickness: 1, endIndent: 16), // 分割线
      ],
    );
  }

  /// 构建封面图片区域。
  ///
  /// 返回一个包含封面图片表单字段和错误提示的 Column Widget。
  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameCoverImageFormField(
          coverImageSource: _coverImageSource, // 封面图片来源
          onChanged: _handleCoverImageChange, // 变化回调
          isLoading: _isProcessing, // 加载状态
        ),
        if (_coverImageError != null) // 显示验证错误
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0), // 内边距
            child: Text(
              _coverImageError!, // 错误信息
              style: TextStyle(
                color: Theme.of(context).colorScheme.error, // 错误颜色
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建标题字段。
  ///
  /// 返回一个游戏标题输入框。
  Widget _buildTitleField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _titleController, // 文本控制器
      focusNode: _titleFocusNode, // 焦点节点
      decoration: const InputDecoration(
        labelText: '游戏标题 *', // 标签文本
        hintText: '[会社名]游戏名', // 提示文本
        prefixIcon: Icon(Icons.title), // 前置图标
        border: OutlineInputBorder(), // 边框
      ),
      maxLines: 1, // 最大行数
      maxLength: 50, // 最大长度
      isEnabled: !_isProcessing, // 是否可用
      textInputAction: TextInputAction.next, // 文本操作
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入游戏标题' : null, // 验证器
    );
  }

  /// 构建简介字段。
  ///
  /// 返回一个游戏简介输入框。
  Widget _buildSummaryField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _summaryController, // 文本控制器
      focusNode: _summaryFocusNode, // 焦点节点
      decoration: const InputDecoration(
        labelText: '游戏简介 *', // 标签文本
        hintText: '一句话概括游戏简要内容', // 提示文本
        prefixIcon: Icon(Icons.short_text), // 前置图标
        border: OutlineInputBorder(), // 边框
      ),
      maxLength: 100, // 最大长度
      minLines: 2, // 最小行数
      maxLines: 3, // 最大行数
      isEnabled: !_isProcessing, // 是否可用
      textInputAction: TextInputAction.newline, // 文本操作
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入游戏简介' : null, // 验证器
    );
  }

  /// 构建描述字段。
  ///
  /// 返回一个详细描述输入框。
  Widget _buildDescriptionField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _descriptionController, // 文本控制器
      focusNode: _descriptionFocusNode, // 焦点节点
      decoration: InputDecoration(
        labelText: '详细描述 *', // 标签文本
        hintText: '详细介绍游戏背景等', // 提示文本
        border: const OutlineInputBorder(), // 边框
        alignLabelWithHint: true, // 标签与提示对齐
        prefixIcon: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Icon(Icons.description_outlined), // 前置图标
        ),
      ),
      minLines: _isDesktop ? 5 : 4, // 最小行数
      maxLength: 500, // 最大长度
      maxLines: _isDesktop ? 10 : 8, // 最大行数
      isEnabled: !_isProcessing, // 是否可用
      textInputAction: TextInputAction.newline, // 文本操作
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '请输入详细描述' : null, // 验证器
    );
  }

  /// 构建音乐链接字段。
  ///
  /// 返回一个网易云音乐链接输入框。
  Widget _buildMusicUrlField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _musicUrlController, // 文本控制器
      focusNode: _musicUrlFocusNode, // 焦点节点
      decoration: const InputDecoration(
        labelText: '网易云音乐链接', // 标签文本
        hintText: '例如: https://music.163.com/#/song?id=', // 提示文本
        prefixIcon: Icon(Icons.music_note_outlined), // 前置图标
        border: OutlineInputBorder(), // 边框
      ),
      maxLines: 1, // 最大行数
      isEnabled: !_isProcessing, // 是否可用
      keyboardType: TextInputType.url, // 键盘类型
      textInputAction: TextInputAction.next, // 文本操作
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null; // 空值不验证
        if (!_validateMusic(value.trim())) return '请输入有效的网易云音乐链接'; // 验证链接
        return null;
      },
    );
  }

  /// 构建 BV 号字段。
  ///
  /// 返回一个 B 站视频 BV 号输入框。
  Widget _buildBvidField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _bvidController, // 文本控制器
      focusNode: _bvidFocusNode, // 焦点节点
      decoration: const InputDecoration(
        labelText: 'B站视频 BV号', // 标签文本
        hintText: '例如: BV1fx411u7pM', // 提示文本
        prefixIcon: Icon(Icons.smart_display_outlined), // 前置图标
        border: OutlineInputBorder(), // 边框
      ),
      maxLines: 1, // 最大行数
      isEnabled: !_isProcessing, // 是否可用
      textInputAction: TextInputAction.done, // 文本操作
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null; // 空值不验证
        if (!_validateBV(value.trim())) {
          return '请输入有效的 BV 号 (以 BV 开头)'; // 验证 BV 号
        }
        return null;
      },
    );
  }

  /// 验证 BV 号格式。
  bool _validateBV(String text) {
    final bvPattern = RegExp(r'^BV[1-9A-HJ-NP-Za-km-z]+$'); // BV 号正则表达式
    return text.startsWith('BV') &&
        text.length > 10 &&
        bvPattern.hasMatch(text); // 验证格式
  }

  /// 验证音乐链接格式。
  bool _validateMusic(String text) {
    return text.startsWith('http://music.163.com') ||
        text.startsWith('https://music.163.com'); // 验证域名
  }

  /// 构建分类区域。
  ///
  /// 返回一个包含游戏分类选择字段和错误提示的 Column Widget。
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameCategoryFormField(
          selectedCategory: _selectedCategory, // 选中分类
          onChanged: (String? newValue) {
            // 变化回调
            setState(() {
              _selectedCategory = newValue; // 更新选中分类
              _categoryError =
                  (_selectedCategory == null) ? '请选择一个分类' : null; // 更新错误状态
            });
          },
        ),
        if (_categoryError != null) // 显示验证错误
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0), // 内边距
            child: Text(
              _categoryError!, // 错误信息
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// 构建标签字段。
  ///
  /// 返回一个游戏标签输入字段。
  Widget _buildTagsField() {
    return GameTagsFormField(
      selectedTags: _selectedTags, // 选中标签
      onChanged: (tags) => setState(() => _selectedTags = tags), // 变化回调
      availableTags: _availableTags, // 可用标签
      loadTagsErrMsg: _tagsErrMsg, // 加载标签错误信息
    );
  }

  /// 构建下载链接字段。
  ///
  /// 返回一个游戏下载链接列表输入字段。
  Widget _buildDownloadLinksField() {
    return GameDownloadLinksFormField(
      inputStateService: widget.inputStateService,
      currentUser: widget.currentUser!,
      downloadLinks: _downloadLinks, // 下载链接列表
      onChanged: (links) => setState(() => _downloadLinks = links), // 变化回调
    );
  }

  /// 构建其他关联链接字段。
  ///
  /// 返回一个游戏外部链接列表输入字段。
  Widget _buildExternalLinksField() {
    return GameExternalLinksFormField(
      inputStateService: widget.inputStateService,
      externalLinks: _externalLinks, // 外部链接列表
      onChanged: (links) => setState(() => _externalLinks = links), // 变化回调
    );
  }

  /// 构建游戏截图区域。
  ///
  /// 返回一个游戏图片表单字段。
  Widget _buildGameImagesSection() {
    return GameImagesFormField(
      gameImagesSources: _gameImagesSources, // 游戏图片来源
      onChanged: _handleGameImagesChange, // 变化回调
      isLoading: _isProcessing, // 加载状态
    );
  }

  /// 构建保存草稿并退出按钮。
  ///
  /// 返回一个用于保存草稿并退出页面的按钮。
  Widget _buildExitAndSaveDraftButton() {
    return FunctionalButton(
      label: '保存草稿并退出', // 按钮文本
      onPressed: !_isProcessing ? () => _saveDraftAndExit() : () {}, // 点击回调
      isEnabled: !_isProcessing, // 是否可用
      icon: Icons.drafts_outlined, // 图标
      isLoading: false, // 加载状态
    );
  }

  /// 构建提交按钮。
  ///
  /// [userId]：用户ID。
  /// 返回一个用于添加或保存游戏的提交按钮。
  Widget _buildSubmitButton(String userId) {
    bool canPress = !_isProcessing; // 按钮是否可用

    return FunctionalButton(
        onPressed: canPress ? () => _submitForm(userId) : () {}, // 点击回调
        isEnabled: canPress, // 是否可用
        isLoading: _isProcessing, // 加载状态
        label: widget.game == null ? '添加游戏' : '保存修改', // 按钮文本
        icon: widget.game == null
            ? Icons.add_circle_outline // 添加图标
            : Icons.save_alt_outlined // 保存图标
        );
  }

  /// 构建预览按钮。
  ///
  /// 返回一个用于预览游戏详情的按钮。
  Widget _buildPreviewButton() {
    String? previewCoverUrl; // 预览封面图片 URL
    if (_coverImageSource is String &&
        (_coverImageSource as String).isNotEmpty) {
      previewCoverUrl = _coverImageSource as String;
    }

    List<String> previewImageUrls =
        _gameImagesSources.whereType<String>().toList(); // 预览游戏图片 URL 列表

    return GamePreviewButton(
      windowStateProvider: widget.windowStateProvider, // 窗口状态 Provider
      sidebarProvider: widget.sidebarProvider, // 侧边栏 Provider
      gameListFilterProvider: widget.gameListFilterProvider, // 游戏列表筛选 Provider
      gameCollectionService: widget.gameCollectionService, // 游戏收藏服务
      authProvider: widget.authProvider, // 认证 Provider
      gameService: widget.gameService, // 游戏服务
      infoService: widget.infoService, // 用户信息服务
      inputStateService: widget.inputStateService, // 输入状态服务
      followService: widget.followService, // 用户关注服务
      currentUser: widget.currentUser, // 当前用户
      titleController: _titleController, // 标题文本控制器
      summaryController: _summaryController, // 摘要文本控制器
      descriptionController: _descriptionController, // 描述文本控制器
      coverImageUrl: previewCoverUrl, // 封面图片 URL
      gameImages: previewImageUrls, // 游戏图片 URL 列表
      selectedCategory: _selectedCategory, // 选中分类
      selectedTags: _selectedTags, // 选中标签
      rating: widget.game?.rating ?? 0.0, // 评分
      downloadLinks: _downloadLinks, // 下载链接
      externalLinks: _externalLinks, // 外部链接
      musicUrlController: _musicUrlController, // 音乐 URL 文本控制器
      bvidController: _bvidController, // BV 号文本控制器
      existingGame: widget.game, // 现有游戏对象
    );
  }
}
