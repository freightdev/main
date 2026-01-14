import 'package:equatable/equatable.dart';

abstract class AppException extends Equatable implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() =>
      'AppException: $message${code != null ? " (Code: $code)" : ""}';

  @override
  List<Object?> get props => [message, code, details];
}

class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? " (Status: $statusCode)" : ""}${code != null ? " (Code: $code)" : ""}';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ParseException extends AppException {
  const ParseException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}
