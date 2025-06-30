// lib/utils/dart/func_extension.dart

typedef FutureVoidCallback = Future<void> Function();
typedef FutureVoidCallbackObject<T> = Future<void> Function(T);

typedef FutureVoidCallbackString = FutureVoidCallbackObject<String>;
typedef FutureVoidCallbackBool = FutureVoidCallbackObject<bool>;

typedef FutureVoidCallbackNullableBool = FutureVoidCallbackObject<bool?>;
typedef FutureVoidCallbackNullableString = FutureVoidCallbackObject<String?>;

typedef VoidCallback = void Function();

typedef VoidCallbackObject<T> = void Function(T);

typedef VoidCallbackString = VoidCallbackObject<String>;
typedef VoidCallbackBool = VoidCallbackObject<bool>;

typedef VoidCallbackNullableBool = VoidCallbackObject<bool?>;
typedef VoidCallbackNullableString = VoidCallbackObject<String?>;
