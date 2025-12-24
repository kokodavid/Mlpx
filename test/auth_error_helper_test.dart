import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milpress/utils/auth_error_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthErrorHelper', () {
    test('maps invalid credentials to friendly message', () {
      final presentation =
          AuthErrorHelper.present(const AuthException('Invalid login credentials'));
      expect(presentation.showToUser, true);
      expect(presentation.message, 'Incorrect email or password.');
    });

    test('maps user already registered to friendly message', () {
      final presentation = AuthErrorHelper.present(
        const AuthException('User already registered'),
      );
      expect(presentation.showToUser, true);
      expect(
        presentation.message,
        'An account with this email already exists. Try logging in instead.',
      );
    });

    test('maps network errors to friendly message', () {
      final presentation = AuthErrorHelper.present(
        const SocketException('Failed host lookup'),
      );
      expect(presentation.showToUser, true);
      expect(
        presentation.message,
        'Network error. Please check your connection and try again.',
      );
    });

    test('hides user-cancelled flows', () {
      final presentation = AuthErrorHelper.present(
        PlatformException(code: 'sign_in_canceled', message: 'Canceled'),
      );
      expect(presentation.showToUser, false);
    });
  });
}
