// lib/widgets/components/screen/checkin/checkin_button.dart
import 'package:flutter/material.dart';
import './effects/particle_effect.dart';

class CheckInButton extends StatelessWidget {
  final bool hasCheckedToday;
  final bool isLoading;
  final AnimationController animationController;
  final int nextReward;
  final VoidCallback onPressed;

  const CheckInButton({
    super.key,
    required this.hasCheckedToday,
    required this.isLoading,
    required this.animationController,
    required this.nextReward,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !hasCheckedToday && !isLoading;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 粒子效果动画
        if (!hasCheckedToday)
          ParticleEffect(
            controller: animationController,
          ),

        // 签到按钮
        ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: hasCheckedToday ? 0 : 4,
          ),
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasCheckedToday
                    ? Icons.check_circle_outline
                    : Icons.add_circle_outline,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasCheckedToday
                    ? '今日已签到'
                    : '立即签到 +$nextReward经验',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}