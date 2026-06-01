import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider singleton untuk repositori autentikasi
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// StreamProvider reaktif yang menyiarkan perubahan status pengguna secara global.
/// Sangat berguna untuk mengubah UI secara instan saat user masuk/keluar.
final authStateProvider = StreamProvider<AppUser>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Controller StateNotifier untuk memproses status login/logout pengguna beserta loading state.
class AuthController extends StateNotifier<AsyncValue<AppUser>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(AppUser.guest)) {
    _fetchActiveUser();
  }

  /// Mengambil data pengguna aktif saat inisialisasi controller
  Future<void> _fetchActiveUser() async {
    final activeRes = await _authRepository.getActiveUser();
    activeRes.fold(
      onSuccess: (user) => state = AsyncValue.data(user),
      onFailure: (_) => state = const AsyncValue.data(AppUser.guest),
    );
  }

  /// Memicu alur masuk menggunakan akun Google
  Future<void> signInWithGoogle({bool useDemoBypass = false}) async {
    state = const AsyncValue.loading();
    final res = await _authRepository.loginWithGoogle(useDemoBypass: useDemoBypass);
    
    res.fold(
      onSuccess: (user) {
        state = AsyncValue.data(user);
      },
      onFailure: (fail) {
        state = AsyncValue.error(fail.message, StackTrace.current);
      },
    );
  }

  /// Memicu alur keluar akun
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final res = await _authRepository.logout();
    
    res.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(AppUser.guest);
      },
      onFailure: (fail) {
        state = AsyncValue.error(fail.message, StackTrace.current);
      },
    );
  }
}

/// Provider global untuk memicu aksi autentikasi dari UI layer
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
