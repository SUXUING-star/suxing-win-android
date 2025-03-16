// lib/widgets/form/gameform/preview/game_preview.dart
import 'package:flutter/material.dart';
import '../../../../common/image/safe_cached_image.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/font/font_config.dart';

class GamePreview extends StatelessWidget {
  final String? title;
  final String? summary;
  final String? coverImageUrl;
  final List<String> categories;
  final List<String> tags;
  final double rating;

  const GamePreview({
    Key? key,
    this.title,
    this.summary,
    this.coverImageUrl,
    required this.categories,
    required this.tags,
    required this.rating,
  }) : super(key: key);

  // Factory constructor to create a preview from game form data
  factory GamePreview.fromFormData({
    required TextEditingController titleController,
    required TextEditingController summaryController,
    required String? coverImageUrl,
    required List<String> selectedCategories,
    required List<String> selectedTags,
    required double rating,
  }) {
    return GamePreview(
      title: titleController.text.isNotEmpty ? titleController.text : null,
      summary: summaryController.text.isNotEmpty ? summaryController.text : null,
      coverImageUrl: coverImageUrl,
      categories: selectedCategories,
      tags: selectedTags,
      rating: rating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;
    final screenSize = MediaQuery.of(context).size;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '游戏预览',
                    style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text('预览模式'),
                    backgroundColor: Colors.amber.withOpacity(0.2),
                  ),
                ],
              ),
            ),
            Divider(height: 1),

            // Game Card Preview
            useDesktopLayout
                ? _buildDesktopPreview(context)
                : _buildMobilePreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePreview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          _buildCoverImage(),
          SizedBox(height: 16),

          // Title and Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTitle(),
              ),
              _buildRatingIndicator(),
            ],
          ),
          SizedBox(height: 8),

          // Summary
          _buildSummary(),
          SizedBox(height: 12),

          // Categories and Tags
          _buildCategories(),
          SizedBox(height: 8),
          _buildTags(),
        ],
      ),
    );
  }

  Widget _buildDesktopPreview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image (left)
          Container(
            width: 200,
            child: _buildCoverImage(),
          ),
          SizedBox(width: 16),

          // Details (right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTitle(),
                    ),
                    _buildRatingIndicator(),
                  ],
                ),
                SizedBox(height: 8),

                // Summary
                _buildSummary(),
                SizedBox(height: 12),

                // Categories and Tags
                _buildCategories(),
                SizedBox(height: 8),
                _buildTags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverImageUrl != null && coverImageUrl!.isNotEmpty
            ? SafeCachedImage(
          imageUrl: coverImageUrl!,
          fit: BoxFit.cover,
          onError: (url, error) {
            print('预览封面图片加载失败: $url, 错误: $error');
          },
        )
            : Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.image,
              size: 48,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title ?? '游戏标题',
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: title != null ? null : Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRatingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRatingColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 18,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor() {
    if (rating >= 8.0) return Colors.green[700]!;
    if (rating >= 6.0) return Colors.amber[700]!;
    if (rating >= 4.0) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Widget _buildSummary() {
    return Text(
      summary ?? '游戏简介将在此处显示...',
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        color: summary != null ? Colors.black87 : Colors.grey[600],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategories() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.isEmpty
          ? [
        Chip(
          label: Text('未选择分类'),
          backgroundColor: Colors.grey[200],
        )
      ]
          : categories.map((category) {
        return Chip(
          label: Text(category),
          backgroundColor: Colors.blue[100],
        );
      }).toList(),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.isEmpty
          ? [
        Chip(
          label: Text('未添加标签'),
          backgroundColor: Colors.grey[200],
        )
      ]
          : tags.map((tag) {
        return Chip(
          label: Text(tag),
          backgroundColor: Colors.purple[100],
        );
      }).toList(),
    );
  }
}