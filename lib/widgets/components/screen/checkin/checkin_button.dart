// lib/widgets/components/screen/checkin/checkin_button.dart

/// 该文件定义了 CheckInButton 组件，用于用户签到操作。
/// CheckInButton 根据签到状态、加载状态和奖励信息显示不同样式。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/widgets/components/screen/checkin/effects/checkin_particle_effect.dart'; // 签到粒子效果组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需

/// `CheckInButton` 类：签到按钮的 StatelessWidget。
///
/// 该组件根据签到状态、加载状态和奖励信息显示不同样式，并包含粒子效果。
class CheckInButton extends StatelessWidget {
  final bool hasCheckedToday; // 今日是否已签到
  final bool isLoading; // 按钮是否处于加载状态
  final AnimationController animationController; // 动画控制器
  final int nextReward; // 下次签到的奖励经验
  final VoidCallback onPressed; // 按钮点击回调

  /// 构造函数。
  ///
  /// [hasCheckedToday]：今日是否已签到。
  /// [isLoading]：按钮是否处于加载状态。
  /// [animationController]：动画控制器。
  /// [nextReward]：下次签到的奖励经验。
  /// [onPressed]：按钮点击回调。
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
    final isEnabled = !hasCheckedToday && !isLoading; // 判断按钮是否可用

    return Stack(
      alignment: Alignment.center, // 居中对齐子组件
      children: [
        if (!hasCheckedToday) // 未签到时显示粒子效果
          CheckInParticleEffect(
            controller: animationController,
          ),
        ElevatedButton(
          onPressed: isEnabled ? onPressed : null, // 根据可用状态设置点击回调
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // 圆角边框
            ),
            elevation: hasCheckedToday ? 0 : 4, // 根据签到状态设置阴影
          ),
          child: isLoading // 加载中时显示加载指示器
              ? const SizedBox(width: 20, height: 20, child: LoadingWidget())
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasCheckedToday // 根据签到状态显示不同图标
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8), // 间距
                    Text(
                      hasCheckedToday
                          ? '今日已签到'
                          : '立即签到 +$nextReward经验', // 根据签到状态显示不同文本
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
