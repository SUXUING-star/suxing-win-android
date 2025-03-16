// lib/widgets/form/gameform/layout/desktop_layout.dart

import 'package:flutter/material.dart';
import '../field/cover_image_field.dart';
import '../field/download_links_field.dart';
import '../field/game_images_field.dart';
import '../field/category_field.dart';
import '../field/rating_field.dart';
import '../field/tags_field.dart';
import '../preview/game_preview_button.dart';
import '../../../../../utils/font/font_config.dart';
import '../../../../../models/game/game.dart';

class DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController descriptionController;
  final TextEditingController musicUrlController;
  final String? coverImageUrl;
  final ValueChanged<String?> onCoverImageChanged;
  final List<String> gameImages;
  final Function(List<String>) onGameImagesChanged;
  final List<DownloadLink> downloadLinks;
  final Function(List<DownloadLink>) onDownloadLinksChanged;
  final double rating;
  final Function(double) onRatingChanged;
  final bool isLoading;
  final Function(bool) onLoadingChanged;
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesChanged;
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final String? coverImageError;
  final String? categoryError;
  final VoidCallback onSubmit;
  final Game? existingGame;

  const DesktopLayout({
    Key? key,
    required this.formKey,
    required this.titleController,
    required this.summaryController,
    required this.descriptionController,
    required this.musicUrlController,
    required this.coverImageUrl,
    required this.onCoverImageChanged,
    required this.gameImages,
    required this.onGameImagesChanged,
    required this.downloadLinks,
    required this.onDownloadLinksChanged,
    required this.rating,
    required this.onRatingChanged,
    required this.isLoading,
    required this.onLoadingChanged,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.coverImageError,
    required this.categoryError,
    required this.onSubmit,
    required this.existingGame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height - 100; // Allow for some margin

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Preview section at the top
            SizedBox(height: 16),

            // Form content
            Row(
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
                                coverImageUrl: coverImageUrl,
                                onChanged: onCoverImageChanged,
                                isLoading: isLoading,
                                onLoadingChanged: onLoadingChanged,
                              ),
                              // Show error if cover image is missing
                              if (coverImageError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    coverImageError!,
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              SizedBox(height: 24),

                              // Game Images
                              GameImagesField(
                                gameImages: gameImages,
                                onChanged: onGameImagesChanged,
                                onLoadingChanged: onLoadingChanged,
                              ),
                              SizedBox(height: 24),

                              // Download Links
                              DownloadLinksField(
                                downloadLinks: downloadLinks,
                                onChanged: onDownloadLinksChanged,
                              ),
                              SizedBox(height: 24),

                              // Music URL
                              TextFormField(
                                controller: musicUrlController,
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
                                controller: titleController,
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
                                controller: summaryController,
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
                                controller: descriptionController,
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CategoryField(
                                          selectedCategories: selectedCategories,
                                          onChanged: onCategoriesChanged,
                                        ),
                                        // Show error if category is missing
                                        if (categoryError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              categoryError!,
                                              style: TextStyle(color: Colors.red, fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Rating
                                  Expanded(
                                    child: RatingField(
                                      rating: rating,
                                      onChanged: onRatingChanged,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Tags
                              TagsField(
                                tags: selectedTags,
                                onChanged: onTagsChanged,
                              ),
                              SizedBox(height: 32),

                              // Button Row with Preview and Submit buttons
                              Center(
                                child: _buildSubmitButtonRow(),
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GamePreviewButton(
          titleController: titleController,
          summaryController: summaryController,
          descriptionController: descriptionController,
          coverImageUrl: coverImageUrl,
          gameImages: gameImages,
          selectedCategories: selectedCategories,
          selectedTags: selectedTags,
          rating: rating,
          downloadLinks: downloadLinks,
          musicUrl: musicUrlController.text,
          existingGame: existingGame,
        ),
        SizedBox(width: 16),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: onSubmit,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        existingGame == null ? '添加游戏' : '保存修改',
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontSize: 16,
        ),
      ),
    );
  }
}