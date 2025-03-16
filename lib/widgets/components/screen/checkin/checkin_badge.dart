// lib/widgets/components/screen/checkin/checkin_badge.dart
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
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  color: hasCheckedToday ? Colors.green : Colors.grey[700],
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckInScreen(),
                      ),
                    );
                  },
                ),
                if (!hasCheckedToday)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}