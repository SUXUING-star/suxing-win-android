// lib/widgets/message/message_badge.dart
import 'package:flutter/material.dart';
import '../../../../services/main/message/message_service.dart';
import '../../../../screens/message_screen.dart';

class MessageBadge extends StatelessWidget {
  final MessageService _messageService = MessageService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _messageService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded),
              color: Colors.grey[700], // 直接设置图标颜色
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MessageScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}