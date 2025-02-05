// lib/utils/mongodb_error_handler.dart
class MongoDBErrorHandler {
  static String handleError(dynamic error) {
    if (error.toString().contains('duplicate key')) {
      return '邮箱已被使用';
    }
    if (error.toString().contains('user not found')) {
      return '用户不存在';
    }
    if (error.toString().contains('invalid password')) {
      return '密码错误';
    }
    return '操作失败: $error';
  }
}