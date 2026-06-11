import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Bubble {
  final String id;
  double x; // 0.0 - 1.0 horizontal position
  double y; // 0.0 (top) - 1.0 (bottom)
  double size;
  Color color;
  double speed; // units per second
  double wobbleOffset;
  double wobbleSpeed;
  bool isPopping = false;
  double popProgress = 0.0; // 0.0 - 1.0

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.wobbleOffset,
    required this.wobbleSpeed,
  });
}

class BubblePopperTab extends StatefulWidget {
  final bool isDark;

  const BubblePopperTab({super.key, required this.isDark});

  @override
  State<BubblePopperTab> createState() => _BubblePopperTabState();
}

class _BubblePopperTabState extends State<BubblePopperTab>
    with SingleTickerProviderStateMixin {
  static const int _maxBubbles = 10;
  static const List<Color> _bubbleColors = [
    Color(0xffb388ff), // Lavender
    Color(0xff80cbc4), // Mint
    Color(0xffffab91), // Peach
    Color(0xff90caf9), // Sky blue
    Color(0xfff48fb1), // Rose
    Color(0xffa5d6a7), // Sage green
    Color(0xffffe082), // Soft gold
    Color(0xffce93d8), // Orchid
  ];

  static const List<String> _mindfulTexts = [
    'Fokuskan pikiran Anda pada setiap gelembung...',
    'Setiap sentuhan membawa kedamaian...',
    'Biarkan gelembung membawa pergi hasrat Anda...',
    'Hiruplah ketenangan, hembuskan kegelisahan...',
    'Anda hadir di sini dan saat ini...',
    'Satu gelembung, satu napas, satu langkah menuju bebas...',
  ];

  final List<_Bubble> _bubbles = [];
  int _score = 0;
  int _currentTextIndex = 0;
  final Random _random = Random();
  late AnimationController _tickController;
  Timer? _textTimer;
  double _elapsedTime = 0;

  @override
  void initState() {
    super.initState();

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _tickController.addListener(_onTick);

    // Spawn initial bubbles
    for (int i = 0; i < _maxBubbles; i++) {
      _bubbles.add(_createBubble(initialSpawn: true));
    }

    // Rotate mindful text
    _textTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _mindfulTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _tickController.removeListener(_onTick);
    _tickController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  _Bubble _createBubble({bool initialSpawn = false}) {
    final size = 40.0 + _random.nextDouble() * 30.0; // 40-70
    return _Bubble(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(99999)}',
      x: 0.08 + _random.nextDouble() * 0.84, // 8% - 92% horizontal
      y: initialSpawn ? (0.2 + _random.nextDouble() * 0.7) : (1.05 + _random.nextDouble() * 0.2),
      size: size,
      color: _bubbleColors[_random.nextInt(_bubbleColors.length)],
      speed: 0.03 + _random.nextDouble() * 0.04, // 0.03 - 0.07 per second
      wobbleOffset: _random.nextDouble() * pi * 2,
      wobbleSpeed: 1.5 + _random.nextDouble() * 2.0,
    );
  }

  DateTime? _lastTick;

  void _onTick() {
    final now = DateTime.now();
    if (_lastTick == null) {
      _lastTick = now;
      return;
    }
    final dt = now.difference(_lastTick!).inMilliseconds / 1000.0;
    _lastTick = now;
    _elapsedTime += dt;

    setState(() {
      // Update bubble positions
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final b = _bubbles[i];

        if (b.isPopping) {
          b.popProgress += dt * 4; // Pop animation ~0.25s
          if (b.popProgress >= 1.0) {
            _bubbles.removeAt(i);
            // Spawn replacement
            if (_bubbles.length < _maxBubbles) {
              _bubbles.add(_createBubble());
            }
          }
          continue;
        }

        // Float upward
        b.y -= b.speed * dt;

        // Gentle wobble
        b.x += sin(_elapsedTime * b.wobbleSpeed + b.wobbleOffset) * 0.001;
        b.x = b.x.clamp(0.05, 0.95);

        // If bubble floated off screen, respawn from bottom
        if (b.y < -0.15) {
          _bubbles[i] = _createBubble();
        }
      }

      // Maintain bubble count
      while (_bubbles.length < _maxBubbles) {
        _bubbles.add(_createBubble());
      }
    });
  }

  void _popBubble(int index) {
    if (_bubbles[index].isPopping) return;
    HapticFeedback.lightImpact();
    setState(() {
      _bubbles[index].isPopping = true;
      _bubbles[index].popProgress = 0.0;
      _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Column(
      children: [
        // Mindful text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Text(
              _mindfulTexts[_currentTextIndex],
              key: ValueKey<int>(_currentTextIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.5,
              ),
            ),
          ),
        ),

        // Score
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🫧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$_score gelembung dipecahkan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Bubble field
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: ClipRect(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _BubblePainter(
                      bubbles: _bubbles,
                      areaWidth: constraints.maxWidth,
                      areaHeight: constraints.maxHeight,
                      isDark: isDark,
                    ),
                    child: Stack(
                      children: List.generate(_bubbles.length, (i) {
                        final b = _bubbles[i];
                        final px = b.x * constraints.maxWidth - b.size / 2;
                        final py = b.y * constraints.maxHeight - b.size / 2;

                        if (b.isPopping) {
                          final scale = 1.0 + b.popProgress * 0.5;
                          final opacity = (1.0 - b.popProgress).clamp(0.0, 1.0);
                          return Positioned(
                            left: px,
                            top: py,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: _buildBubbleWidget(b, isDark),
                              ),
                            ),
                          );
                        }

                        return Positioned(
                          left: px,
                          top: py,
                          child: GestureDetector(
                            onTap: () => _popBubble(i),
                            child: _buildBubbleWidget(b, isDark),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleWidget(_Bubble bubble, bool isDark) {
    return Container(
      width: bubble.size,
      height: bubble.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            bubble.color.withValues(alpha: isDark ? 0.5 : 0.4),
            bubble.color.withValues(alpha: isDark ? 0.2 : 0.15),
            bubble.color.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: bubble.color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bubble.color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      // Shine highlight
      child: Align(
        alignment: const Alignment(-0.35, -0.35),
        child: Container(
          width: bubble.size * 0.25,
          height: bubble.size * 0.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.35),
          ),
        ),
      ),
    );
  }
}

// Simple painter for optional background effects
class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double areaWidth;
  final double areaHeight;
  final bool isDark;

  _BubblePainter({
    required this.bubbles,
    required this.areaWidth,
    required this.areaHeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No additional painting needed — bubbles are rendered as widgets
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}
