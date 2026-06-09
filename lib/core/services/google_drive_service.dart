import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Service untuk menangani sinkronisasi file backup Dailio ke Google Drive pribadi pengguna.
class GoogleDriveService {
  final AuthRepository _authRepository;
  final http.Client _client;

  GoogleDriveService({
    required AuthRepository authRepository,
    http.Client? client,
  })  : _authRepository = authRepository,
        _client = client ?? http.Client();

  /// Mencari file backup di Google Drive. Mengembalikan file ID jika ditemukan, null jika tidak.
  Future<String?> _findBackupFileId(String accessToken) async {
    try {
      final query = Uri.encodeComponent("name = 'dailio_backup.json' and trashed = false");
      final url = Uri.parse("https://www.googleapis.com/drive/v3/files?q=$query&spaces=drive");

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        if (files.isNotEmpty) {
          return files.first['id'] as String?;
        }
      } else {
        debugPrint('Google Drive: Gagal mencari berkas. Code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Google Drive: Exception saat mencari berkas: $e');
    }
    return null;
  }

  /// Mengunggah data backup ke Google Drive.
  /// Jika file cadangan sudah ada, isinya akan ditimpa (update). Jika belum ada, file baru dibuat.
  Future<bool> uploadBackup(Map<String, dynamic> backupData) async {
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) {
      debugPrint('Google Drive: Batal upload karena Google access token tidak ditemukan.');
      return false;
    }

    try {
      final fileId = await _findBackupFileId(token);
      final jsonString = jsonEncode(backupData);

      if (fileId != null) {
        // 1. Pembaruan File (PATCH)
        final url = Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media');
        final response = await _client.patch(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonString,
        );

        debugPrint('Google Drive: PATCH response code: ${response.statusCode}');
        return response.statusCode == 200;
      } else {
        // 2. Pembuatan File Baru (POST Multipart)
        final url = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
        const boundary = 'dailio_backup_boundary';
        
        final metadata = jsonEncode({
          'name': 'dailio_backup.json',
          'mimeType': 'application/json',
        });

        // Struktur body multipart manual
        final bodyBuffer = StringBuffer();
        bodyBuffer.write('--$boundary\r\n');
        bodyBuffer.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
        bodyBuffer.write('$metadata\r\n');
        bodyBuffer.write('--$boundary\r\n');
        bodyBuffer.write('Content-Type: application/json\r\n\r\n');
        bodyBuffer.write('$jsonString\r\n');
        bodyBuffer.write('--$boundary--\r\n');

        final response = await _client.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: bodyBuffer.toString(),
        );

        debugPrint('Google Drive: POST response code: ${response.statusCode}');
        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      debugPrint('Google Drive: Exception saat mengunggah cadangan: $e');
      return false;
    }
  }

  /// Mengunduh data cadangan dari Google Drive. Mengembalikan Map JSON jika ada, null jika tidak ada.
  Future<Map<String, dynamic>?> downloadBackup() async {
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) {
      debugPrint('Google Drive: Batal download karena Google access token tidak ditemukan.');
      return null;
    }

    try {
      final fileId = await _findBackupFileId(token);
      if (fileId == null) {
        debugPrint('Google Drive: Tidak ada file dailio_backup.json yang ditemukan.');
        return null;
      }

      final url = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Google Drive: Gagal download berkas. Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google Drive: Exception saat mengunduh cadangan: $e');
    }
    return null;
  }
}
