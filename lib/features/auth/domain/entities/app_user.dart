/// Entitas bisnis murni untuk merepresentasikan Pengguna di Dailio.
/// Mendukung mode terautentikasi (Google OAuth) maupun Guest Mode (SQLite lokal murni).
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isGuest; // true jika menggunakan mode lokal tanpa login akun

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isGuest,
  });

  /// Akun dummy default untuk merepresentasikan Guest Mode
  static const AppUser guest = AppUser(
    id: 'guest_user',
    email: 'guest@dailio.local',
    displayName: 'Tamu Dailio (Lokal)',
    photoUrl: null,
    isGuest: true,
  );

  /// Akun simulasi untuk Demo Bypass Mode
  static const AppUser demo = AppUser(
    id: 'demo_user_google_123',
    email: 'pejuang.konsistensi@gmail.com',
    displayName: 'Anhar Ahya (Demo)',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    isGuest: false,
  );

  /// Memeriksa apakah ini akun Google terautentikasi nyata/demo
  bool get isAuthenticated => !isGuest;
}
