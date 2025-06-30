// lib/models/post/post_extension.dart

import 'package:suxingchahui/models/post/enrich_post_tag.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/utils/share/share_utils.dart';

extension PostExtension on Post {
  List<EnrichPostTag> get enrichTags => EnrichPostTag.fromTags(tags);

  bool get isActive => status == Post.statusActive;
  bool get isNotActive => status != Post.statusActive;
  bool get isLocked => status == Post.statusLocked;
  bool get isDeleted => status == Post.statusDeleted;

  String toShareMessage() {
    return ShareUtils.generateShareMessage(
      id: id,
      title: title,
      shareType: ShareUtils.sharePost, // 明确告诉工具类，我分享的是个游戏
    );
  }
}
