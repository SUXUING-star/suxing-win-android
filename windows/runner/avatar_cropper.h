#ifndef AVATAR_CROPPER_H_
#define AVATAR_CROPPER_H_

#include <flutter/plugin_registry.h>

// 导出函数，用于向Flutter注册插件
#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// 修改函数签名，使用PluginRegistry::Registrar*来匹配generated_plugin_registrant.cc
FLUTTER_PLUGIN_EXPORT void AvatarCropperPluginRegisterWithRegistrar(
    flutter::PluginRegistry::Registrar* registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // AVATAR_CROPPER_H_