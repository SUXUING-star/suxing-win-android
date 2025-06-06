// lib/widgets/ui/components/game/review/game_review_item.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

import '../../../../../models/game/game_collection.dart';


class GameReviewItemWidget extends StatelessWidget {
  final User? currentUser;
  final GameCollectionReview review;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  const GameReviewItemWidget({
    super.key,
    required this.currentUser,
    required this.review,
    required this.followService,
    required this.infoProvider,
  });

  @override
  Widget build(BuildContext context) {
    final String userId = review.userId;
    final DateTime updateTime = review.updateTime;
    final double? rating = review.rating;
    final String? reviewText = review.reviewContent;
    final String status = review.status;
    final String? notesText = review.notes;

    String statusLabel;
    IconData statusIcon;
    Color statusColor;
    switch (status) {
      case GameCollectionStatus.wantToPlay:
        statusLabel = '想玩';
        statusIcon = Icons.bookmark_add_outlined;
        statusColor = Colors.blue;
        break;
      case GameCollectionStatus.playing:
        statusLabel = '在玩';
        statusIcon = Icons.gamepad_outlined;
        statusColor = Colors.orange;
        break;
      case GameCollectionStatus.played:
        statusLabel = '玩过';
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.green;
        break;
      default:
        statusLabel = '未知';
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: UserInfoBadge(
                      followService: followService,
                      infoProvider: infoProvider,
                      currentUser: currentUser,
                      targetUserId: userId,
                      showFollowButton: false,
                      mini: true)),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(statusIcon, size: 16, color: statusColor),
                label: Text(statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                backgroundColor: statusColor.withSafeOpacity(0.1),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(color: statusColor.withSafeOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 8),
              Text(DateTimeFormatter.formatRelative(updateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          if (status == GameCollectionStatus.played && rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                children: List.generate(5, (index) {
                  double starValue = rating / 2.0;
                  IconData starIcon;
                  Color starColor = Colors.amber;
                  if (index < starValue.floor()) {
                    starIcon = Icons.star_rounded;
                  } else if (index < starValue && (starValue - index) >= 0.25) {
                    starIcon = Icons.star_half_rounded;
                  } else {
                    starIcon = Icons.star_border_rounded;
                    starColor = Colors.grey[400]!;
                  }
                  return Icon(starIcon, size: 16, color: starColor);
                }),
              ),
            ),
          if (reviewText != null && reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(reviewText,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[800], height: 1.5)),
            ),
          if (notesText != null && notesText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                userId == currentUser?.id
                    ? "我做的笔记: $notesText"
                    : "笔记: $notesText",
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
