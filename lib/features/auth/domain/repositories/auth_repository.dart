import '../../../../core/errors/failure.dart';
import '../entities/app_user.dart';

/// Kontrak repositori untuk mengelola Autentikasi Pengguna di Domain Layer.
abstract class AuthRepository {
  /// Proses masuk menggunakan akun Google.
  /// Jika [useDemoBypass] bernilai true, sistem akan langsung masuk menggunakan
  /// akun simulasi demo tanpa memicu verifikasi Google Cloud SDK asli.
  Future<Result<AppUser>> loginWithGoogle({bool useDemoBypass = false});

  /// Proses keluar akun.
  /// Mengembalikan pengguna ke status [AppUser.guest] (Guest Mode lokal).
  Future<Result<void>> logout();

  /// Mengambil data pengguna aktif yang tersimpan saat ini.
  Future<Result<AppUser>> getActiveUser();

  /// Aliran data reaktif yang memancarkan perubahan status login secara real-time.
  Stream<AppUser> get authStateChanges;

  /// Mendapatkan Access Token Google OAuth untuk keperluan integrasi API pihak ketiga (misalnya Google Calendar).
  Future<String?> getGoogleAccessToken();

  /// Meminta izin scope Google Calendar secara bertahap (incremental authorization).
  Future<bool> requestCalendarScope();

  /// Meminta izin scope Google Drive secara bertahap untuk melakukan backup data.
  Future<bool> requestDriveScope();
}
