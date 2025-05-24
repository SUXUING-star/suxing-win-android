// lib/widgets/components/badge/layout/message_badge.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';

class MessageBadge extends StatelessWidget {
  final MessageService messageService;
  const MessageBadge({
    super.key,
    required this.messageService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: messageService.getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            NavigationUtils.pushNamed(context, AppRoutes.message);
          },
          child: unreadCount > 0
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
