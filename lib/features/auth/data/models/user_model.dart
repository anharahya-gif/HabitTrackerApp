import '../../domain/entities/app_user.dart';

/// Model data Pengguna di Data Layer yang menangani serialization/deserialization JSON.
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.isGuest,
  });

  /// Factory untuk membuat model dari objek Entitas Domain murni
  factory UserModel.fromEntity(AppUser entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isGuest: entity.isGuest,
    );
  }

  /// Membuat Map/JSON untuk penyimpanan lokal (Shared Preferences / SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_guest': isGuest ? 1 : 0,
    };
  }

  /// Membaca model data dari Map/JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      isGuest: (json['is_guest'] as int? ?? 1) == 1,
    );
  }
}
