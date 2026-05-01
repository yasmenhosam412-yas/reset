import 'dart:io';

/// True when [error] is a typical transport-level failure (VM / mobile / desktop).
bool isIoNetworkError(Object error) {
  return error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TlsException ||
      error is CertificateException;
}
