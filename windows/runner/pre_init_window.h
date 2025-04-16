#ifndef RUNNER_PRE_INIT_WINDOW_H_
#define RUNNER_PRE_INIT_WINDOW_H_

#include <windows.h>
#include <winhttp.h>    // Windows HTTP API
#include <wincrypt.h>   // Windows 加密 API
#include <shlwapi.h>    // Shell 轻量级 API
#include <shlobj.h>     // Shell 对象 API
#include <dwmapi.h>     // 桌面窗口管理器 API
#include <string>
#include <vector>
#include <map>
#include <iomanip>      // 用于格式化输出
#include <sstream>      // 字符串流
#include <functional>
#include <memory>

#pragma comment(lib, "Shlwapi.lib")

class PreInitWindow {
public:
    PreInitWindow();
    ~PreInitWindow();

    // 禁止拷贝
    PreInitWindow(const PreInitWindow&) = delete;
    PreInitWindow& operator=(const PreInitWindow&) = delete;

    static bool ShowPreInitCheck();

		// 静态方法：设置安全网络层
		static bool SetupSecureNetworkLayer();
	
		// 静态方法：验证证书
		static bool ValidateCertificate(const char* hostname, const uint8_t* certData, size_t certSize);
		
		// 静态方法：计算证书哈希
		static std::vector<uint8_t> CalculateCertificateHash(const uint8_t* certData, size_t certSize);
		
		// 静态方法：将哈希转换为字符串
		static std::string HashToString(const std::vector<uint8_t>& hash);

private:
    class WindowClass {
    public:
        WindowClass();
        ~WindowClass();

        WindowClass(const WindowClass&) = delete;
        WindowClass& operator=(const WindowClass&) = delete;

        const wchar_t* GetName() const { return class_name_; }

    private:
        static constexpr const wchar_t* class_name_ = L"PreInitCheckWindow";
        HINSTANCE instance_;
    };

    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
    void CreateControls();
    void UpdateStatus(const wchar_t* message, int progress);
    bool RunChecks();
    void Cleanup();
    bool CheckResourceFiles();
		// 网络安全检查方法
		bool CheckNetworkSecurity();
				
		// TLS 设置验证
		//bool VerifyTLSSettings();
		
		// 系统代理检查
		bool CheckSystemProxies();
		
		// 获取固定证书哈希
		static std::vector<uint8_t> GetPinnedCertificateHash(const char* hostname);
		
		// WinHTTP 会话句柄
		static HINTERNET http_session_;
		
    static std::vector<std::wstring> GetRequiredResources();
		bool is_checking_ = false;  // 添加此变量

    static WindowClass window_class_;

    HWND window_handle_;
    HWND progress_bar_;
    HWND status_text_;
    UINT_PTR timer_id_;
    int current_check_;
    bool has_shown_error_ = false;

    struct WindowDeleter {
        void operator()(HWND hwnd) const {
            if (hwnd) {
                DestroyWindow(hwnd);
            }
        }
    };

    std::unique_ptr<HWND__, WindowDeleter> window_ptr_;
};

#endif  // RUNNER_PRE_INIT_WINDOW_H_