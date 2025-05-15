import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../effects/particle_effect.dart'; // 导入粒子效果组件

// Define image assets as constants
const List<String> backgroundImages = [
  'assets/images/bg-1.jpg',
  'assets/images/bg-2.jpg'
];
const List<String> backgroundImagesRotated = [
  'assets/images/bg-1rotate.jpg',
  'assets/images/bg-2rotate.jpg'
];

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late Timer _imageTimer;
  int _currentImageIndex = 0;

  bool _isAndroidPortrait = false;

  @override
  void initState() {
    super.initState();
    _setupImageRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceOrientation();
    });
  }

  Future<void> _checkDeviceOrientation() async {
    if (kIsWeb) return; // Skip if it's a web app

    if (Platform.isAndroid) {
      // Check for Android
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (!mounted) return;

      // Check if the device is an Android device
      if (androidInfo.version.sdkInt >= 16) {
        //Use try catch to avoid error
        try {
          Orientation orientation = MediaQuery.of(context).orientation;
          setState(() {
            _isAndroidPortrait = orientation == Orientation.portrait;
          });
        } catch (e) {
          debugPrint('Error getting orientation: $e');
        }
      }
    } else {
      _isAndroidPortrait = false;
    }
  }

  void _setupImageRotation() {
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> gradientColors = isDark
        ? [
            Color.fromRGBO(0, 0, 0, 0.6),
            Color.fromRGBO(0, 0, 0, 0.4),
          ]
        : [
            Color.fromRGBO(255, 255, 255, 0.7),
            Color.fromRGBO(255, 255, 255, 0.5),
          ];

    List<String> imagesToUse =
        _isAndroidPortrait ? backgroundImagesRotated : backgroundImages;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image layer with fade in/out effect
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Image.asset(
                imagesToUse[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
            // Glass morphism effect layer
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6.0,
                sigmaY: 6.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            // Particle animation layer
            ParticleEffect(particleCount: 50), // 使用粒子效果组件
            // Content layer
            widget.child,
          ],
        );
      },
    );
  }
}
