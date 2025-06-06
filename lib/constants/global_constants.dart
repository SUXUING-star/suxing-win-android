// lib/constants/global_constants.dart
class GlobalConstants {
  static const String donationUrl = 'https://xingsu.fun'; // 替换为你的爱发电 ID
  static const String feedbackUrl = 'https://xingsu.fun'; // 替换为你的反馈链接
  static const String githubUrl =
      'https://github.com/SUXUING-star/suxing-win-android';
  static const String bUrl =
      'https://space.bilibili.com/32892805?spm_id_from=333.1007.0.0';

  static const String groupNumber = '829701655'; // QQ群号
  static const String qrCodeAssetPath = 'assets/images/qq.png'; // 图片资源路径
  static const String appName = '宿星茶会';
  static const String appNameAndroid = '$appName（安卓版）';
  static const String appNameWindows = '$appName（Windows）';
  static const String appIcon = 'assets/images/icons/app_icon.jpg';

  static const List<Map<String, dynamic>> techStacks = [
    {
      "title": "本项目全栈开发技术",
      "items": [
        {"name": "Dart", "desc": "客户端开发"},
        {"name": "Golang", "desc": "服务端开发"},
      ]
    }
  ];

  static const List<String> defaultBackgroundImages = [
    'assets/images/bg-1.jpg',
    'assets/images/bg-2.jpg',
  ];
  static const List<String> defaultBackgroundImagesRotated = [
    'assets/images/bg-1rotate.jpg',
    'assets/images/bg-2rotate.jpg',
  ];

  static const int defaultParticleCount = 30;

  static const String initScreenGifFirst = 'assets/images/cappo.gif';
  static const String initScreenGifSecond = 'assets/images/cappo1.gif';

  static const String defaultBannerImage = 'assets/images/kaev.jpg';
}
