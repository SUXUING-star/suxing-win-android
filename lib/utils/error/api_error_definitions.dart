// lib/utils/error/api_error_definitions.dart

// 后端 API 返回的业务错误码常量 (直接从你的 Go 代码中的 Code* 转换)
class BackendApiErrorCodes {
  static const String internalError = "INTERNAL_ERROR";
  static const String notFound = "NOT_FOUND";
  static const String unAuthorized = "UNAUTHORIZED";
  static const String invalidCredentials = "INVALID_CREDENTIALS";
  static const String permissionDenied = "PERMISSION_DENIED";
  static const String validationFailed = "VALIDATION_FAILED";
  static const String invalidInput = "INVALID_INPUT";
  static const String databaseError = "DATABASE_ERROR"; // 你从 SERVER_ERROR 改的
  static const String serverError = "SERVER_ERROR";   // 你保留的通用服务器错误
  static const String invalidPayload = "INVALID_PAYLOAD";
  static const String missingParam = "MISSING_PARAM";
  static const String noChanges = "NO_CHANGES";
  static const String rateLimited = "RATE_LIMITED";
  static const String createLimit = "CREATE_LIMIT";
  static const String gamePendingApproval = "GAME_PENDING_APPROVAL";
  static const String postLock = "POST_LOCK";
  static const String deleteLimit = "DELETE_LIMIT";
  static const String contentForbidden = "CONTENT_FORBIDDEN";
  static const String duplicateData = "DUPLICATE_DATA";    // 对应 ErrDuplicateEntry
  static const String consistencyError = "CONSISTENCY_ERROR"; // 对应 ErrFindCheck

  static const String networkNoConnection = "NETWORK_NO_CONNECTION";
  static const String networkTimeout = "NETWORK_TIMEOUT";
  static const String networkGenericError = "NETWORK_GENERIC_ERROR"; // 其他网络问题
  static const String networkHostLookupFailed = "NETWORK_HOST_LOOKUP_FAILED";

  // 用于处理未在下面注册的错误码，或者当后端未返回明确code时
  static const String unknownFromApi = "UNKNOWN_FROM_API";
  static const String httpErrorPrefix = "HTTP_"; // 用于包装纯HTTP错误
}

// API 错误描述符，包含Flutter端如何处理这个错误的信息
class ApiErrorDescriptor {
  final String code; // 后端返回的原始业务码
  final String defaultUserMessage; // 从你后端 Message 来的
  final bool isRetryable; // 这个错误是否适合自动重试 (需要根据错误类型判断)
  final int defaultHttpStatus; // 从你后端 Status 来的

  const ApiErrorDescriptor({
    required this.code,
    required this.defaultUserMessage,
    required this.defaultHttpStatus,
    this.isRetryable = false, // 默认不可重试，具体情况具体分析
  });
}

// API 错误注册表/映射 (基于你后端的 errorMap 转换)
class ApiErrorRegistry {
  static final Map<String, ApiErrorDescriptor> _descriptors = {
    // --- NotFound (HTTP 404) ---
    // ErrGameNotFound, mongo.ErrNoDocuments, ErrPostNotFound, etc. 都会映射到 CodeNotFound
    BackendApiErrorCodes.notFound: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.notFound,
      defaultUserMessage: "请求的资源未找到", // 统一用一个，或者你可以细分
      defaultHttpStatus: 404,
      isRetryable: false,
    ),

    // --- Forbidden / Unauthorized (HTTP 400, 401, 403) ---
    BackendApiErrorCodes.invalidCredentials: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.invalidCredentials,
      defaultUserMessage: "用户名或密码不正确，请检查后重试",
      defaultHttpStatus: 400, // 后端是 http.StatusBadRequest
      isRetryable: false,
    ),
    BackendApiErrorCodes.unAuthorized: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.unAuthorized,
      defaultUserMessage: "未登录或认证已失效，请重新登录",
      defaultHttpStatus: 401, // 后端是 http.StatusUnauthorized
      isRetryable: false,
    ),
    BackendApiErrorCodes.permissionDenied: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.permissionDenied,
      defaultUserMessage: "抱歉，您没有权限执行此操作",
      defaultHttpStatus: 403, // 后端是 http.StatusForbidden
      isRetryable: false,
    ),
    BackendApiErrorCodes.gamePendingApproval: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.gamePendingApproval,
      defaultUserMessage: "该游戏正在审核中，请耐心等待",
      defaultHttpStatus: 403, // 后端是 http.StatusForbidden
      isRetryable: false,
    ),
    BackendApiErrorCodes.postLock: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.postLock,
      defaultUserMessage: "该帖子已被锁定，无法进行操作",
      defaultHttpStatus: 403, // 后端是 http.StatusForbidden
      isRetryable: false,
    ),

    // --- BadRequest / Client Errors (HTTP 400) ---
    BackendApiErrorCodes.invalidInput: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.invalidInput,
      defaultUserMessage: "请求参数不正确或格式无效，请检查后重试",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),
    BackendApiErrorCodes.noChanges: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.noChanges,
      defaultUserMessage: "您的请求未包含任何需要更新的有效字段",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),
    BackendApiErrorCodes.contentForbidden: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.contentForbidden,
      defaultUserMessage: "您提交的内容可能包含不被允许的词汇或信息，请修改后重试",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),
    BackendApiErrorCodes.validationFailed: const ApiErrorDescriptor( // 假设它也是 400
      code: BackendApiErrorCodes.validationFailed,
      defaultUserMessage: "数据校验失败，请检查您的输入。",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),
    BackendApiErrorCodes.invalidPayload: const ApiErrorDescriptor( // 假设它也是 400
      code: BackendApiErrorCodes.invalidPayload,
      defaultUserMessage: "请求体无效或格式错误。",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),
    BackendApiErrorCodes.missingParam: const ApiErrorDescriptor( // 假设它也是 400
      code: BackendApiErrorCodes.missingParam,
      defaultUserMessage: "缺少必要的请求参数。",
      defaultHttpStatus: 400,
      isRetryable: false,
    ),

    // --- 新增网络错误描述符 ---
    BackendApiErrorCodes.networkNoConnection: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.networkNoConnection,
      defaultUserMessage: "当前无网络连接，请检查您的网络设置后重试。",
      defaultHttpStatus: 0, // 表示非 HTTP 错误
      isRetryable: true, // 通常网络恢复后可重试
    ),
    BackendApiErrorCodes.networkTimeout: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.networkTimeout,
      defaultUserMessage: "网络请求超时，请稍后重试。",
      defaultHttpStatus: 0,
      isRetryable: true,
    ),
    BackendApiErrorCodes.networkHostLookupFailed: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.networkHostLookupFailed,
      defaultUserMessage: "无法连接到服务器，请检查网络或稍后再试。", // 稍微通用一点
      defaultHttpStatus: 0,
      isRetryable: true,
    ),
    BackendApiErrorCodes.networkGenericError: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.networkGenericError,
      defaultUserMessage: "网络连接发生未知错误，请稍后重试。",
      defaultHttpStatus: 0,
      isRetryable: true,
    ),


    // --- Conflict (HTTP 409) ---
    BackendApiErrorCodes.duplicateData: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.duplicateData,
      defaultUserMessage: "操作冲突，您尝试创建的数据可能已存在",
      defaultHttpStatus: 409, // 后端是 http.StatusConflict
      isRetryable: false,
    ),

    // --- TooManyRequests (HTTP 429) ---
    BackendApiErrorCodes.rateLimited: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.rateLimited,
      defaultUserMessage: "您的请求过于频繁，请稍后再试",
      defaultHttpStatus: 429, // 后端是 http.StatusTooManyRequests
      isRetryable: true, // 通常限流是可以重试的
    ),
    // --- TooManyRequests (HTTP 429) ---
    BackendApiErrorCodes.createLimit: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.createLimit,
      defaultUserMessage: "今天创建次数超出上限",
      defaultHttpStatus: 429, // 后端是 http.StatusTooManyRequests
      isRetryable: true, // 通常限流是可以重试的
    ),
    BackendApiErrorCodes.deleteLimit: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.deleteLimit,
      defaultUserMessage: "操作不符合限制，例如资源创建时间过短不允许删除",
      defaultHttpStatus: 429, // 后端是 http.StatusTooManyRequests
      isRetryable: false, // 这类限制通常不是简单重试能解决的
    ),

    // --- Server Errors (HTTP 500, 5xx) ---
    BackendApiErrorCodes.internalError: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.internalError,
      defaultUserMessage: "服务器内部发生未知错误，请稍后重试或联系管理员",
      defaultHttpStatus: 500,
      isRetryable: true, // 服务器内部错误通常可以重试
    ),
    BackendApiErrorCodes.databaseError: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.databaseError,
      defaultUserMessage: "服务器数据库操作失败，请稍后再试。", // 你后端没给具体message，我编一个
      defaultHttpStatus: 500, // 假设也是500
      isRetryable: true,
    ),
    BackendApiErrorCodes.serverError: const ApiErrorDescriptor( // 通用服务器错误
      code: BackendApiErrorCodes.serverError,
      defaultUserMessage: "服务器发生错误，请稍后再试。",
      defaultHttpStatus: 500,
      isRetryable: true,
    ),
    BackendApiErrorCodes.consistencyError: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.consistencyError,
      defaultUserMessage: "服务器内部状态异常，我们正在处理",
      defaultHttpStatus: 500, // 后端是 http.StatusInternalServerError
      isRetryable: true, // 内部状态异常可能恢复
    ),

    // --- Default for unknown codes from API ---
    BackendApiErrorCodes.unknownFromApi: const ApiErrorDescriptor(
      code: BackendApiErrorCodes.unknownFromApi,
      defaultUserMessage: "发生未知API错误，请稍后再试。",
      defaultHttpStatus: 500, // 默认按服务器错误处理
      isRetryable: true,
    ),
  };

  static ApiErrorDescriptor getDescriptor(String backendCode) {
    return _descriptors[backendCode] ?? _descriptors[BackendApiErrorCodes.unknownFromApi]!;
  }

  // 为纯HTTP错误码（没有后端业务code的情况）提供一个描述符
  static ApiErrorDescriptor getHttpErrorDescriptor(int httpStatusCode) {
    String message;
    bool retryable = false;
    switch (httpStatusCode) {
      case 400:
        message = "错误的请求";
        break;
      case 401:
        message = "需要身份认证";
        break;
      case 403:
        message = "禁止访问";
        break;
      case 404:
        message = "请求的资源未找到";
        break;
      case 429:
        message = "请求过于频繁";
        retryable = true;
        break;
      case 500:
        message = "服务器内部错误";
        retryable = true;
        break;
      case 502:
        message = "网关错误";
        retryable = true;
        break;
      case 503:
        message = "服务不可用";
        retryable = true;
        break;
      case 504:
        message = "网关超时";
        retryable = true;
        break;
      default:
        message = "网络请求发生未知错误 (HTTP $httpStatusCode)";
        if (httpStatusCode >= 500) retryable = true;
    }
    return ApiErrorDescriptor(
      code: '${BackendApiErrorCodes.httpErrorPrefix}$httpStatusCode',
      defaultUserMessage: message,
      defaultHttpStatus: httpStatusCode,
      isRetryable: retryable,
    );
  }
}