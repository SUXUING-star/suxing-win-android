import 'package:flutter/material.dart';
import '../../../../../models/post/post.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/datetime/date_time_formatter.dart';
import '../../../badge/info/user_info_badge.dart'; // 导入UserInfoBadge

class PostContent extends StatelessWidget {
  final Post post;

  PostContent({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop || DeviceUtils.isWeb || DeviceUtils.isTablet(context);

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
                    post.title,
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

            // 作者信息栏 - 使用UserInfoBadge
            _buildAuthorRow(context, isDesktop),
            const SizedBox(height: 20),

            // 标签栏
            if (post.tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: post.tags.map((tag) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            if (post.tags.isNotEmpty) const SizedBox(height: 20),

            // 内容栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDesktop ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isDesktop
                    ? Border.all(color: Colors.grey[200]!)
                    : null,
              ),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 15,
                  height: 1.8,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Post statistics
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.viewCount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.replyCount}',
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
            userId: post.authorId,
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
          DateTimeFormatter.formatRelative(post.createTime),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}