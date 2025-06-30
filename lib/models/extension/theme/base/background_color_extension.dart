// lib/models/extension/theme/base/background_color_extension.dart

import 'package:flutter/painting.dart';

abstract class BackgroundColorExtension {
  Color getBackgroundColor();
}

extension EasilyGetBackgroundColorExtension<T extends BackgroundColorExtension> on T {
  Color get backgroundColor => getBackgroundColor();
}
