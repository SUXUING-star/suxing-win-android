// lib/widgets/form/gameform/preview/game_preview_section.dart
import 'package:flutter/material.dart';
import 'game_preview.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/font/font_config.dart';

class GamePreviewSection extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final String? coverImageUrl;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final double rating;

  const GamePreviewSection({
    Key? key,
    required this.titleController,
    required this.summaryController,
    required this.coverImageUrl,
    required this.selectedCategories,
    required this.selectedTags,
    required this.rating,
  }) : super(key: key);

  @override
  _GamePreviewSectionState createState() => _GamePreviewSectionState();
}

class _GamePreviewSectionState extends State<GamePreviewSection> {
  bool _showPreview = true;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '卡片预览',
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _showPreview,
                  onChanged: (value) {
                    setState(() {
                      _showPreview = value;
                    });
                  },
                ),
              ],
            ),
          ),

          if (_showPreview)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24.0 : 16.0,
                vertical: 8.0,
              ),
              child: GamePreview.fromFormData(
                titleController: widget.titleController,
                summaryController: widget.summaryController,
                coverImageUrl: widget.coverImageUrl,
                selectedCategories: widget.selectedCategories,
                selectedTags: widget.selectedTags,
                rating: widget.rating,
              ),
            ),

          // Preview info text
          if (_showPreview)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '此简易预览仅展示基本卡片样式。要查看完整的游戏详情页面预览效果，请使用页面底部的"预览游戏详情"按钮。',
                    style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          SizedBox(height: 8),
        ],
      ),
    );
  }
}