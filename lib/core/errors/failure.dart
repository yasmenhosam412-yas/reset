import 'dart:async';

import 'package:new_project/core/errors/network_error_flags.dart'
    if (dart.library.html) 'package:new_project/core/errors/network_error_flags_stub.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

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

/// Maps to a clear message when RLS blocks actions (e.g. frozen account).
class AccountSuspendedFailure extends Failure {
  AccountSuspendedFailure({super.message = _defaultSuspendedMessage});

  static const String _defaultSuspendedMessage =
      'Your account is temporarily suspended. Posting, comments, and other '
      'actions are disabled until the suspension ends.';
}

Failure failureFromException(Object error) {
  if (error is Failure) return error;
  if (error is TimeoutException) {
    return NetworkFailure(message: 'Request timed out');
  }
  if (isIoNetworkError(error)) {
    return NetworkFailure();
  }
  if (error is PostgrestException && _postgrestIsRowLevelSecurityBlock(error)) {
    return AccountSuspendedFailure();
  }
  return ServerFailure(message: _sanitizeFailureMessage(error.toString()));
}

/// PostgREST surfaces RLS denials as row-level security violations (e.g. frozen account).
bool _postgrestIsRowLevelSecurityBlock(PostgrestException e) {
  final blob =
      '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
  return blob.contains('row-level security') || blob.contains('rls policy');
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
