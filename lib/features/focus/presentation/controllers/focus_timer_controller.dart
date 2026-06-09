import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';

class FocusTimerState {
  final bool isRunning;
  final bool isPaused;
  final int remainingSeconds;
  final int totalSeconds;
  final String? habitId;
  final String? habitName;

  const FocusTimerState({
    required this.isRunning,
    required this.isPaused,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.habitId,
    this.habitName,
  });

  factory FocusTimerState.initial() {
    return const FocusTimerState(
      isRunning: false,
      isPaused: false,
      remainingSeconds: 1500, // 25 minutes default
      totalSeconds: 1500,
      habitId: null,
      habitName: null,
    );
  }

  FocusTimerState copyWith({
    bool? isRunning,
    bool? isPaused,
    int? remainingSeconds,
    int? totalSeconds,
    String? habitId,
    String? habitName,
  }) {
    return FocusTimerState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
    );
  }
}

class FocusTimerController extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  Timer? _timer;

  FocusTimerController(this._ref) : super(FocusTimerState.initial());

  void setDuration(int minutes) {
    final seconds = minutes * 60;
    state = state.copyWith(
      remainingSeconds: seconds,
      totalSeconds: seconds,
    );
  }

  void startTimer({int? durationMinutes, String? habitId, String? habitName}) {
    _timer?.cancel();
    
    int totalSecs = state.totalSeconds;
    if (durationMinutes != null) {
      totalSecs = durationMinutes * 60;
    }

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      remainingSeconds: durationMinutes != null ? totalSecs : state.remainingSeconds,
      totalSeconds: totalSecs,
      habitId: habitId,
      habitName: habitName,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    if (state.isRunning && !state.isPaused) {
      _timer?.cancel();
      state = state.copyWith(isPaused: true);
    }
  }

  void resumeTimer() {
    if (state.isRunning && state.isPaused) {
      state = state.copyWith(isPaused: false);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.remainingSeconds > 0) {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void stopTimer() {
    _timer?.cancel();
    state = FocusTimerState.initial();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    final completedSeconds = state.totalSeconds;
    final completedMinutes = completedSeconds ~/ 60;
    final habitId = state.habitId;

    // Reset timer state
    state = FocusTimerState.initial();

    // Save statistics
    await _ref.read(focusStatsProvider.notifier).recordFocusSession(completedMinutes);

    // If linked to a habit, auto-complete it
    if (habitId != null) {
      final todayStr = DateFormatter.todayString;
      await _ref.read(trackingProvider.notifier).trackHabit(
        habitId: habitId,
        date: todayStr,
        status: 'done',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class FocusStatsState {
  final int totalMinutesToday;
  final int totalMinutesWeek;
  final int totalSessions;

  const FocusStatsState({
    required this.totalMinutesToday,
    required this.totalMinutesWeek,
    required this.totalSessions,
  });

  factory FocusStatsState.initial() {
    return const FocusStatsState(
      totalMinutesToday: 0,
      totalMinutesWeek: 0,
      totalSessions: 0,
    );
  }

  FocusStatsState copyWith({
    int? totalMinutesToday,
    int? totalMinutesWeek,
    int? totalSessions,
  }) {
    return FocusStatsState(
      totalMinutesToday: totalMinutesToday ?? this.totalMinutesToday,
      totalMinutesWeek: totalMinutesWeek ?? this.totalMinutesWeek,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}

class FocusStatsController extends StateNotifier<FocusStatsState> {
  FocusStatsController() : super(FocusStatsState.initial()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormatter.todayString;
    final lastActiveDate = prefs.getString('focus_last_active_date') ?? '';

    int minutesToday = prefs.getInt('focus_minutes_today') ?? 0;
    int minutesWeek = prefs.getInt('focus_minutes_week') ?? 0;
    int sessions = prefs.getInt('focus_sessions') ?? 0;

    // Reset daily minutes if it's a new day
    if (lastActiveDate != today) {
      minutesToday = 0;
      await prefs.setString('focus_last_active_date', today);
      await prefs.setInt('focus_minutes_today', 0);
      
      // Reset weekly stats if it is Monday (start of week)
      final now = DateTime.now();
      if (now.weekday == DateTime.monday) {
        minutesWeek = 0;
        await prefs.setInt('focus_minutes_week', 0);
      }
    }

    state = FocusStatsState(
      totalMinutesToday: minutesToday,
      totalMinutesWeek: minutesWeek,
      totalSessions: sessions,
    );
  }

  Future<void> recordFocusSession(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormatter.todayString;

    final updatedToday = state.totalMinutesToday + minutes;
    final updatedWeek = state.totalMinutesWeek + minutes;
    final updatedSessions = state.totalSessions + 1;

    await prefs.setString('focus_last_active_date', today);
    await prefs.setInt('focus_minutes_today', updatedToday);
    await prefs.setInt('focus_minutes_week', updatedWeek);
    await prefs.setInt('focus_sessions', updatedSessions);

    state = FocusStatsState(
      totalMinutesToday: updatedToday,
      totalMinutesWeek: updatedWeek,
      totalSessions: updatedSessions,
    );
  }
}

final focusTimerProvider = StateNotifierProvider<FocusTimerController, FocusTimerState>((ref) {
  return FocusTimerController(ref);
});

final focusStatsProvider = StateNotifierProvider<FocusStatsController, FocusStatsState>((ref) {
  return FocusStatsController();
});
