// lib/widgets/components/screen/forum/post/section/tags/post_tags.dart

/// PostDetail页面提供的PostTags
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/enrich_post_tag.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/post_extension.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';

class PostTags extends StatelessWidget {
  final Post post;
  final bool isMini;
  final double tagSpacing;
  final EdgeInsets? scrollPadding;
  final Function(BuildContext context, String tag)? onTagTap;
  final String? selectedTagString;

  const PostTags({
    super.key,
    required this.post,
    required this.isMini,
    this.tagSpacing = 8.0,
    this.scrollPadding = const EdgeInsets.symmetric(vertical: 4.0),
    this.onTagTap,
    this.selectedTagString,
  });

  @override
  Widget build(BuildContext context) {
    final List<EnrichPostTag> tags = post.enrichTags;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> tagItemWidgets = [];
    for (int i = 0; i < tags.length; i++) {
      final EnrichPostTag currentEnrichTag = tags[i];
      final String currentTag = currentEnrichTag.tag;
      tagItemWidgets.add(
        PostTagItem(
          key: ValueKey('post_tag_item_${post.id}_${currentEnrichTag.tag}'),
          enrichTag: currentEnrichTag,
          isMini: isMini,
          isSelected: selectedTagString == currentTag,
          onTap: (onTagTap != null)
              ? (_) {
                  onTagTap!(context, currentTag);
                }
              : null,
        ),
      );
      if (i < tags.length - 1) {
        tagItemWidgets.add(SizedBox(width: tagSpacing));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: scrollPadding,
      child: Row(
        children: tagItemWidgets,
      ),
    );
  }
}
