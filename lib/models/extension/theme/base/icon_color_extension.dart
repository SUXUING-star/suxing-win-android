// lib/models/extension/theme/base/icon_color_extension.dart

import 'package:flutter/widgets.dart';

abstract class IconColorExtension {
  Color getIconColor();
}

extension EasilyGetIconColorExtension<T extends IconColorExtension> on T {
  Color get iconColor => getIconColor();
}
