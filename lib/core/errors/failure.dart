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
  return ServerFailure(message: _sanitizeFailureMessage(error.toString()));
}

String _sanitizeFailureMessage(String raw) {
  var msg = raw.trim();
  if (msg.isEmpty) return 'Something went wrong';

  const prefixes = <String>[
    'Bad state: ',
    'Exception: ',
    'StateError: ',
    'Invalid argument(s): ',
    'ArgumentError: ',
  ];

  for (final p in prefixes) {
    if (msg.startsWith(p)) {
      msg = msg.substring(p.length).trimLeft();
      break;
    }
  }

  return msg.isEmpty ? 'Something went wrong' : msg;
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
