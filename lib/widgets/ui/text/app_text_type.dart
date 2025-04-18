// lib/widgets/ui/text/app_text_type.dart (或者放在 app_text.dart 文件顶部)
enum AppTextType {
  // --- 基础样式 (通常只影响字体大小/粗细，颜色用默认) ---
  body,      // 对应 Theme.of(context).textTheme.bodyMedium
  caption,   // 对应 Theme.of(context).textTheme.caption (或 bodySmall)
  button,    // 对应 Theme.of(context).textTheme.labelLarge
  title,     // 对应 Theme.of(context).textTheme.titleMedium
  headline,  // 对应 Theme.of(context).textTheme.headlineSmall

  // --- 带特定颜色语义的类型 ---
  primary,   // 使用 Theme.of(context).colorScheme.primary
  secondary, // 使用 Theme.of(context).colorScheme.secondary
  error,     // 使用 Theme.of(context).colorScheme.error
  disabled,  // 使用 Theme.of(context).disabledColor

  // --- 你可以根据需要添加更多 ---
  success,   // 比如用绿色
  warning,   // 比如用橙色
  // ...
}