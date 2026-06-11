import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/vault_provider.dart';

class VaultLockPage extends ConsumerStatefulWidget {
  const VaultLockPage({super.key});

  @override
  ConsumerState<VaultLockPage> createState() => _VaultLockPageState();
}

class _VaultLockPageState extends ConsumerState<VaultLockPage> {
  final List<int> _currentInput = [];
  bool _isCreatingPin = false;
  bool _isConfirmingPin = false;
  String _tempPin = '';
  String _errorMessage = '';
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performInitialCheck();
    });
  }

  void _performInitialCheck() {
    if (!mounted) return;
    final securityState = ref.read(vaultSecurityProvider);

    // If already unlocked, go straight to dashboard
    if (securityState.isUnlocked) {
      context.go('/vault/dashboard');
      return;
    }

    if (!securityState.hasPin) {
      setState(() {
        _isCreatingPin = true;
      });
    } else {
      // Try biometric immediately if state is already ready
      _tryAutoBiometric(securityState);
    }
  }

  /// Attempts biometric auth automatically if enabled and not yet attempted.
  /// Called both from initState and when the provider state updates (to handle
  /// the async _init() race condition in VaultSecurityNotifier).
  void _tryAutoBiometric(VaultState state) {
    if (_biometricAttempted || _isCreatingPin) return;
    if (state.isUnlocked) return;
    if (state.isBiometricEnabled && state.isBiometricSupported && state.hasPin) {
      _biometricAttempted = true;
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final success = await ref.read(vaultSecurityProvider.notifier).authenticateWithBiometrics();
    if (success && mounted) {
      context.go('/vault/dashboard');
    }
  }

  void _onNumberTap(int number) {
    if (_currentInput.length >= 4) return;
    
    setState(() {
      _currentInput.add(number);
      _errorMessage = '';
    });

    if (_currentInput.length == 4) {
      _handleFullInput();
    }
  }

  void _onBackspaceTap() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _currentInput.removeLast();
    });
  }

  void _handleFullInput() {
    final inputStr = _currentInput.map((e) => e.toString()).join();
    final securityNotifier = ref.read(vaultSecurityProvider.notifier);

    if (_isCreatingPin) {
      if (!_isConfirmingPin) {
        // Step 1: Entered first PIN
        setState(() {
          _tempPin = inputStr;
          _isConfirmingPin = true;
          _currentInput.clear();
        });
      } else {
        // Step 2: Confirming PIN
        if (inputStr == _tempPin) {
          // Success! Save PIN
          securityNotifier.setPin(inputStr).then((_) {
            if (mounted) {
              context.go('/vault/dashboard');
            }
          });
        } else {
          // PIN mismatch
          setState(() {
            _errorMessage = 'PIN tidak cocok. Silakan coba lagi.';
            _currentInput.clear();
            _isConfirmingPin = false;
            _tempPin = '';
          });
        }
      }
    } else {
      // Normal Unlock
      final success = securityNotifier.verifyPin(inputStr);
      if (success) {
        context.go('/vault/dashboard');
      } else {
        setState(() {
          _errorMessage = 'PIN Salah!';
          _currentInput.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(vaultSecurityProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for state changes to catch when async _init() completes
    // and biometric support info becomes available
    ref.listen<VaultState>(vaultSecurityProvider, (previous, next) {
      _tryAutoBiometric(next);
    });

    // Deep lavender/amethyst palette for lock screen
    final bgColor = isDark 
        ? const Color(0xff0d0914) // very dark amethyst purple
        : const Color(0xfff6f2f8);
    final glassColor = isDark 
        ? const Color(0xff221b2d).withOpacity(0.4) 
        : Colors.white.withOpacity(0.6);
    final accentPurple = const Color(0xffb39ddb); // Soft lavender

    String titleText = 'Masukkan PIN Anda';
    if (_isCreatingPin) {
      titleText = _isConfirmingPin ? 'Konfirmasi PIN Baru Anda' : 'Buat PIN 4-Digit Baru';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      body: Stack(
        children: [
          // Background ambient lights
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: glassColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentPurple.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isCreatingPin ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: accentPurple,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Heading
                Text(
                  titleText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isCreatingPin 
                      ? 'PIN ini digunakan untuk melindungi data sensitif Anda'
                      : 'Data Anda dienkripsi secara lokal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = _currentInput.length > index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive 
                            ? accentPurple 
                            : isDark ? Colors.white12 : Colors.black12,
                        border: Border.all(
                          color: isActive ? Colors.transparent : accentPurple.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : [],
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 16),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const SizedBox(height: 20),
                
                const Spacer(),
                
                // Numpad Container (Glassmorphic look)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Container(
                    color: glassColor,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: Column(
                      children: [
                        _buildNumpadRow([1, 2, 3]),
                        const SizedBox(height: 16),
                        _buildNumpadRow([4, 5, 6]),
                        const SizedBox(height: 16),
                        _buildNumpadRow([7, 8, 9]),
                        const SizedBox(height: 16),
                        _buildNumpadBottomRow(securityState),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildNumpadRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumpadButton(
        label: number.toString(),
        onTap: () => _onNumberTap(number),
      )).toList(),
    );
  }

  Widget _buildNumpadBottomRow(VaultState securityState) {
    Widget leftButton;
    // Show biometric button only if enabled, supported and not creating a PIN
    if (securityState.isBiometricSupported && securityState.isBiometricEnabled && !_isCreatingPin) {
      leftButton = _buildNumpadIconButton(
        icon: Icons.fingerprint_rounded,
        onTap: _triggerBiometricAuth,
      );
    } else {
      leftButton = const SizedBox(width: 72, height: 72); // spacing placeholder
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        leftButton,
        _buildNumpadButton(
          label: '0',
          onTap: () => _onNumberTap(0),
        ),
        _buildNumpadIconButton(
          icon: Icons.backspace_outlined,
          onTap: _onBackspaceTap,
        ),
      ],
    );
  }

  Widget _buildNumpadButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 1,
            ),
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 1,
            ),
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          ),
          child: Icon(
            icon,
            size: 26,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
