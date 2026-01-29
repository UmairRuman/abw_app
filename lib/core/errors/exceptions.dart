// lib/core/errors/exceptions.dart

/// Base exception class
class AppException implements Exception {
  final String message;
  final int? code;

  AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server exception
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ServerException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network exception
class NetworkException extends AppException {
  NetworkException({
    super.message = 'No internet connection',
    super.code = 0,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Cache exception
class CacheException extends AppException {
  CacheException({
    super.message = 'Cache error occurred',
    super.code,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Authentication exception
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Firebase exception
class FirebaseException extends AppException {
  FirebaseException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'FirebaseException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Permission exception
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Permission denied',
    super.code,
  });

  @override
  String toString() => 'PermissionException: $message';
}

/// File exception
class FileException extends AppException {
  FileException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'FileException: $message';
}

/// Timeout exception
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'Request timeout',
    super.code,
  });

  @override
  String toString() => 'TimeoutException: $message';
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found',
    super.code = 404,
  });

  @override
  String toString() => 'NotFoundException: $message';
}

/// Unauthorized exception
class UnauthorizedException extends AppException {
  UnauthorizedException({
    super.message = 'Unauthorized access',
    super.code = 401,
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}