// pre_init_window.cpp
#include "pre_init_window.h"
#include <CommCtrl.h>
#include <vector>
#include <functional>
#include <shlobj.h>
#include <dwmapi.h>
#include <shlwapi.h> 

#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "Shlwapi.lib")  // 添加库链接

PreInitWindow::WindowClass PreInitWindow::window_class_;

PreInitWindow::WindowClass::WindowClass()
    : instance_(GetModuleHandle(nullptr)) {
    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = PreInitWindow::WindowProc;
    wc.hInstance = instance_;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = class_name_;
    
    RegisterClassExW(&wc);
}

PreInitWindow::WindowClass::~WindowClass() {
    UnregisterClassW(class_name_, instance_);
}

PreInitWindow::PreInitWindow() 
    : window_handle_(nullptr)
    , progress_bar_(nullptr)
    , status_text_(nullptr)
    , timer_id_(0)
    , current_check_(0) {
    
    INITCOMMONCONTROLSEX icex = {
        sizeof(INITCOMMONCONTROLSEX),
        ICC_PROGRESS_CLASS | ICC_STANDARD_CLASSES
    };
    InitCommonControlsEx(&icex);
    
    int screen_width = GetSystemMetrics(SM_CXSCREEN);
    int screen_height = GetSystemMetrics(SM_CYSCREEN);
    int window_width = 480;  // 增加窗口宽度
    int window_height = 260; // 增加窗口高度
    int window_x = (screen_width - window_width) / 2;
    int window_y = (screen_height - window_height) / 2;
    
    window_handle_ = CreateWindowExW(
        WS_EX_LAYERED,  // 使用分层窗口
        window_class_.GetName(),
        L"System Environment Check",
        WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU,
        window_x, window_y,
        window_width, window_height,
        nullptr, nullptr,
        GetModuleHandle(nullptr), nullptr
    );
    
    if (window_handle_) {
        // 设置窗口透明度
        SetLayeredWindowAttributes(window_handle_, 0, 245, LWA_ALPHA);
        
        // 启用DWM阴影
        DWMNCRENDERINGPOLICY policy = DWMNCRP_ENABLED;
        DwmSetWindowAttribute(window_handle_, DWMWA_NCRENDERING_POLICY, &policy, sizeof(policy));
        
        // 设置圆角
        MARGINS margins = {1, 1, 1, 1};
        DwmExtendFrameIntoClientArea(window_handle_, &margins);
        
        window_ptr_.reset(window_handle_);
        SetWindowLongPtr(window_handle_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
        CreateControls();
    }
}

PreInitWindow::~PreInitWindow() {
    Cleanup();
}

void PreInitWindow::Cleanup() {
    if (timer_id_) {
        KillTimer(window_handle_, timer_id_);
        timer_id_ = 0;
    }

    if (progress_bar_) {
        DestroyWindow(progress_bar_);
        progress_bar_ = nullptr;
    }

    if (status_text_) {
        DestroyWindow(status_text_);
        status_text_ = nullptr;
    }

    // window_ptr_ 的析构函数会处理主窗口
}

bool PreInitWindow::ShowPreInitCheck() {
    PreInitWindow window;
    if (!window.window_handle_) return false;

    // 显示窗口并开始检查
    ShowWindow(window.window_handle_, SW_SHOW);
    UpdateWindow(window.window_handle_);

    window.timer_id_ = SetTimer(window.window_handle_, 1, 50, nullptr);

    // 消息循环带超时
    DWORD start_time = GetTickCount();
    const DWORD max_wait_time = 2000; // 2秒超时
    bool result = true;

    MSG msg;
    while (GetTickCount() - start_time < max_wait_time) {
        while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) {
                return msg.wParam != 0;
            }
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        Sleep(1);
    }

    return result;
}

void PreInitWindow::CreateControls() {
	// 创建标题
	HFONT hFont = CreateFontW(24, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
			DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
			CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
			
	HWND title = CreateWindowExW(
			0, L"STATIC",
			L"Environment Check",
			WS_CHILD | WS_VISIBLE | SS_CENTER,
			20, 20, 440, 30,
			window_handle_, nullptr,
			GetModuleHandle(nullptr), nullptr
	);
	SendMessage(title, WM_SETFONT, (WPARAM)hFont, TRUE);
	
	// 创建进度条 - 使用现代风格
	progress_bar_ = CreateWindowExW(
			0, PROGRESS_CLASSW,
			nullptr,
			WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
			40, 120, 400, 8,  // 更细的进度条
			window_handle_, nullptr,
			GetModuleHandle(nullptr), nullptr
	);
	
	// 创建状态文本 - 使用更好的字体
	HFONT hFontStatus = CreateFontW(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
			DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
			CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
			
	status_text_ = CreateWindowExW(
			0, L"STATIC",
			L"Preparing to check system environment...",
			WS_CHILD | WS_VISIBLE | SS_CENTER,
			20, 80, 440, 24,
			window_handle_, nullptr,
			GetModuleHandle(nullptr), nullptr
	);
	SendMessage(status_text_, WM_SETFONT, (WPARAM)hFontStatus, TRUE);
	
	// 添加详细信息文本框
	HWND info_text = CreateWindowExW(
			0, L"STATIC",
			L"This will ensure your system meets all requirements",
			WS_CHILD | WS_VISIBLE | SS_CENTER,
			20, 160, 440, 20,
			window_handle_, nullptr,
			GetModuleHandle(nullptr), nullptr
	);
	SendMessage(info_text, WM_SETFONT, (WPARAM)hFontStatus, TRUE);
	
	if (progress_bar_) {
			SendMessage(progress_bar_, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
			SendMessage(progress_bar_, PBM_SETSTEP, 1, 0);
			// 设置进度条颜色
			SendMessage(progress_bar_, PBM_SETBARCOLOR, 0, RGB(0, 120, 215));
			SendMessage(progress_bar_, PBM_SETBKCOLOR, 0, RGB(200, 200, 200));
	}
}

void PreInitWindow::UpdateStatus(const wchar_t* message, int progress) {
    if (status_text_) {
        SetWindowTextW(status_text_, message);
    }
    if (progress_bar_) {
        SendMessage(progress_bar_, PBM_SETPOS, progress, 0);
    }
    if (window_handle_) {
        UpdateWindow(window_handle_);
    }
}
std::vector<std::wstring> PreInitWindow::GetRequiredResources() {
	return {
			L"data\\flutter_assets",
			L"data\\icudtl.dat",
	};
}

bool PreInitWindow::RunChecks() {
	struct CheckItem {
			std::wstring message;
			std::function<bool()> check;
	};

	const CheckItem checks[] = {
			{
					L"Checking system requirements...",
					[this]() {
							SYSTEM_INFO si;
							GetSystemInfo(&si);
							if (si.wProcessorArchitecture != PROCESSOR_ARCHITECTURE_AMD64 && !has_shown_error_) {
									MessageBoxW(window_handle_, L"System architecture not supported", L"Error", MB_ICONERROR);
									has_shown_error_ = true;
									return false;
							}
							return si.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64;
					}
			},
			{
					L"Checking runtime environment...",
					[this]() {
							if (HMODULE hModule = LoadLibraryW(L"vcruntime140.dll")) {
									FreeLibrary(hModule);
									return true;
							}
							if (!has_shown_error_) {
									MessageBoxW(window_handle_, L"Required runtime not found: vcruntime140.dll", L"Error", MB_ICONERROR);
									has_shown_error_ = true;
							}
							return false;
					}
			},
			{
					L"Checking storage access...",
					[this]() {
							wchar_t path[MAX_PATH];
							if (!SUCCEEDED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, path)) && !has_shown_error_) {
									MessageBoxW(window_handle_, L"Unable to access local storage", L"Error", MB_ICONERROR);
									has_shown_error_ = true;
									return false;
							}
							return SUCCEEDED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, path));
					}
			},
			{
					L"Checking resource files...",
					[this]() { return this->CheckResourceFiles(); }
			},
			{
				L"Checking network...",
				[this]() { return this->CheckNetworkSecurity(); }
			}
	};

	const int total_checks = sizeof(checks) / sizeof(checks[0]);

	if (current_check_ >= total_checks) {
			UpdateStatus(L"Initialization complete", 100);
			Sleep(100);
			PostQuitMessage(1);
			return true;
	}

	const auto& check = checks[current_check_];
	UpdateStatus(check.message.c_str(), (current_check_ * 100) / total_checks);

	bool check_result = check.check();
	if (!check_result) {
			KillTimer(window_handle_, timer_id_);  // 在检查失败时也停止定时器
			timer_id_ = 0;
			PostQuitMessage(0);
			return false;
	}
	current_check_++;
	return true;
}

// 初始化静态变量
HINTERNET PreInitWindow::http_session_ = NULL;

// 实现网络安全检查方法
bool PreInitWindow::CheckNetworkSecurity() {
    // 检查 TLS 安全设置
    bool tlsCheck = VerifyTLSSettings();
    
    
    if (!tlsCheck && !has_shown_error_) {
        MessageBoxW(window_handle_, L"setting warning,connection is not safe", 
                   L"waring", MB_ICONWARNING);
        // 仅警告，不中断启动
    }
    
    // 即使有警告也继续，但记录了警告状态
    return true;
}

bool PreInitWindow::VerifyTLSSettings() {
    // 检查系统是否有安全的 TLS 版本
    HMODULE hModule = LoadLibraryW(L"schannel.dll");
    if (!hModule) {
        return false;
    }
    FreeLibrary(hModule);
    
    // 检查 Windows 安全策略设置中的 TLS 1.2 状态
    DWORD secureProtocols = 0;
    DWORD bufSize = sizeof(secureProtocols);
    DWORD regType = REG_DWORD;
    LONG result = RegGetValueW(
        HKEY_LOCAL_MACHINE,
        L"SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\TLS 1.2\\Client",
        L"Enabled",
        RRF_RT_REG_DWORD,
        &regType,
        &secureProtocols,
        &bufSize
    );
    
    // 如果 TLS 1.2 启用，返回 true
    if (result == ERROR_SUCCESS && secureProtocols == 1) {
        return true;
    }
    
    // 检查 TLS 1.3 (如果系统支持)
    secureProtocols = 0;
    result = RegGetValueW(
        HKEY_LOCAL_MACHINE,
        L"SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\TLS 1.3\\Client",
        L"Enabled",
        RRF_RT_REG_DWORD,
        &regType,
        &secureProtocols,
        &bufSize
    );
    
    return (result == ERROR_SUCCESS && secureProtocols == 1);
}

bool PreInitWindow::CheckSystemProxies() {
    WINHTTP_CURRENT_USER_IE_PROXY_CONFIG proxyConfig;
    ZeroMemory(&proxyConfig, sizeof(proxyConfig));
    
    if (WinHttpGetIEProxyConfigForCurrentUser(&proxyConfig)) {
        // 检查是否有可能不安全的代理设置
        
        // 释放资源
        if (proxyConfig.lpszProxy) GlobalFree(proxyConfig.lpszProxy);
        if (proxyConfig.lpszProxyBypass) GlobalFree(proxyConfig.lpszProxyBypass);
        if (proxyConfig.lpszAutoConfigUrl) GlobalFree(proxyConfig.lpszAutoConfigUrl);
        
        return true;
    }
    return false;
}

bool PreInitWindow::CheckResourceFiles() {
	const auto resources = GetRequiredResources();
	std::wstring missing_files;
	
	for (const auto& resource : resources) {
			wchar_t full_path[MAX_PATH];
			if (GetModuleFileNameW(nullptr, full_path, MAX_PATH) == 0) {
					continue;
			}
			
			if (!PathRemoveFileSpecW(full_path)) {
					continue;
			}
			
			if (!PathAppendW(full_path, resource.c_str())) {
					continue;
			}
			
			if (GetFileAttributesW(full_path) == INVALID_FILE_ATTRIBUTES) {
					if (!missing_files.empty()) {
							missing_files += L"\n";
					}
					missing_files += resource;
			}
	}
	
	if (!missing_files.empty() && !has_shown_error_) {
			std::wstring error_message = L"Missing required files:\n" + missing_files;
			MessageBoxW(window_handle_, error_message.c_str(), L"Resource Error", MB_ICONERROR);
			has_shown_error_ = true;
			return false;
	}
	
	return missing_files.empty();
}

LRESULT CALLBACK PreInitWindow::WindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
	if (PreInitWindow* window = reinterpret_cast<PreInitWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA))) {
			switch (msg) {
					case WM_TIMER:
							if (wp == window->timer_id_ && !window->is_checking_) {
									window->is_checking_ = true;  // 设置检查标志
									if (!window->RunChecks()) {
											KillTimer(hwnd, window->timer_id_);  // 停止定时器
											window->timer_id_ = 0;
									}
									window->is_checking_ = false;  // 清除检查标志
							}
							return 0;

					case WM_CLOSE:
							PostQuitMessage(0);
							return 0;

					case WM_DESTROY:
							window->Cleanup();
							return 0;
			}
	}
	return DefWindowProcW(hwnd, msg, wp, lp);
}