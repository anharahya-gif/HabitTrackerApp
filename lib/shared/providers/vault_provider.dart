import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers.dart';

class VaultState {
  final bool isUnlocked;
  final bool hasPin;
  final bool isBiometricEnabled;
  final bool isBiometricSupported;

  VaultState({
    this.isUnlocked = false,
    this.hasPin = false,
    this.isBiometricEnabled = false,
    this.isBiometricSupported = false,
  });

  VaultState copyWith({
    bool? isUnlocked,
    bool? hasPin,
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      hasPin: hasPin ?? this.hasPin,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
    );
  }
}

class VaultSecurityNotifier extends StateNotifier<VaultState> {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  VaultSecurityNotifier(this._prefs) : super(VaultState()) {
    _init();
  }

  Future<void> _init() async {
    final hasPin = _prefs.containsKey('vault_pin_hash');
    final isBiometricEnabled = _prefs.getBool('vault_biometric_enabled') ?? false;

    bool isBiometricSupported = false;
    try {
      isBiometricSupported = await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
    } catch (_) {}

    state = VaultState(
      isUnlocked: false,
      hasPin: hasPin,
      isBiometricEnabled: isBiometricEnabled,
      isBiometricSupported: isBiometricSupported,
    );
  }

  String _simpleHash(String pin) {
    const salt = 'dailio_vault_salt_129837';
    final bytes = utf8.encode(pin + salt);
    int hash = 2166136261;
    for (var byte in bytes) {
      hash ^= byte;
      hash *= 16777619;
    }
    return hash.toUnsigned(32).toString();
  }

  Future<void> setPin(String pin) async {
    final hash = _simpleHash(pin);
    await _prefs.setString('vault_pin_hash', hash);
    state = state.copyWith(hasPin: true, isUnlocked: true);
  }

  bool verifyPin(String pin) {
    final storedHash = _prefs.getString('vault_pin_hash');
    if (storedHash == null) return false;

    final hash = _simpleHash(pin);
    if (storedHash == hash) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    return false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool('vault_biometric_enabled', enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!state.isBiometricSupported || !state.isBiometricEnabled) return false;
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah Anda untuk membuka Ruang Privat',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        state = state.copyWith(isUnlocked: true);
        return true;
      }
    } catch (e) {
      debugPrint('Gagal autentikasi biometrik: $e');
    }
    return false;
  }

  void lock() {
    state = state.copyWith(isUnlocked: false);
  }

  Future<void> clearVaultSecurity() async {
    await _prefs.remove('vault_pin_hash');
    await _prefs.remove('vault_biometric_enabled');
    state = state.copyWith(hasPin: false, isUnlocked: false, isBiometricEnabled: false);
  }
}

final vaultSecurityProvider = StateNotifierProvider<VaultSecurityNotifier, VaultState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VaultSecurityNotifier(prefs);
});
