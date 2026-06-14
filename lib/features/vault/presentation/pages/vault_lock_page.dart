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

class _VaultLockPageState extends ConsumerState<VaultLockPage>
    with SingleTickerProviderStateMixin {
  final List<int> _currentInput = [];
  bool _isCreatingPin = false;
  bool _isConfirmingPin = false;
  String _tempPin = '';
  String _errorMessage = '';
  bool _biometricAttempted = false;

  /// true = show biometric full-screen view, false = show PIN numpad
  bool _showBiometricView = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performInitialCheck();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _performInitialCheck() {
    if (!mounted) return;
    final securityState = ref.read(vaultSecurityProvider);

    if (securityState.isUnlocked) {
      context.go('/vault/dashboard');
      return;
    }

    if (!securityState.hasPin) {
      setState(() {
        _isCreatingPin = true;
        _showBiometricView = false;
      });
    } else if (securityState.isBiometricEnabled &&
        securityState.isBiometricSupported) {
      setState(() {
        _showBiometricView = true;
      });
      _tryAutoBiometric(securityState);
    }
  }

  void _tryAutoBiometric(VaultState state) {
    if (_biometricAttempted || _isCreatingPin) return;
    if (state.isUnlocked) return;
    if (state.isBiometricEnabled &&
        state.isBiometricSupported &&
        state.hasPin) {
      _biometricAttempted = true;
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final success =
        await ref.read(vaultSecurityProvider.notifier).authenticateWithBiometrics();
    if (success && mounted) {
      context.go('/vault/dashboard');
    }
  }

  void _switchToPinView() {
    setState(() {
      _showBiometricView = false;
      _errorMessage = '';
      _currentInput.clear();
    });
  }

  void _switchToBiometricView() {
    setState(() {
      _showBiometricView = true;
      _errorMessage = '';
      _currentInput.clear();
      _biometricAttempted = false;
    });
    // Auto-trigger biometric when switching back
    _triggerBiometricAuth();
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
        setState(() {
          _tempPin = inputStr;
          _isConfirmingPin = true;
          _currentInput.clear();
        });
      } else {
        if (inputStr == _tempPin) {
          securityNotifier.setPin(inputStr).then((_) {
            if (mounted) {
              context.go('/vault/dashboard');
            }
          });
        } else {
          setState(() {
            _errorMessage = 'PIN tidak cocok. Silakan coba lagi.';
            _currentInput.clear();
            _isConfirmingPin = false;
            _tempPin = '';
          });
        }
      }
    } else {
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

    ref.listen<VaultState>(vaultSecurityProvider, (previous, next) {
      // Fix race condition: _init() is async, so _performInitialCheck may
      // have wrongly set _isCreatingPin=true because hasPin was still false.
      // When _init finishes and hasPin becomes true, correct the state.
      if (_isCreatingPin && next.hasPin && _currentInput.isEmpty && _tempPin.isEmpty) {
        // _init just finished and user actually HAS a pin — abort create-pin mode
        setState(() {
          _isCreatingPin = false;
          _isConfirmingPin = false;
        });
      }

      if (!_showBiometricView &&
          !_isCreatingPin &&
          next.isBiometricEnabled &&
          next.isBiometricSupported &&
          next.hasPin &&
          !_biometricAttempted) {
        setState(() {
          _showBiometricView = true;
        });
      }
      _tryAutoBiometric(next);
    });

    final bgColor = isDark
        ? const Color(0xff0d0914)
        : const Color(0xfff6f2f8);

    final bool biometricAvailable = securityState.isBiometricEnabled &&
        securityState.isBiometricSupported &&
        securityState.hasPin &&
        !_isCreatingPin;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // If on PIN view and biometric is available, go back to biometric view
        if (!_showBiometricView && biometricAvailable) {
          _switchToBiometricView();
          return;
        }
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
            icon: Icon(Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              // If on PIN view and biometric is available, go back to biometric
              if (!_showBiometricView && biometricAvailable) {
                _switchToBiometricView();
                return;
              }
              Navigator.maybePop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            // Background ambient lights
            _buildBackgroundLights(isDark),
            // Main Content
            if (_showBiometricView && biometricAvailable)
              _buildBiometricView(isDark, theme)
            else
              _buildPinView(isDark, theme, securityState, biometricAvailable),
          ],
        ),
      ),
    );
  }

  // ─── Biometric Full-Screen View ────────────────────────────────────────────

  Widget _buildBiometricView(bool isDark, ThemeData theme) {
    const accentPurple = Color(0xffb39ddb);

    return SafeArea(
      key: const ValueKey('biometric_view'),
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Header at the top
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xff221b2d).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.6),
                      border: Border.all(
                        color: accentPurple.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: accentPurple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ruang Privat',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan sidik jari atau wajah untuk membuka',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // "Gunakan PIN" button — center of the screen
            Center(
              child: TextButton.icon(
                onPressed: _switchToPinView,
                icon: Icon(
                  Icons.dialpad_rounded,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                label: Text(
                  'Gunakan PIN',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),

            // Fingerprint — bottom of screen (typical in-screen sensor position)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _triggerBiometricAuth,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentPurple.withValues(alpha: 0.25),
                              accentPurple.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? accentPurple.withValues(alpha: 0.12)
                                  : accentPurple.withValues(alpha: 0.08),
                              border: Border.all(
                                color: accentPurple.withValues(alpha: 0.35),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 52,
                              color: accentPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ketuk untuk memindai',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PIN Numpad View ───────────────────────────────────────────────────────

  Widget _buildPinView(
      bool isDark, ThemeData theme, VaultState securityState, bool biometricAvailable) {
    const accentPurple = Color(0xffb39ddb);
    final glassColor = isDark
        ? const Color(0xff221b2d).withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);

    String titleText = 'Masukkan PIN Anda';
    if (_isCreatingPin) {
      titleText =
          _isConfirmingPin ? 'Konfirmasi PIN Baru Anda' : 'Buat PIN 4-Digit Baru';
    }

    return SafeArea(
      key: const ValueKey('pin_view'),
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
                color: accentPurple.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isCreatingPin ? Icons.lock_open_rounded : Icons.dialpad_rounded,
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
                      : isDark
                          ? Colors.white12
                          : Colors.black12,
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : accentPurple.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accentPurple.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
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

          // "Gunakan Biometrik" button (only if available and not creating PIN)
          if (biometricAvailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: _switchToBiometricView,
                icon: Icon(
                  Icons.fingerprint_rounded,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                label: Text(
                  'Gunakan Biometrik',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

          // Numpad Container
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
                  _buildNumpadBottomRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────────

  Widget _buildBackgroundLights(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withValues(alpha: 0.15),
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
              color: Colors.deepPurple.withValues(alpha: 0.12),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Numpad Widgets ────────────────────────────────────────────────────────

  Widget _buildNumpadRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((number) => _buildNumpadButton(
                label: number.toString(),
                onTap: () => _onNumberTap(number),
              ))
          .toList(),
    );
  }

  Widget _buildNumpadBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 72, height: 72), // spacing placeholder
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
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
