// lib/widgets/components/badge/layout/checkin_badge.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../services/main/user/user_checkin_service.dart';

class CheckInBadge extends StatelessWidget {
  final UserCheckInService checkInService;

  const CheckInBadge({
    super.key,
    required this.checkInService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: checkInService.checkedTodayStream,
      initialData: checkInService.checkedTodayNotifier.value,
      builder: (context, snapshot) {
        final bool hasCheckedToday = snapshot.data ?? false;

        return GestureDetector(
          onTap: () {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.checkin,
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: hasCheckedToday ? Colors.blue[400] : Colors.green,
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
  }
}
