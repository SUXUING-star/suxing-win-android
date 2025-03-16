#include "plugin_setup.h"
#include "avatar_cropper.h"

void RegisterPlugins(flutter::PluginRegistry* registry) {
  // 注册头像裁剪插件，使用与generated_plugin_registrant.cc相同的模式
  AvatarCropperPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AvatarCropperPlugin"));
}