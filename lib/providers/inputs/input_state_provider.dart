// lib/providers/inputs/input_state_provider.dart
import 'package:flutter/material.dart';

/// `InputStateService` 类：全局管理不同输入框的文本状态。
///
/// 该类提供输入框文本内容的存取、控制器管理和资源清理。
class InputStateService with ChangeNotifier {
  final Map<String, String> _textStates = {}; // 存储各个输入框的文本内容
  final Map<String, TextEditingController> _controllers = {}; // 缓存各个输入框的控制器实例
  final Map<String, VoidCallback> _listeners = {}; // 缓存各个控制器对应的监听器回调

  /// 获取指定输入框的文本内容。
  ///
  /// [slotName]：输入框的唯一标识符。
  /// 返回对应名称的文本，未找到则返回空字符串。
  String getText(String slotName) {
    return _textStates[slotName] ?? '';
  }

  /// 内部方法：仅更新指定输入框的文本状态。
  ///
  /// [slotName]：输入框的唯一标识符。
  /// [text]：新的文本内容。
  void _updateInternalStateOnly(String slotName, String text) {
    if (_textStates[slotName] != text) {
      // 检查文本是否发生变化
      _textStates[slotName] = text; // 更新文本状态
    }
  }

  /// 清除指定输入框的文本内容、控制器和监听器。
  ///
  /// [slotName]：输入框的唯一标识符。
  void clearText(String slotName) {
    if (_textStates.containsKey(slotName)) {
      // 检查是否存在该输入框的状态
      _textStates.remove(slotName); // 从文本状态缓存中移除

      final controller = _controllers.remove(slotName); // 从控制器缓存中移除
      final listener = _listeners.remove(slotName); // 从监听器缓存中移除

      if (controller != null) {
        // 存在控制器时执行清理
        try {
          controller.clear(); // 清空控制器文本
        } catch (e) {
          // 捕获异常
        }
        if (listener != null) {
          // 存在监听器时移除
          try {
            controller.removeListener(listener); // 移除控制器监听器
          } catch (e) {
            // 捕获异常
          }
        }
      }
    }
  }

  /// 获取指定输入框的 [TextEditingController] 实例。
  ///
  /// [slotName]：输入框的唯一标识符。
  /// 如果控制器不存在，则创建一个新的并缓存。
  TextEditingController getController(String slotName) {
    if (!_controllers.containsKey(slotName)) {
      // 如果控制器缓存中不存在该实例
      final controller = TextEditingController(
          text: getText(slotName)); // 创建新的 TextEditingController
      void listener() {
        // 定义一个监听器回调函数
        if (_controllers[slotName] == controller) {
          // 检查当前控制器是否仍是该名称对应的控制器
          if (!controller.value.composing.isValid) {
            // 忽略中文输入法合成阶段的文本
            _updateInternalStateOnly(slotName, controller.text); // 更新内部文本状态
          }
        } else {
          // 当前控制器不再是该名称对应的控制器
          final storedListener = _listeners[slotName]; // 获取缓存的监听器
          if (storedListener != null) {
            // 存在缓存监听器时移除
            try {
              controller.removeListener(storedListener); // 移除监听器
              _listeners.remove(slotName); // 从缓存中清除监听器
            } catch (e) {
              // 捕获异常
            }
          }
        }
      }

      controller.addListener(listener); // 为控制器添加监听器
      _controllers[slotName] = controller; // 缓存控制器实例
      _listeners[slotName] = listener; // 缓存监听器实例
    }
    return _controllers[slotName]!; // 返回对应名称的控制器实例
  }

  /// 销毁该 Provider 时释放所有资源。
  ///
  /// 遍历所有缓存的控制器，移除监听器并销毁控制器实例，
  /// 清空所有内部缓存。
  @override
  void dispose() {
    _controllers.forEach((slotName, controller) {
      // 遍历所有缓存的控制器
      final listener = _listeners[slotName]; // 获取对应的监听器
      if (listener != null) {
        // 存在监听器时移除
        try {
          controller.removeListener(listener); // 移除监听器
        } catch (e) {
          // 捕获异常
        }
      }
      try {
        controller.dispose(); // 销毁控制器
      } catch (e) {
        // 捕获异常
      }
    });
    _controllers.clear(); // 清空控制器缓存
    _listeners.clear(); // 清空监听器缓存
    _textStates.clear(); // 清空文本状态缓存
    super.dispose(); // 调用父类的销毁方法
  }
}
