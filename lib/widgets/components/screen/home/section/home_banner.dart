import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    double bannerHeight = 200.0;
    if (DeviceUtils.isAndroid && DeviceUtils.isPortrait(context)) {
      bannerHeight = 140.0;
    }

    return Container(
      height: bannerHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 图片容器
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withSafeOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/kaev.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                // 渐变遮罩
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withSafeOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
