// lib/widgets/components/screen/home/section/home_banner.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200.0,
            maxHeight: 250.0,
          ),
          child: AspectRatio(
            aspectRatio: 1536 / 1024,
            child: PageView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  // 外层边框，作为第一层
                  padding: const EdgeInsets.all(2.0), // 细边框的厚度
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400, // 比如一个亮灰色细线
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withSafeOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    // 内层边框，作为主画框
                    padding: const EdgeInsets.all(5.0), // 主画框厚度
                    decoration: BoxDecoration(
                      color: Colors.grey[850], // 主体用深色
                      borderRadius: BorderRadius.circular(14.0), // 圆角要比外层小
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9.0), // 最内层圆角
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            GlobalConstants.defaultBannerImage,
                            fit: BoxFit.cover,
                          ),
                          // 渐变遮罩
                          Container(
                            decoration: BoxDecoration(
                              // 这个 borderRadius 必须和 ClipRRect 的一致
                              borderRadius: BorderRadius.circular(10.0),
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
