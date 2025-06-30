// lib/models/extension/theme/base/text_color_extension.dart

import 'package:flutter/painting.dart';

abstract class TextColorExtension {
  Color getTextColor();
}

extension EasilyGetTextColorExtension<T extends TextColorExtension> on T {
  Color get textColor => getTextColor();
}
