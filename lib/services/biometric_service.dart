import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:developer' as developer;

class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _biometricEnabledKey = 'biometric_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      developer.log('Error checking if biometrics is enabled: $e');
      return false;
    }
  }

  Future<void> enableBiometrics() async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: 'true');
    } catch (e) {
      developer.log('Error enabling biometrics: $e');
      rethrow;
    }
  }

  Future<void> disableBiometrics() async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: 'false');
    } catch (e) {
      developer.log('Error disabling biometrics: $e');
      rethrow;
    }
  }

  Future<bool> authenticate() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      developer.log('Can check biometrics: $canCheckBiometrics');
      developer.log('Is device supported: $isDeviceSupported');

      if (!canCheckBiometrics || !isDeviceSupported) {
        developer.log('Biometrics not available on this device');
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      developer.log('Available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        developer.log('No biometrics enrolled');
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      developer.log('Authentication result: $result');
      return result;
    } catch (e) {
      developer.log('Error during authentication: $e');
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      developer.log('Can check biometrics: $canCheckBiometrics');
      developer.log('Is device supported: $isDeviceSupported');
      developer.log('Available biometrics: $availableBiometrics');

      return canCheckBiometrics && isDeviceSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      developer.log('Error checking biometric availability: $e');
      return false;
    }
  }
} 
