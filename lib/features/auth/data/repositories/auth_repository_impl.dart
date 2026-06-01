import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implementasi konkrit dari [AuthRepository] menggunakan package `google_sign_in`.
/// Mendukung login Google, bypass simulasi demo, dan default Guest Mode.
class AuthRepositoryImpl implements AuthRepository {
  final GoogleSignIn _googleSignIn;
  
  // StreamController untuk menyiarkan perubahan status reaktif pengguna
  final StreamController<AppUser> _authStreamController = StreamController<AppUser>.broadcast();
  
  // Cache user aktif dalam memori saat runtime
  AppUser _currentUser = AppUser.guest;

  AuthRepositoryImpl({GoogleSignIn? googleSignIn}) 
      : _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: [
            'email',
            'profile',
          ],
        ) {
    // Siarkan status default (Guest) saat pertama kali diinisialisasi
    _authStreamController.add(_currentUser);
  }

  @override
  Stream<AppUser> get authStateChanges => _authStreamController.stream;

  @override
  Future<Result<AppUser>> getActiveUser() async {
    return Success(_currentUser);
  }

  @override
  Future<Result<AppUser>> loginWithGoogle({bool useDemoBypass = false}) async {
    if (useDemoBypass) {
      // 1. Bypass Simulasi: Langsung masuk menggunakan Akun Demo Premium
      _currentUser = AppUser.demo;
      _authStreamController.add(_currentUser);
      return Success(_currentUser);
    }

    try {
      // 2. Autentikasi Google Asli
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const Failure('Proses masuk dibatalkan oleh pengguna.');
      }

      final appUser = AppUser(
        id: googleAccount.id,
        email: googleAccount.email,
        displayName: googleAccount.displayName ?? 'Pengguna Dailio',
        photoUrl: googleAccount.photoUrl,
        isGuest: false,
      );

      _currentUser = appUser;
      _authStreamController.add(_currentUser);
      return Success(_currentUser);
    } catch (e) {
      // Menangkap error API Google (misalnya PlatformException API 10 / developer error karena SHA-1 belum terdaftar)
      // Kita kembalikan error spesifik agar UI bisa menyarankan Demo Bypass secara anggun.
      return Failure(
        'Gagal terhubung dengan layanan Google. Kredensial (SHA-1) mungkin belum terdaftar di Google Cloud Console.\n\nError: $e'
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Sign out dari Google SDK jika sedang terhubung
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Abaikan jika gagal sign out Google, tetap kembalikan user ke Guest Mode lokal
    }

    // Kembalikan status aktif ke Guest Mode
    _currentUser = AppUser.guest;
    _authStreamController.add(_currentUser);
    return const Success(null);
  }
}
