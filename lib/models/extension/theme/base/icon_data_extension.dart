// lib/models/extension/theme/base/icon_data_extension.dart

import 'package:flutter/widgets.dart';

abstract class IconDataExtension {
  IconData getIconData();
}

extension EasilyGetIconDataExtension<T extends IconDataExtension> on T {
  IconData get iconData => getIconData();
}
