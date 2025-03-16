// lib/widgets/form/gameform/layout/mobile_layout.dart

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

class MobileLayout extends StatelessWidget {
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

  const MobileLayout({
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
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Preview Section at the top
        SizedBox(height: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
        SizedBox(height: 16),

        _buildBasicFields(),
        SizedBox(height: 16),

        Column(
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
        SizedBox(height: 16),

        TagsField(
          tags: selectedTags,
          onChanged: onTagsChanged,
        ),
        SizedBox(height: 16),

        DownloadLinksField(
          downloadLinks: downloadLinks,
          onChanged: onDownloadLinksChanged,
        ),
        SizedBox(height: 16),

        RatingField(
          rating: rating,
          onChanged: onRatingChanged,
        ),
        SizedBox(height: 16),

        GameImagesField(
          gameImages: gameImages,
          onChanged: onGameImagesChanged,
          onLoadingChanged: onLoadingChanged,
        ),
        SizedBox(height: 24),

        // Preview Button
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
        SizedBox(height: 16),

        // Submit Button
        _buildSubmitButton(),
        SizedBox(height: 16), // Add bottom padding to avoid cutoff
      ],
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        TextFormField(
          controller: titleController,
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
          controller: summaryController,
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
          controller: descriptionController,
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
          controller: musicUrlController,
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