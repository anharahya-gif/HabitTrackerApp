import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class MoodSelectorWidget extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  const MoodSelectorWidget({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  static const List<Map<String, String>> _moods = [
    {'value': 'great', 'emoji': '😊', 'label': 'Sangat Baik', 'color': '0xff4ade80'}, // green
    {'value': 'good', 'emoji': '🙂', 'label': 'Baik', 'color': '0xff60a5fa'},       // blue
    {'value': 'neutral', 'emoji': '😐', 'label': 'Netral', 'color': '0xfffbbf24'},    // amber
    {'value': 'bad', 'emoji': '😔', 'label': 'Buruk', 'color': '0xfffb7185'},      // rose
    {'value': 'terrible', 'emoji': '😢', 'label': 'Sangat Buruk', 'color': '0xfff43f5e'}, // red
  ];

  Color _parseColor(String hex) {
    return Color(int.parse(hex));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _moods.map((mood) {
        final isSelected = selectedMood == mood['value'];
        final moodColor = _parseColor(mood['color']!);

        return GestureDetector(
          onTap: () => onMoodSelected(mood['value']!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? moodColor.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
                  border: Border.all(
                    color: isSelected
                        ? moodColor
                        : Colors.transparent,
                    width: 2.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: moodColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  mood['emoji']!,
                  style: TextStyle(
                    fontSize: isSelected ? 32 : 26,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mood['label']!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : moodColor)
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
