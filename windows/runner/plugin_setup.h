#ifndef PLUGIN_SETUP_H_
#define PLUGIN_SETUP_H_

#include <flutter/plugin_registry.h>

// 定义插件注册函数，使用PluginRegistry*而不是FlutterViewController*
void RegisterPlugins(flutter::PluginRegistry* registry);

#endif  // PLUGIN_SETUP_H_