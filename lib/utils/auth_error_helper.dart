import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorPresentation {
  final String message;
  final bool showToUser;

  const AuthErrorPresentation._(this.message, this.showToUser);

  const AuthErrorPresentation.show(String message) : this._(message, true);
  const AuthErrorPresentation.hide() : this._('', false);
}

class AuthErrorHelper {
  static AuthErrorPresentation present(Object error) {
    if (_isUserCancelled(error)) {
      return const AuthErrorPresentation.hide();
    }

    if (error is SocketException || error is TimeoutException) {
      return const AuthErrorPresentation.show(
        'Network error. Please check your connection and try again.',
      );
    }

    if (error is AuthException) {
      return AuthErrorPresentation.show(_fromSupabaseMessage(error.message));
    }

    if (error is AuthApiException) {
      return AuthErrorPresentation.show(_fromSupabaseMessage(error.message));
    }

    final message = error.toString();
    if (_looksLikeNetworkMessage(message)) {
      return const AuthErrorPresentation.show(
        'Network error. Please check your connection and try again.',
      );
    }

    return const AuthErrorPresentation.show(
      'Something went wrong. Please try again.',
    );
  }

  static String message(Object error) => present(error).message;

  static bool _isUserCancelled(Object error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('canceled') || code.contains('cancelled')) {
        return true;
      }
    }

    final lower = error.toString().toLowerCase();
    return lower.contains('canceled') ||
        lower.contains('cancelled') ||
        lower.contains('sign_in_canceled') ||
        lower.contains('sign_in_cancelled');
  }

  static bool _looksLikeNetworkMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('unreachable') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup');
  }

  static String _fromSupabaseMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_grant')) {
      return 'Incorrect email or password.';
    }

    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed') ||
        lower.contains('confirm your email')) {
      return 'Please verify your email, then try again.';
    }

    if (lower.contains('user already registered') ||
        lower.contains('already exists') ||
        lower.contains('already registered')) {
      return 'An account with this email already exists. Try logging in instead.';
    }

    if (lower.contains('password') && lower.contains('at least')) {
      return 'Your password is too weak. Please choose a stronger password.';
    }

    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (_looksLikeNetworkMessage(message)) {
      return 'Network error. Please check your connection and try again.';
    }

    if (lower.contains('oauth') ||
        lower.contains('redirect_uri') ||
        lower.contains('redirect uri')) {
      return 'Sign-in provider configuration error. Please try again later.';
    }

    if (lower.contains('invalid email') || lower.contains('email address')) {
      return 'Please enter a valid email address.';
    }

    return 'Authentication failed. Please try again.';
  }
}

