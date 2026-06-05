import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';

/// Service untuk melakukan sinkronisasi Habit dan Task ke Google Calendar via REST API.
class GoogleCalendarService {
  final AuthRepository _authRepository;
  final http.Client _client;

  GoogleCalendarService({
    required AuthRepository authRepository,
    http.Client? client,
  })  : _authRepository = authRepository,
        _client = client ?? http.Client();

  static const _baseUrl = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  Future<Map<String, String>> _headers(String accessToken) async {
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Mengambil daftar event Dailio di Google Calendar (dengan paginasi)
  Future<Map<String, List<Map<String, String>>>> _fetchDailioEvents() async {
    debugPrint('Google Calendar Sync: _fetchDailioEvents() dipicu.');
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) {
      debugPrint('Google Calendar Sync: Sesi Google tidak ditemukan / Token null.');
      return {'tasks': [], 'habits': []};
    }

    try {
      final List<Map<String, String>> taskEvents = [];
      final List<Map<String, String>> habitEvents = [];
      final taskRegExp = RegExp(r'\[Dailio Task ID:\s*([a-zA-Z0-9\-]+)\]');
      final habitRegExp = RegExp(r'\[Dailio Habit ID:\s*([a-zA-Z0-9\-]+)\]');

      String? pageToken;
      int pageCount = 0;

      do {
        pageCount++;
        var urlStr = '$_baseUrl?q=Dailio&maxResults=250';
        if (pageToken != null) urlStr += '&pageToken=$pageToken';
        final url = Uri.parse(urlStr);
        
        debugPrint('Google Calendar Sync: GET request halaman $pageCount ke $url');
        final response = await _client.get(url, headers: await _headers(token));
        debugPrint('Google Calendar Sync: GET response code: ${response.statusCode}');

        if (response.statusCode != 200) {
          debugPrint('Google Calendar Sync: GET request gagal. Body: ${response.body}');
          throw Exception('Gagal memuat event Google Calendar (${response.statusCode}): ${response.body}');
        }

        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        pageToken = data['nextPageToken'] as String?;

        for (final item in items) {
          final description = item['description'] as String? ?? '';
          final eventId = item['id'] as String? ?? '';
          if (eventId.isEmpty) continue;

          final taskMatch = taskRegExp.firstMatch(description);
          if (taskMatch != null) {
            final taskId = taskMatch.group(1)!;
            taskEvents.add({'taskId': taskId, 'eventId': eventId});
            continue;
          }

          final habitMatch = habitRegExp.firstMatch(description);
          if (habitMatch != null) {
            final habitId = habitMatch.group(1)!;
            habitEvents.add({'habitId': habitId, 'eventId': eventId});
          }
        }
      } while (pageToken != null && pageCount < 20); // Max 20 halaman (5000 event)

      debugPrint('Google Calendar Sync: Total terurai ${taskEvents.length} task events dan ${habitEvents.length} habit events dari $pageCount halaman.');
      return {'tasks': taskEvents, 'habits': habitEvents};
    } catch (e) {
      debugPrint('Google Calendar Sync: Terjadi kesalahan saat membaca event: $e');
      rethrow;
    }
  }

  /// Menghapus event berdasarkan eventId Google Calendar
  Future<bool> _deleteEvent(String eventId) async {
    debugPrint('Google Calendar Sync: _deleteEvent() dipicu untuk eventId: $eventId');
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) return false;

    try {
      final url = Uri.parse('$_baseUrl/$eventId');
      debugPrint('Google Calendar Sync: DELETE request ke $url');
      final response = await _client.delete(url, headers: await _headers(token));
      debugPrint('Google Calendar Sync: DELETE response code: ${response.statusCode}');
      return response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 410;
    } catch (e) {
      debugPrint('Google Calendar Sync: Gagal menghapus event $eventId: $e');
      return false;
    }
  }

  /// Menghapus SEMUA event Dailio dari Google Calendar
  /// Dipanggil ketika user menonaktifkan sinkronisasi
  Future<int> deleteAllDailioEvents() async {
    debugPrint('Google Calendar Sync: deleteAllDailioEvents() dipicu.');
    try {
      final existingEvents = await _fetchDailioEvents();
      final allEvents = [
        ...existingEvents['tasks'] ?? [],
        ...existingEvents['habits'] ?? [],
      ];

      if (allEvents.isEmpty) {
        debugPrint('Google Calendar Sync: Tidak ada event Dailio yang perlu dihapus.');
        return 0;
      }

      debugPrint('Google Calendar Sync: Menghapus ${allEvents.length} event Dailio...');
      int deleted = 0;
      for (final event in allEvents) {
        final eventId = event['eventId'] ?? event['taskId'] ?? '';
        if (eventId.isNotEmpty) {
          final success = await _deleteEvent(eventId);
          if (success) deleted++;
        }
      }
      debugPrint('Google Calendar Sync: Berhasil menghapus $deleted/${allEvents.length} event.');
      return deleted;
    } catch (e) {
      debugPrint('Google Calendar Sync: Error saat menghapus semua event: $e');
      return 0;
    }
  }

  /// Menghitung format waktu start/end untuk Google Calendar API
  Map<String, dynamic> _formatEventTime(DateTime date, {String? startTimeStr, String? endTimeStr}) {
    if (startTimeStr == null) {
      // Jika tidak ada spesifikasi waktu, gunakan all-day event
      final yyyymmdd = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return {
        'start': {'date': yyyymmdd},
        'end': {'date': yyyymmdd},
      };
    }

    // Jika waktu ditentukan, hitung rentang jamnya
    try {
      final startParts = startTimeStr.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);

      final startDateTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
      
      DateTime endDateTime;
      if (endTimeStr != null) {
        final endParts = endTimeStr.split(':');
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);
        endDateTime = DateTime(date.year, date.month, date.day, endHour, endMinute);
      } else {
        endDateTime = startDateTime.add(const Duration(minutes: 30));
      }

      return {
        'start': {'dateTime': startDateTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
        'end': {'dateTime': endDateTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      };
    } catch (_) {
      final yyyymmdd = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return {
        'start': {'date': yyyymmdd},
        'end': {'date': yyyymmdd},
      };
    }
  }

  /// Sinkronisasi Tugas (Tasks) ke Google Calendar
  Future<void> syncTasks(List<Task> tasks) async {
    debugPrint('Google Calendar Sync: syncTasks() dipicu untuk ${tasks.length} tugas.');
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) {
      debugPrint('Google Calendar Sync: syncTasks batal karena token null.');
      return;
    }

    final dailioEvents = await _fetchDailioEvents();
    final taskEvents = dailioEvents['tasks'] ?? [];

    final Map<String, String> taskIdToEventId = {};
    for (final ev in taskEvents) {
      if (ev['taskId'] != null && ev['eventId'] != null) {
        taskIdToEventId[ev['taskId']!] = ev['eventId']!;
      }
    }

    final activeTaskIds = tasks.map((t) => t.id).toSet();

    // Hapus event yang secara lokal sudah tidak ada (orphaned)
    for (final ev in taskEvents) {
      final taskId = ev['taskId'];
      final eventId = ev['eventId'];
      if (taskId != null && eventId != null && !activeTaskIds.contains(taskId)) {
        debugPrint('Google Calendar Sync: Menghapus event yatim (task telah dihapus) eventId: $eventId');
        await _deleteEvent(eventId);
      }
    }

    // Sync task aktif
    for (final task in tasks) {
      if (task.dueDate == null) {
        // Jika tidak memiliki tenggat waktu, pastikan terhapus di calendar
        final existingEventId = taskIdToEventId[task.id];
        if (existingEventId != null) {
          debugPrint('Google Calendar Sync: Menghapus event task "${task.title}" karena tidak memiliki tenggat waktu lagi.');
          await _deleteEvent(existingEventId);
        }
        continue;
      }

      final title = task.isCompleted ? '✅ [Selesai] ${task.title}' : task.title;
      final description = '${task.description ?? ""}\n\nPrioritas: ${task.priority.toUpperCase()}\nKategori: ${task.category}\n\n[Dailio Task ID: ${task.id}]';
      final times = _formatEventTime(task.dueDate!);

      final body = {
        'summary': title,
        'description': description,
        ...times,
      };

      final existingEventId = taskIdToEventId[task.id];
      try {
        if (existingEventId != null) {
          // Update event
          final url = Uri.parse('$_baseUrl/$existingEventId');
          debugPrint('Google Calendar Sync: Memperbarui event task: $url dengan judul: "$title"');
          final response = await _client.put(url, headers: await _headers(token), body: jsonEncode(body));
          debugPrint('Google Calendar Sync: PUT response code: ${response.statusCode}');
          if (response.statusCode != 200) {
            throw Exception('Gagal mengubah event tugas di Google Calendar (${response.statusCode}): ${response.body}');
          }
        } else if (!task.isCompleted) {
          // Hanya buat event baru jika belum selesai
          final url = Uri.parse(_baseUrl);
          debugPrint('Google Calendar Sync: Membuat event task baru ke: $url dengan judul: "$title"');
          final response = await _client.post(url, headers: await _headers(token), body: jsonEncode(body));
          debugPrint('Google Calendar Sync: POST response code: ${response.statusCode}');
          if (response.statusCode != 200 && response.statusCode != 201) {
            throw Exception('Gagal membuat event tugas di Google Calendar (${response.statusCode}): ${response.body}');
          }
        }
      } catch (e) {
        debugPrint('Google Calendar Sync: Exception di syncTasks untuk task ${task.id}: $e');
        rethrow;
      }
    }
    debugPrint('Google Calendar Sync: syncTasks() selesai.');
  }

  /// Sinkronisasi Kebiasaan (Habits) ke Google Calendar
  Future<void> syncHabits(List<Habit> habits) async {
    debugPrint('Google Calendar Sync: syncHabits() dipicu untuk ${habits.length} kebiasaan.');
    final token = await _authRepository.getGoogleAccessToken();
    if (token == null) {
      debugPrint('Google Calendar Sync: syncHabits batal karena token null.');
      return;
    }

    final dailioEvents = await _fetchDailioEvents();
    final habitEvents = dailioEvents['habits'] ?? [];

    final Map<String, String> habitIdToEventId = {};
    for (final ev in habitEvents) {
      if (ev['habitId'] != null && ev['eventId'] != null) {
        habitIdToEventId[ev['habitId']!] = ev['eventId']!;
      }
    }

    final activeHabitIds = habits.where((h) => !h.isArchived).map((h) => h.id).toSet();

    // Hapus event yang secara lokal sudah diarsipkan atau dihapus
    for (final ev in habitEvents) {
      final habitId = ev['habitId'];
      final eventId = ev['eventId'];
      if (habitId != null && eventId != null && !activeHabitIds.contains(habitId)) {
        debugPrint('Google Calendar Sync: Menghapus event yatim (habit telah diarsipkan/dihapus) eventId: $eventId');
        await _deleteEvent(eventId);
      }
    }

    // Sync habit aktif
    for (final habit in habits) {
      if (habit.isArchived) continue;

      final title = '🌿 Kebiasaan: ${habit.name}';
      final description = '${habit.description ?? ""}\n\nKategori: ${habit.category}\nTipe: ${habit.type}\n\n[Dailio Habit ID: ${habit.id}]';
      
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final times = _formatEventTime(
        todayDate,
        startTimeStr: habit.startTime ?? habit.reminderTime,
        endTimeStr: habit.endTime,
      );

      final String freq = habit.type.toLowerCase() == 'weekly' ? 'WEEKLY' : 'DAILY';

      final body = {
        'summary': title,
        'description': description,
        ...times,
        'recurrence': [
          'RRULE:FREQ=$freq',
        ],
      };

      final existingEventId = habitIdToEventId[habit.id];
      try {
        if (existingEventId != null) {
          // Update event
          final url = Uri.parse('$_baseUrl/$existingEventId');
          debugPrint('Google Calendar Sync: Memperbarui event habit: $url dengan judul: "$title"');
          final response = await _client.put(url, headers: await _headers(token), body: jsonEncode(body));
          debugPrint('Google Calendar Sync: PUT response code: ${response.statusCode}');
          if (response.statusCode != 200) {
            throw Exception('Gagal mengubah event kebiasaan di Google Calendar (${response.statusCode}): ${response.body}');
          }
        } else {
          // Buat event baru
          final url = Uri.parse(_baseUrl);
          debugPrint('Google Calendar Sync: Membuat event habit baru ke: $url dengan judul: "$title"');
          final response = await _client.post(url, headers: await _headers(token), body: jsonEncode(body));
          debugPrint('Google Calendar Sync: POST response code: ${response.statusCode}');
          if (response.statusCode != 200 && response.statusCode != 201) {
            throw Exception('Gagal membuat event kebiasaan di Google Calendar (${response.statusCode}): ${response.body}');
          }
        }
      } catch (e) {
        debugPrint('Google Calendar Sync: Exception di syncHabits untuk habit ${habit.id}: $e');
        rethrow;
      }
    }
    debugPrint('Google Calendar Sync: syncHabits() selesai.');
  }
}
