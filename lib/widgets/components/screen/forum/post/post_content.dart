import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';
import '../../../../../models/post/post.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/datetime/date_time_formatter.dart';
import '../../../../ui/badges/user_info_badge.dart';
import 'post_interaction_buttons.dart';

class PostContent extends StatefulWidget {
  final Post post;
  final UserPostActions userActions;
  final Function(Post, UserPostActions) onPostUpdated;

  const PostContent({
    super.key,
    required this.userActions,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  _PostContentState createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _post = widget.post;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop ||
        DeviceUtils.isWeb ||
        DeviceUtils.isTablet(context);

    return Opacity(
      opacity: 0.9,
      child: Container(
        margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDesktop
              ? [] // No shadow for desktop
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24, // Slightly larger for desktop
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _post.title,
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 作者信息栏
            _buildAuthorRow(context, isDesktop),
            const SizedBox(height: 20),

            // 标签栏
            if (_post.tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: _post.tags.map((tagString) {
                    // 遍历字符串列表
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: PostTagItem(
                        tagString: tagString, // <--- 传递字符串
                        isMini: !isDesktop, // 根据是否桌面调整大小
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (_post.tags.isNotEmpty) const SizedBox(height: 20),
            // 内容栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDesktop ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isDesktop ? Border.all(color: Colors.grey[200]!) : null,
              ),
              child: Text(
                _post.content,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 15,
                  height: 1.8,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // 添加交互按钮
            const SizedBox(height: 16),
            PostInteractionButtons(
              userActions: widget.userActions,
              post: _post,
              onPostUpdated: widget.onPostUpdated,
            ),

            // Post statistics
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.remove_red_eye,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${_post.viewCount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${_post.replyCount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        // 使用UserInfoBadge替换原有的用户信息显示
        Expanded(
          child: UserInfoBadge(
            userId: _post.authorId,
            showFollowButton: false, // 不显示关注按钮
            mini: !isDesktop, // 根据是否是桌面版决定尺寸
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        // 楼主标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '楼主',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 发布时间
        Text(
          DateTimeFormatter.formatRelative(_post.createTime),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
