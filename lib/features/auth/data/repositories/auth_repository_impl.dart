import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implementasi konkrit dari [AuthRepository] menggunakan package `google_sign_in` dan `firebase_auth`.
/// Mendukung login Google asli dengan Firebase, bypass simulasi demo, dan default Guest Mode.
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
    // Siarkan status default (Guest atau user aktif) saat pertama kali diinisialisasi
    _initSession();
  }

  Future<void> _initSession() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Pengguna Dailio',
        photoUrl: firebaseUser.photoURL,
        isGuest: false,
      );
      // Restore Google Sign-In session in background so token is ready
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        debugPrint('Dailio Auth: Gagal signInSilently di _initSession: $e');
      }
    }
    _authStreamController.add(_currentUser);
  }

  @override
  Stream<AppUser> get authStateChanges => _authStreamController.stream;

  @override
  Future<Result<AppUser>> getActiveUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Pengguna Dailio',
        photoUrl: firebaseUser.photoURL,
        isGuest: false,
      );
    }
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

      // Ambil detail autentikasi Google
      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Jalankan autentikasi Firebase Auth dengan kredensial Google
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Failure('Gagal mendapatkan sesi autentikasi dari Firebase.');
      }

      final appUser = AppUser(
        id: firebaseUser.uid, // Menggunakan Firebase UID agar sesuai dengan Firestore Rules
        email: firebaseUser.email ?? googleAccount.email,
        displayName: firebaseUser.displayName ?? googleAccount.displayName ?? 'Pengguna Dailio',
        photoUrl: firebaseUser.photoURL ?? googleAccount.photoUrl,
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
      // Sign out dari Firebase Auth SDK jika aktif
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }

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

  @override
  Future<String?> getGoogleAccessToken() async {
    try {
      var googleAccount = _googleSignIn.currentUser;
      if (googleAccount == null) {
        debugPrint('Dailio Auth: currentUser null di getGoogleAccessToken(). Mencoba signInSilently...');
        googleAccount = await _googleSignIn.signInSilently();
      }
      if (googleAccount == null) {
        debugPrint('Dailio Auth: currentUser tetap null setelah signInSilently()');
        return null;
      }
      final googleAuth = await googleAccount.authentication;
      final token = googleAuth.accessToken;
      debugPrint('Dailio Auth: Berhasil mengambil Google Access Token. Panjang: ${token?.length}');
      return token;
    } catch (e) {
      debugPrint('Dailio Auth: Error saat mengambil Google Access Token: $e');
      return null;
    }
  }

  @override
  Future<bool> requestCalendarScope() async {
    try {
      // Pastikan sesi Google Sign-In aktif terlebih dahulu
      var account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('Dailio Auth: requestCalendarScope - currentUser null, mencoba signInSilently...');
        account = await _googleSignIn.signInSilently();
      }
      if (account == null) {
        debugPrint('Dailio Auth: requestCalendarScope - signInSilently gagal, tidak ada sesi Google aktif.');
        return false;
      }

      debugPrint('Dailio Auth: requestCalendarScope - Meminta scope calendar.events...');
      final result = await _googleSignIn.requestScopes([
        'https://www.googleapis.com/auth/calendar.events',
      ]);
      debugPrint('Dailio Auth: requestCalendarScope - Hasil requestScopes: $result');
      return result;
    } catch (e) {
      debugPrint('Dailio Auth: requestCalendarScope - Error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestDriveScope() async {
    try {
      var account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('Dailio Auth: requestDriveScope - currentUser null, mencoba signInSilently...');
        account = await _googleSignIn.signInSilently();
      }
      if (account == null) {
        debugPrint('Dailio Auth: requestDriveScope - signInSilently gagal, tidak ada sesi Google aktif.');
        return false;
      }

      debugPrint('Dailio Auth: requestDriveScope - Meminta scope drive.file...');
      final result = await _googleSignIn.requestScopes([
        'https://www.googleapis.com/auth/drive.file',
      ]);
      debugPrint('Dailio Auth: requestDriveScope - Hasil requestScopes: $result');
      return result;
    } catch (e) {
      debugPrint('Dailio Auth: requestDriveScope - Error: $e');
      return false;
    }
  }
}
