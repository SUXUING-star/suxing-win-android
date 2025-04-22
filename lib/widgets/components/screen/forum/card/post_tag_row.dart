// post_tag_row.dart
import 'package:flutter/material.dart';

class PostTagRow extends StatelessWidget {
  final List<String> tags;
  final bool isAndroidPortrait;
  final EdgeInsetsGeometry? tagMargin;
  final EdgeInsetsGeometry? tagPadding;
  final double? tagBorderRadius;
  final Color? tagBackgroundColor;
  final Color? tagTextColor;

  const PostTagRow({
    super.key,
    required this.tags,
    this.isAndroidPortrait = false,
    this.tagMargin,
    this.tagPadding,
    this.tagBorderRadius,
    this.tagBackgroundColor,
    this.tagTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) => _buildTag(context, tag)).toList(),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      margin: tagMargin ?? const EdgeInsets.only(right: 6),
      padding: tagPadding ?? const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tagBackgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(tagBorderRadius ?? 8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: tagTextColor ?? Theme.of(context).primaryColor,
          fontSize: isAndroidPortrait ? 10 : 12,
        ),
      ),
    );
  }
}