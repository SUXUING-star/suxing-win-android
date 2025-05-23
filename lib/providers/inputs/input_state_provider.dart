// lib/providers/inputs/input_state_provider.dart
import 'package:flutter/material.dart';

/// 全局管理不同输入框（坑位）的文本状态
class InputStateService with ChangeNotifier {
  final Map<String, String> _textStates = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, VoidCallback> _listeners = {};

  String getText(String slotName) {
    return _textStates[slotName] ?? '';
  }

  void _updateInternalStateOnly(String slotName, String text) {
    if (_textStates[slotName] != text) {
      _textStates[slotName] = text;
    }
  }

  void clearText(String slotName) {
    if (_textStates.containsKey(slotName)) {
      _textStates.remove(slotName); // 清除文本状态

      final controller = _controllers.remove(slotName); // 从缓存中移除 Controller
      final listener = _listeners.remove(slotName); // 从缓存中移除监听器

      if (controller != null) {
        // 清空 Controller 的文本
        try {
          controller.clear();
        } catch (e) {
          // print("Error clearing controller in clearText for slot '$slotName': $e\n$s");
        }
        // 移除监听器
        if (listener != null) {
          try {
            controller.removeListener(listener);
          } catch (e) {
            // print("Error removing listener in clearText for slot '$slotName': $e\n$s");
          }
        }
      }
    }
  }

  TextEditingController getController(String slotName) {
    if (!_controllers.containsKey(slotName)) {
      final controller = TextEditingController(text: getText(slotName));
      void listener() {
        if (_controllers[slotName] == controller) {
          if (!controller.value.composing.isValid) {
            _updateInternalStateOnly(slotName, controller.text);
          }
        } else {
          final storedListener = _listeners[slotName];
          if (storedListener != null) {
            try {
              controller.removeListener(storedListener);
              _listeners.remove(slotName);
            } catch (e) {
              // print("Error removing listener inside listener callback for slot '$slotName': $e\n$s");
            }
          }
        }
      }

      controller.addListener(listener);
      _controllers[slotName] = controller;
      _listeners[slotName] = listener;
    }
    return _controllers[slotName]!;
  }

  @override
  void dispose() {
    _controllers.forEach((slotName, controller) {
      final listener = _listeners[slotName];
      if (listener != null) {
        try {
          controller.removeListener(listener);
        } catch (e) {
          // print(
          //     "Error removing listener during service dispose for slot '$slotName': $e\n$s");
        }
      }
      try {
        // 在 Service 销毁时 dispose Controller
        controller.dispose();
      } catch (e) {
        // print(
        //     "Error disposing controller during service dispose for slot '$slotName': $e\n$s");
      }
    });
    _controllers.clear();
    _listeners.clear();
    _textStates.clear();
    super.dispose();
  }
}
