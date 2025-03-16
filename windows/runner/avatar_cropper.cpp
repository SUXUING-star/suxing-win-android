#include <windows.h>
#include <gdiplus.h>
#include <string>
#include <vector>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

#include "avatar_cropper.h"

#pragma comment(lib, "Gdiplus.lib")

// 头像裁剪类
class AvatarCropper {
private:
    ULONG_PTR m_gdiplusToken;
    
    // 初始化GDI+
    bool InitGdiplus() {
        Gdiplus::GdiplusStartupInput startupInput;
        return Gdiplus::GdiplusStartup(&m_gdiplusToken, &startupInput, NULL) == Gdiplus::Ok;
    }
    
    // 关闭GDI+
    void ShutdownGdiplus() {
        Gdiplus::GdiplusShutdown(m_gdiplusToken);
    }
    
    // 将宽字符串转换为UTF8
    std::string WideToUtf8(const std::wstring& wide) {
        if (wide.empty()) return std::string();
        
        int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wide[0], (int)wide.size(),
                                              NULL, 0, NULL, NULL);
        std::string utf8(size_needed, 0);
        WideCharToMultiByte(CP_UTF8, 0, &wide[0], (int)wide.size(),
                            &utf8[0], size_needed, NULL, NULL);
        return utf8;
    }
    
    // 将UTF8转换为宽字符串
    std::wstring Utf8ToWide(const std::string& utf8) {
        if (utf8.empty()) return std::wstring();
        
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(), NULL, 0);
        std::wstring wide(size_needed, 0);
        MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(), &wide[0], size_needed);
        return wide;
    }

public:
    AvatarCropper() {
        InitGdiplus();
    }
    
    ~AvatarCropper() {
        ShutdownGdiplus();
    }
    
    // 裁剪头像为圆形
    bool CropAvatarCircle(
        const std::string& inputPath,
        const std::string& outputPath,
        double sourceX,
        double sourceY,
        double sourceWidth,
        double sourceHeight,
        int outputSize
    ) {
        std::wstring wInputPath = Utf8ToWide(inputPath);
        std::wstring wOutputPath = Utf8ToWide(outputPath);
        
        // 加载源图像
        Gdiplus::Bitmap* sourceImage = Gdiplus::Bitmap::FromFile(wInputPath.c_str());
        if (!sourceImage || sourceImage->GetLastStatus() != Gdiplus::Ok) {
            delete sourceImage;
            return false;
        }
        
        // 创建输出图像
        Gdiplus::Bitmap* outputImage = new Gdiplus::Bitmap(outputSize, outputSize, PixelFormat32bppARGB);
        if (!outputImage || outputImage->GetLastStatus() != Gdiplus::Ok) {
            delete sourceImage;
            delete outputImage;
            return false;
        }
        
        // 创建图形对象
        Gdiplus::Graphics* graphics = Gdiplus::Graphics::FromImage(outputImage);
        graphics->SetSmoothingMode(Gdiplus::SmoothingModeHighQuality);
        graphics->SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
        graphics->SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
        
        // 创建圆形路径 - 修复AddEllipse重载问题
        Gdiplus::GraphicsPath path;
        // 使用Rect而不是直接传递坐标，明确指定使用哪个重载
        Gdiplus::Rect ellipseRect(0, 0, outputSize, outputSize);
        path.AddEllipse(ellipseRect);
        
        // 设置裁剪区域
        graphics->SetClip(&path);
        
        // 计算源矩形和目标矩形 - 修复浮点转换问题
        Gdiplus::RectF srcRect(
            static_cast<Gdiplus::REAL>(sourceX), 
            static_cast<Gdiplus::REAL>(sourceY), 
            static_cast<Gdiplus::REAL>(sourceWidth), 
            static_cast<Gdiplus::REAL>(sourceHeight)
        );
        Gdiplus::RectF destRect(
            0.0f, 
            0.0f, 
            static_cast<Gdiplus::REAL>(outputSize), 
            static_cast<Gdiplus::REAL>(outputSize)
        );
        
        // 绘制裁剪后的图像
        graphics->DrawImage(sourceImage, destRect, srcRect, Gdiplus::UnitPixel);
        
        // 保存图像
        CLSID pngClsid;
        GetEncoderClsid(L"image/png", &pngClsid);
        Gdiplus::Status saveStatus = outputImage->Save(wOutputPath.c_str(), &pngClsid);
        
        // 清理资源
        delete graphics;
        delete sourceImage;
        delete outputImage;
        
        return saveStatus == Gdiplus::Ok;
    }
    
    // 获取编码器CLSID
    int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
        UINT num = 0;                     // 编码器数量
        UINT size = 0;                    // 编码器信息大小
        
        Gdiplus::GetImageEncodersSize(&num, &size);
        if (size == 0) return -1;
        
        Gdiplus::ImageCodecInfo* pImageCodecInfo = (Gdiplus::ImageCodecInfo*)(malloc(size));
        if (pImageCodecInfo == NULL) return -1;
        
        Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);
        
        for (UINT i = 0; i < num; ++i) {
            if (wcscmp(pImageCodecInfo[i].MimeType, format) == 0) {
                *pClsid = pImageCodecInfo[i].Clsid;
                free(pImageCodecInfo);
                return i;
            }
        }
        
        free(pImageCodecInfo);
        return -1;
    }
};

// 插件类实现
class AvatarCropperPlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
        auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "com.suxingchahui/avatar_cropper",
            &flutter::StandardMethodCodec::GetInstance());
            
        auto plugin = std::make_unique<AvatarCropperPlugin>();
        
        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto& call, auto result) {
                plugin_pointer->HandleMethodCall(call, std::move(result));
            });
            
        registrar->AddPlugin(std::move(plugin));
    }
    
    AvatarCropperPlugin() {}
    
    virtual ~AvatarCropperPlugin() {}
    
private:
    AvatarCropper cropper;
    
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        
        if (method_call.method_name().compare("cropAvatar") == 0) {
            // 检查参数
            if (!method_call.arguments() || !std::holds_alternative<flutter::EncodableMap>(*method_call.arguments())) {
                result->Error("INVALID_ARGUMENTS", "Arguments are invalid");
                return;
            }
            
            const auto& args = std::get<flutter::EncodableMap>(*method_call.arguments());
            std::string inputPath;
            std::string outputPath;
            double sourceX = 0;
            double sourceY = 0;
            double sourceWidth = 0;
            double sourceHeight = 0;
            int outputSize = 300;
            
            // 提取参数
            auto it = args.find(flutter::EncodableValue("inputPath"));
            if (it != args.end() && std::holds_alternative<std::string>(it->second)) {
                inputPath = std::get<std::string>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("outputPath"));
            if (it != args.end() && std::holds_alternative<std::string>(it->second)) {
                outputPath = std::get<std::string>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("sourceX"));
            if (it != args.end() && std::holds_alternative<double>(it->second)) {
                sourceX = std::get<double>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("sourceY"));
            if (it != args.end() && std::holds_alternative<double>(it->second)) {
                sourceY = std::get<double>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("sourceWidth"));
            if (it != args.end() && std::holds_alternative<double>(it->second)) {
                sourceWidth = std::get<double>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("sourceHeight"));
            if (it != args.end() && std::holds_alternative<double>(it->second)) {
                sourceHeight = std::get<double>(it->second);
            }
            
            it = args.find(flutter::EncodableValue("outputSize"));
            if (it != args.end() && std::holds_alternative<int>(it->second)) {
                outputSize = std::get<int>(it->second);
            }
            
            // 执行裁剪
            bool success = cropper.CropAvatarCircle(
                inputPath, outputPath, sourceX, sourceY, 
                sourceWidth, sourceHeight, outputSize);
                
            if (success) {
                result->Success(flutter::EncodableValue(outputPath));
            } else {
                result->Error("CROP_FAILED", "Failed to crop avatar image");
            }
        } else {
            result->NotImplemented();
        }
    }
};

// 插件注册函数
void AvatarCropperPluginRegisterWithRegistrar(
    flutter::PluginRegistrar* registrar) {
    AvatarCropperPlugin::RegisterWithRegistrar(registrar);
}