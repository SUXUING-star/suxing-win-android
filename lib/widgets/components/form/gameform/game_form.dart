// widgets/form/gameform/game_form.dart

import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'field/cover_image_field.dart';
import 'field/download_links_field.dart';
import 'field/game_images_field.dart';
import 'field/category_field.dart';
import 'field/rating_field.dart';
import 'field/tags_field.dart';
import '../../../utils/device/device_utils.dart';
import '../../../utils/font/font_config.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final tags = _selectedTags ?? [];

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
          child: useDesktopLayout ? _buildDesktopLayout(context) : _buildMobileLayout(context),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100; // Allow for some margin

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel - Visual content (40% width)
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: cardHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '视觉内容',
                            style: TextStyle(
                              fontFamily: FontConfig.defaultFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          SizedBox(height: 16),

                          // Cover Image
                          CoverImageField(
                            coverImageUrl: _coverImageUrl,
                            onChanged: (url) => setState(() => _coverImageUrl = url),

                            isLoading: _isLoading,
                            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
                          ),
                          SizedBox(height: 24),

                          // Game Images
                          GameImagesField(
                            gameImages: _gameImages,
                            onChanged: (images) => setState(() => _gameImages = images),
                            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
                          ),
                          SizedBox(height: 24),

                          // Download Links
                          DownloadLinksField(
                            downloadLinks: _downloadLinks,
                            onChanged: (links) => setState(() => _downloadLinks = links),
                          ),
                          SizedBox(height: 24),

                          // Music URL
                          TextFormField(
                            controller: _musicUrlController,
                            decoration: InputDecoration(
                              labelText: '背景音乐链接(可选)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.music_note),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Right panel - Text content (60% width)
            Expanded(
              flex: 6,
              child: Card(
                elevation: 2,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: cardHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '游戏信息',
                            style: TextStyle(
                              fontFamily: FontConfig.defaultFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          SizedBox(height: 16),

                          // Title
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
                            decoration: InputDecoration(
                              labelText: '游戏标题',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.games),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? '请输入游戏标题'
                                : null,
                          ),
                          SizedBox(height: 16),

                          // Summary
                          TextFormField(
                            controller: _summaryController,
                            style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
                            decoration: InputDecoration(
                              labelText: '游戏简介',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.short_text),
                            ),
                            maxLines: 2,
                            validator: (value) => value?.isEmpty ?? true
                                ? '请输入游戏简介'
                                : null,
                          ),
                          SizedBox(height: 16),

                          // Description - reduced max lines to prevent overflow
                          TextFormField(
                            controller: _descriptionController,
                            style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
                            decoration: InputDecoration(
                              labelText: '详细描述',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 6, // Reduced from 8 to help prevent overflow
                            validator: (value) => value?.isEmpty ?? true
                                ? '请输入详细描述'
                                : null,
                          ),
                          SizedBox(height: 24),

                          // Category and Tags in a row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Categories
                              Expanded(
                                child: CategoryField(
                                  selectedCategories: _selectedCategories,
                                  onChanged: (categories) => setState(() => _selectedCategories = categories),
                                ),
                              ),
                              SizedBox(width: 16),
                              // Rating
                              Expanded(
                                child: RatingField(
                                  rating: _rating,
                                  onChanged: (value) => setState(() => _rating = value),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Tags
                          TagsField(
                            tags: _selectedTags,
                            onChanged: (tags) => setState(() => _selectedTags = tags),
                          ),
                          SizedBox(height: 32),

                          // Submit Button - Centered
                          Center(child: _buildSubmitButton()),
                          SizedBox(height: 16), // Add bottom padding to avoid cutoff
                        ],
                      ),
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

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        CoverImageField(
          coverImageUrl: _coverImageUrl,
          onChanged: (url) => setState(() => _coverImageUrl = url),
          isLoading: _isLoading,
          onLoadingChanged: (loading) => setState(() => _isLoading = loading),
        ),
        SizedBox(height: 16),

        _buildBasicFields(),
        SizedBox(height: 16),

        CategoryField(
          selectedCategories: _selectedCategories,
          onChanged: (categories) => setState(() => _selectedCategories = categories),
        ),
        SizedBox(height: 16),

        TagsField(
          tags: _selectedTags,
          onChanged: (tags) => setState(() => _selectedTags = tags),
        ),
        SizedBox(height: 16),

        DownloadLinksField(
          downloadLinks: _downloadLinks,
          onChanged: (links) => setState(() => _downloadLinks = links),
        ),
        SizedBox(height: 16),

        RatingField(
          rating: _rating,
          onChanged: (value) => setState(() => _rating = value),
        ),
        SizedBox(height: 16),

        GameImagesField(
          gameImages: _gameImages,
          onChanged: (images) => setState(() => _gameImages = images),
          onLoadingChanged: (loading) => setState(() => _isLoading = loading),
        ),
        SizedBox(height: 24),

        _buildSubmitButton(),
        SizedBox(height: 16), // Add bottom padding to avoid cutoff
      ],
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
          decoration: InputDecoration(
            labelText: '游戏标题',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true
              ? '请输入游戏标题'
              : null,
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _summaryController,
          style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
          decoration: InputDecoration(
            labelText: '游戏简介',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) => value?.isEmpty ?? true
              ? '请输入游戏简介'
              : null,
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _descriptionController,
          style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
          decoration: InputDecoration(
            labelText: '详细描述',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          validator: (value) => value?.isEmpty ?? true
              ? '请输入详细描述 '
              : null,
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _musicUrlController,
          style: TextStyle(fontFamily: FontConfig.defaultFontFamily),
          decoration: InputDecoration(
            labelText: '背景音乐链接(可选)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        widget.game == null ? '添加游戏' : '保存修改',
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '正在上传图片...',
                  style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      fontSize: 16
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}