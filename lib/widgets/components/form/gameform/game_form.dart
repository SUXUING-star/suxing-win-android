// lib/widgets/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import '../../../../models/game/game.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'layout/desktop_layout.dart';
import 'layout/mobile_layout.dart';
import 'common/loading_overlay.dart';
import '../../../../utils/device/device_utils.dart';

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
  String? _coverImageUrl;
  List<String> _gameImages = [];
  List<DownloadLink> _downloadLinks = [];
  double _rating = 0.0;
  bool _isLoading = false;
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];

  // Add validation error messages
  String? _coverImageError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.game != null) {
      _titleController.text = widget.game!.title;
      _summaryController.text = widget.game!.summary;
      _descriptionController.text = widget.game!.description;
      _musicUrlController.text = widget.game!.musicUrl ?? '';
      _coverImageUrl = widget.game!.coverImage;
      _gameImages = List.from(widget.game!.images);
      _downloadLinks = List.from(widget.game!.downloadLinks);
      _rating = widget.game!.rating;
      _selectedCategories = widget.game!.category.split(',').map((e) => e.trim()).toList();

      try {
        _selectedTags = widget.game!.tags != null ? List.from(widget.game!.tags) : [];
      } catch (e) {
        _selectedTags = [];
        print('初始化标签时出错: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _musicUrlController.dispose();
    super.dispose();
  }

  // Validate all form fields, including non-FormField widgets
  bool _validateForm() {
    bool isValid = _formKey.currentState?.validate() ?? false;

    // Validate cover image
    if (_coverImageUrl == null || _coverImageUrl!.isEmpty) {
      setState(() {
        _coverImageError = '请上传封面图片';
      });
      isValid = false;
    } else {
      setState(() {
        _coverImageError = null;
      });
    }

    // Validate category
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

  void _submitForm() {
    if (_validateForm()) {
      final tags = _selectedTags;

      final game = Game(
        id: widget.game?.id ?? mongo.ObjectId().toHexString(),
        authorId: widget.game?.authorId ?? '',
        title: _titleController.text,
        summary: _summaryController.text,
        description: _descriptionController.text,
        category: _selectedCategories.join(', '),
        coverImage: _coverImageUrl ?? '',
        images: _gameImages,
        tags: tags,
        rating: _rating,
        viewCount: widget.game?.viewCount ?? 0,
        createTime: widget.game?.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
        likeCount: widget.game?.likeCount ?? 0,
        likedBy: widget.game?.likedBy ?? [],
        downloadLinks: _downloadLinks,
        musicUrl: _musicUrlController.text.isEmpty ? null : _musicUrlController.text,
        lastViewedAt: widget.game?.lastViewedAt,
      );

      widget.onSubmit(game);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请检查表单中的错误并修正'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and orientation
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: useDesktopLayout
              ? DesktopLayout(
            formKey: _formKey,
            titleController: _titleController,
            summaryController: _summaryController,
            descriptionController: _descriptionController,
            musicUrlController: _musicUrlController,
            coverImageUrl: _coverImageUrl,
            onCoverImageChanged: (url) => setState(() => _coverImageUrl = url as String?),
            gameImages: _gameImages,
            onGameImagesChanged: (images) => setState(() => _gameImages = images as List<String>),
            downloadLinks: _downloadLinks,
            onDownloadLinksChanged: (links) => setState(() => _downloadLinks = links as List<DownloadLink>),
            rating: _rating,
            onRatingChanged: (value) => setState(() => _rating = value),
            isLoading: _isLoading,
            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
            selectedCategories: _selectedCategories,
            onCategoriesChanged: (categories) => setState(() {
              _selectedCategories = categories as List<String>;
              if (categories.isNotEmpty) {
                _categoryError = null;
              }
            }),
            selectedTags: _selectedTags,
            onTagsChanged: (tags) => setState(() => _selectedTags = tags as List<String>),
            coverImageError: _coverImageError,
            categoryError: _categoryError,
            onSubmit: _submitForm,
            existingGame: widget.game,
          )
              : MobileLayout(
            formKey: _formKey,
            titleController: _titleController,
            summaryController: _summaryController,
            descriptionController: _descriptionController,
            musicUrlController: _musicUrlController,
            coverImageUrl: _coverImageUrl,
            onCoverImageChanged: (url) => setState(() => _coverImageUrl = url),
            gameImages: _gameImages,
            onGameImagesChanged: (images) => setState(() => _gameImages = images),
            downloadLinks: _downloadLinks,
            onDownloadLinksChanged: (links) => setState(() => _downloadLinks = links),
            rating: _rating,
            onRatingChanged: (value) => setState(() => _rating = value),
            isLoading: _isLoading,
            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
            selectedCategories: _selectedCategories,
            onCategoriesChanged: (categories) => setState(() {
              _selectedCategories = categories;
              if (categories.isNotEmpty) {
                _categoryError = null;
              }
            }),
            selectedTags: _selectedTags,
            onTagsChanged: (tags) => setState(() => _selectedTags = tags),
            coverImageError: _coverImageError,
            categoryError: _categoryError,
            onSubmit: _submitForm,
            existingGame: widget.game,
          ),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }
}