import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  const AppException(this.message, {this.permissionDenied = false});

  final String message;
  final bool permissionDenied;

  @override
  String toString() => message;
}

bool isPermissionDenied(Object error) {
  if (error is AppException) return error.permissionDenied;
  if (error is PostgrestException) {
    return error.code == '42501' || error.code == 'PGRST301';
  }
  if (error is StorageException) {
    return error.statusCode == '403' || error.statusCode == '401';
  }
  return false;
}

String describeError(Object error) {
  if (error is AppException) return error.message;
  if (error is AuthException) return error.message;
  if (error is TimeoutException) {
    return 'The request timed out. Check your connection and try again.';
  }
  if (isPermissionDenied(error)) {
    return "You don't have permission to do that.";
  }
  if (error is PostgrestException) {
    switch (error.code) {
      case '23503':
        return 'This item is still in use, so it cannot be removed.';
      case '23505':
        return 'That name is already taken.';
      case '23514':
        return 'Some values are not allowed. Check the form and try again.';
    }
    return error.message;
  }
  if (error is StorageException) return error.message;
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('XMLHttpRequest')) {
    return "Can't reach the server. Check your internet connection.";
  }
  return 'Something went wrong. Please try again.';
}
