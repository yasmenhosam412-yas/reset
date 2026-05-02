import 'dart:async';

import 'package:new_project/core/errors/network_error_flags.dart'
    if (dart.library.html) 'package:new_project/core/errors/network_error_flags_stub.dart';

abstract class Failure {
  final String message;

  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class NetworkFailure extends Failure {
  NetworkFailure({super.message = "No internet connection"});
}

Failure failureFromException(Object error) {
  if (error is Failure) return error;
  if (error is TimeoutException) {
    return NetworkFailure(message: 'Request timed out');
  }
  if (isIoNetworkError(error)) {
    return NetworkFailure();
  }
  return ServerFailure(message: error.toString());
}

bool authMessageLooksLikeNetworkFailure(String message) {
  final m = message.toLowerCase();
  return m.contains('network') ||
      m.contains('socket') ||
      m.contains('failed host lookup') ||
      m.contains('connection refused') ||
      m.contains('connection reset') ||
      m.contains('connection closed') ||
      m.contains('internet') ||
      m.contains('offline') ||
      m.contains('timed out') ||
      m.contains('timeout') ||
      m.contains('no address associated') ||
      m.contains('host lookup failed');
}
