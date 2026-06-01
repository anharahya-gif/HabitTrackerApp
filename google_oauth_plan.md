# 🌿 Integrasi Google OAuth & Sinkronisasi Cloud untuk Dailio

Dokumen ini menjelaskan konsep, langkah teknis, dan rancangan arsitektur untuk mengintegrasikan **Google OAuth (Google Sign-In)** ke dalam aplikasi **Dailio**. buat juga jika tidak ada credentialsnya google aplikasi ini akan bisa berjalan namun tidak bisa login dan sinkronisasi cloud dan hanya terbatas di guest mode(tidak menggunakan akun hanya menggunakan database local).

---

## 🗺️ Peta Jalan & Arsitektur Integrasi

Karena Dailio dirancang sebagai aplikasi **Offline-First**, proses autentikasi sebaiknya dipadukan dengan **Sinkronisasi Cloud**. Pengguna tetap bisa menggunakan aplikasi secara offline (data disimpan di SQLite local), dan begitu login dengan Google, datanya akan disinkronisasikan ke backend cloud.

### Arsitektur Aliran Data (Clean Architecture)
```text
[ UI Layer ]               -->  HabitListPage / LoginPage
     │
[ State Management ]       -->  authProvider (Riverpod Notifier)
     │
[ Domain Layer ]           -->  AuthRepository (Interface) & LoginWithGoogle UseCase
     │
[ Data Layer ]             -->  AuthRepositoryImpl & GoogleSignIn API (Remote Data Source)
```

---

## 🛠️ Langkah 1: Registrasi di Google Cloud Console

Sebelum menulis kode Flutter, Anda perlu mendaftarkan aplikasi Dailio di **[Google Cloud Console](https://console.cloud.google.com/)**:

1.  **Buat Proyek Baru:** Beri nama proyek Anda (misalnya: *Dailio Habit Tracker*).
2.  **Konfigurasi OAuth Consent Screen:**
    *   Pilih tipe user: **External**.
    *   Masukkan informasi dasar aplikasi (Nama: Dailio, email support, logo).
3.  **Buat Kredensial (Credentials):**
    *   Pilih **Create Credentials** > **OAuth client ID**.
    *   **Untuk Android:**
        *   Masukkan nama paket: `com.habittracker.app` (atau nama paket Dailio Anda).
        *   Masukkan **SHA-1 fingerprint** (bisa didapatkan dengan menjalankan perintah `./gradlew signingReport` di folder `android`).
    *   **Untuk iOS:**
        *   Masukkan *Bundle ID* iOS Anda (misalnya: `com.habittracker.app`).
        *   Simpan **iOS Client ID** dan **Reversed Client ID** yang dihasilkan untuk konfigurasi `Info.plist`.

---

## 📦 Langkah 2: Menambahkan Dependensi Flutter

Tambahkan package resmi dari Google ke dalam `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  # Jika ingin dipadukan dengan backend Firebase (Sangat Direkomendasikan)
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.8
```

---

## ⚙️ Langkah 3: Konfigurasi Native Platform

### A. Konfigurasi Android
Biasanya, Google Sign-In langsung bekerja di Android selama SHA-1 sidik jari (*fingerprint*) keystore sudah didaftarkan dengan benar di Google Cloud Console/Firebase Console.

### B. Konfigurasi iOS (`ios/Runner/Info.plist`)
Google OAuth membutuhkan penanganan skema URL khusus agar setelah login di browser Safari, sistem bisa kembali ke aplikasi Dailio. Tambahkan baris berikut di `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<!-- Ganti dengan REVERSED_CLIENT_ID dari iOS Client ID Anda di Google Console -->
			<string>com.googleusercontent.apps.xxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx</string>
		</array>
	</dict>
</array>
```

---

## 📝 Langkah 4: Implementasi Clean Architecture

### 1. Domain Layer (`lib/features/auth/domain/repositories/auth_repository.dart`)
```dart
abstract class AuthRepository {
  Future<Result<UserModel?>> loginWithGoogle();
  Future<Result<void>> logout();
  Stream<UserModel?> get authStateChanges;
}
```

### 2. Data Layer (`lib/features/auth/data/repositories/auth_repository_impl.dart`)
```dart
class AuthRepositoryImpl implements AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<Result<UserModel?>> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return const Failure('Login dibatalkan oleh pengguna.');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Di sini kita bisa membuat objek user lokal, atau meneruskannya ke Firebase Auth
      final user = UserModel(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
      
      return Success(user);
    } catch (e) {
      return Failure('Gagal login dengan Google: $e');
    }
  }
  
  @override
  Future<Result<void>> logout() async {
    await _googleSignIn.signOut();
    return const Success(null);
  }
  
  // ...
}
```

### 3. Presentation Layer (`lib/features/auth/presentation/controllers/auth_controller.dart`)
Menggunakan Riverpod untuk memantau status login secara global:

```dart
final authProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  
  AuthController(this._authRepository) : super(const AsyncValue.data(null));
  
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authRepository.loginWithGoogle();
    result.when(
      success: (user) => state = AsyncValue.data(user),
      failure: (fail) => state = AsyncValue.error(fail.message, StackTrace.current),
    );
  }
}
```

---

## 🌿 Hubungan Antara SQLite Lokal & Database Cloud

Ketika pengguna masuk dengan Google OAuth, Dailio akan memiliki dua opsi penanganan data:
1.  **Anonymous (Offline) First:** Semua data disimpan di SQLite.
2.  **Cloud Sync:** Begitu pengguna login dengan Google, aplikasi akan membaca seluruh tabel SQLite (`habits`, `habit_logs`, `habit_streaks`), lalu melakukan *upload* (sinkronisasi) data tersebut ke server cloud (misalnya Firestore atau database Supabase).
3.  Ini memastikan pengguna **tidak pernah kehilangan data mereka** jika berganti HP, dan aplikasi tetap berjalan sangat cepat karena pembacaan data harian tetap langsung ke SQLite lokal!
