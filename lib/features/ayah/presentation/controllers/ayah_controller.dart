import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../../core/utils/home_widget_service.dart';
import '../../data/datasources/ayah_local_data_source.dart';
import '../../data/datasources/ayah_remote_data_source.dart';
import '../../data/repositories/ayah_repository_impl.dart';
import '../../data/repositories/tajwid_repository_impl.dart';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../../domain/repositories/tajwid_repository.dart';
import '../../domain/usecases/get_daily_ayah.dart';
import '../../domain/usecases/get_favorite_ayahs.dart';
import '../../domain/usecases/toggle_favorite_ayah.dart';

class AyahState {
  final DailyAyah? todayAyah;
  final List<DailyAyah> favorites;
  final bool isLoading;
  final String errorMessage;
  final bool isAudioPlaying;
  final bool isAudioLoading;

  const AyahState({
    this.todayAyah,
    this.favorites = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.isAudioPlaying = false,
    this.isAudioLoading = false,
  });

  AyahState copyWith({
    DailyAyah? todayAyah,
    List<DailyAyah>? favorites,
    bool? isLoading,
    String? errorMessage,
    bool? isAudioPlaying,
    bool? isAudioLoading,
  }) {
    return AyahState(
      todayAyah: todayAyah ?? this.todayAyah,
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      isAudioLoading: isAudioLoading ?? this.isAudioLoading,
    );
  }
}

// ─── RIVERPOD PROVIDERS ──────────────────────────────────────────────────────

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final ayahLocalDataSourceProvider = Provider<AyahLocalDataSource>((ref) {
  return AyahLocalDataSource(DatabaseHelper.instance);
});

final ayahRemoteDataSourceProvider = Provider<AyahRemoteDataSource>((ref) {
  return AyahRemoteDataSource(ref.read(httpClientProvider));
});

final ayahRepositoryProvider = Provider<AyahRepository>((ref) {
  return AyahRepositoryImpl(
    ref.read(ayahLocalDataSourceProvider),
    ref.read(ayahRemoteDataSourceProvider),
  );
});

final tajwidRepositoryProvider = Provider<TajwidRepository>((ref) {
  return TajwidRepositoryImpl();
});

final getDailyAyahProvider = Provider<GetDailyAyah>((ref) {
  return GetDailyAyah(ref.read(ayahRepositoryProvider));
});

final getFavoriteAyahsProvider = Provider<GetFavoriteAyahs>((ref) {
  return GetFavoriteAyahs(ref.read(ayahRepositoryProvider));
});

final toggleFavoriteAyahProvider = Provider<ToggleFavoriteAyah>((ref) {
  return ToggleFavoriteAyah(ref.read(ayahRepositoryProvider));
});

final ayahControllerProvider = StateNotifierProvider<AyahController, AyahState>((ref) {
  return AyahController(
    ref,
    ref.read(getDailyAyahProvider),
    ref.read(getFavoriteAyahsProvider),
    ref.read(toggleFavoriteAyahProvider),
  );
});

// ─── CONTROLLER CLASS ────────────────────────────────────────────────────────

class AyahController extends StateNotifier<AyahState> {
  final Ref _ref;
  final GetDailyAyah _getDailyAyah;
  final GetFavoriteAyahs _getFavoriteAyahs;
  final ToggleFavoriteAyah _toggleFavoriteAyah;
  late final AudioPlayer _audioPlayer;

  AyahController(
    this._ref,
    this._getDailyAyah,
    this._getFavoriteAyahs,
    this._toggleFavoriteAyah,
  ) : super(const AyahState()) {
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    // Dengarkan status playback audio untuk sinkronisasi state UI
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (mounted) {
        state = state.copyWith(
          isAudioPlaying: playerState == PlayerState.playing,
          isAudioLoading: playerState == PlayerState.completed ? false : state.isAudioLoading,
        );
      }
    });

    await loadTodayAyah();
    await loadFavorites();
  }

  /// Memuat Ayat Hari Ini (cache-first dengan remote fetch & offline fallback)
  Future<void> loadTodayAyah() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    final todayStr = DateFormatter.todayString;

    final result = await _getDailyAyah(todayStr);
    result.fold(
      onSuccess: (ayah) {
        state = state.copyWith(todayAyah: ayah, isLoading: false);
        // Sinkronisasi data ke Home Screen Widget
        final shortTranslation = ayah.translation.length > 55
            ? '${ayah.translation.substring(0, 52)}...'
            : ayah.translation;
        HomeWidgetService.updateAyahData(
          shortTranslation,
          'QS. ${ayah.surahName}:${ayah.ayahNumber}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  /// Memuat seluruh daftar ayat terfavorit
  Future<void> loadFavorites() async {
    final result = await _getFavoriteAyahs(const NoParams());
    result.fold(
      onSuccess: (list) {
        state = state.copyWith(favorites: list);
      },
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  /// Menambah atau menghapus ayat dari koleksi favorit SQLite harian
  Future<void> toggleFavorite(DailyAyah ayah) async {
    final isFav = isFavorited(ayah);
    final params = ToggleFavoriteAyahParams(ayah: ayah, isFavorite: !isFav);

    final result = await _toggleFavoriteAyah(params);
    result.fold(
      onSuccess: (_) async {
        await loadFavorites();
      },
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  /// Mengecek apakah suatu ayat terfavorit
  bool isFavorited(DailyAyah ayah) {
    return state.favorites.any(
      (f) => f.surahNumber == ayah.surahNumber && f.ayahNumber == ayah.ayahNumber,
    );
  }

  // ─── AUDIO PLAYBACK METHODS ────────────────────────────────────────────────

  /// Memutar atau menjeda audio murattal ayat harian
  Future<void> toggleAudioPlayback(String? url) async {
    if (url == null || url.isEmpty) return;

    if (state.isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        state = state.copyWith(isAudioLoading: true);
        await _audioPlayer.play(UrlSource(url));
        state = state.copyWith(isAudioLoading: false, isAudioPlaying: true);
      } catch (e) {
        state = state.copyWith(
          isAudioLoading: false,
          errorMessage: 'Gagal memutar audio: $e',
        );
      }
    }
  }

  /// Menghentikan pemutaran audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    state = state.copyWith(isAudioPlaying: false, isAudioLoading: false);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
