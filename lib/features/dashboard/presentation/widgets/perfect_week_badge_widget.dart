import 'package:flutter/material.dart';

/// Widget visualisasi badge premium untuk pencapaian Perfect Week.
/// Mendukung animasi breathing scale jika berhasil diraih,
/// serta rendering abu-abu/terkunci jika belum didapatkan.
class PerfectWeekBadgeWidget extends StatelessWidget {
  final bool hasBadge;
  final int totalCount;

  const PerfectWeekBadgeWidget({
    super.key,
    required this.hasBadge,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1a1d24) : Colors.white;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : Colors.black87;
    final textSecondary = isDark ? const Color(0xff94a3b8) : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasBadge
              ? Colors.amber.withOpacity(0.25)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
        boxShadow: hasBadge
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Visual Medal Badge with Breathing Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.96, end: 1.04),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              final double appliedScale = hasBadge ? scale : 1.0;
              return Transform.scale(
                scale: appliedScale,
                child: child,
              );
            },
            // Loop the breathing animation implicitly by rebuilding when duration ends.
            // Note: Since TweenAnimationBuilder has no built-in auto-reverse repeat,
            // we can make a simple breathing loop widget, or just render it directly.
            // Let's create a custom BreathingLoopWidget for maximum premium feel!
            child: _BreathingBadge(hasBadge: hasBadge),
          ),
          const SizedBox(width: 20),
          
          // Badge Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Perfect Week Badge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hasBadge) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.stars, color: Colors.amber, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasBadge
                      ? 'Selamat! Kamu menyelesaikan semua habit 100% tanpa terputus dalam 7 hari terakhir.'
                      : 'Selesaikan semua habit harian kamu selama 7 hari berturut-turut untuk meraih badge ini!',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Total Perfect Weeks count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasBadge 
                        ? Colors.amber.withOpacity(0.12)
                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        color: hasBadge ? Colors.amber : textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Total Diraih: $totalCount Kali',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasBadge ? Colors.amber : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingBadge extends StatefulWidget {
  final bool hasBadge;
  const _BreathingBadge({required this.hasBadge});

  @override
  State<_BreathingBadge> createState() => _BreathingBadgeState();
}

class _BreathingBadgeState extends State<_BreathingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.hasBadge) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _BreathingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasBadge && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.hasBadge && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeWidget = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.hasBadge
            ? const LinearGradient(
                colors: [Color(0xffffe259), Color(0xffffa751)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: widget.hasBadge
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          widget.hasBadge ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );

    if (widget.hasBadge) {
      return ScaleTransition(
        scale: _animation,
        child: badgeWidget,
      );
    }

    return badgeWidget;
  }
}
