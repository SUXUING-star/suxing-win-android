// lib/widgets/components/badge/layout/checkin_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/main/user/user_checkin_service.dart';
import '../../../../screens/checkin/checkin_screen.dart';

class CheckInBadge extends StatelessWidget {
  const CheckInBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserCheckInService>(
      builder: (context, checkInService, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: checkInService.checkedTodayNotifier,
          builder: (context, hasCheckedToday, child) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckInScreen(),
                  ),
                );
              },
              child: !hasCheckedToday
                  ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              )
                  : Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}