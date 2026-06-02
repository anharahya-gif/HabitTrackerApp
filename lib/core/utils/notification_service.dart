import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../features/habits/domain/entities/habit.dart';

/// Layanan Notifikasi Lokal Premium untuk aplikasi Dailio.
/// Menangani inisialisasi, perizinan, penjadwalan berulang harian/mingguan,
/// serta pembatalan notifikasi pengingat kebiasaan.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi awal notifikasi lokal dan timezone
  static Future<void> initialize() async {
    // 1. Inisialisasi database timezone
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback ke UTC jika gagal mendeteksi timezone lokal
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Pengaturan Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. Pengaturan iOS/Darwin
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 4. Gabungkan pengaturan inisialisasi
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 5. Eksekusi inisialisasi plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Aksi ketika notifikasi diklik (jika ingin membuka halaman tertentu di masa depan)
      },
    );
  }

  /// Meminta izin notifikasi ke pengguna (Android 13+ & iOS)
  static Future<void> requestPermissions() async {
    // Android
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      try {
        // Meminta izin alarm tepat (exact alarm) untuk ketepatan waktu pengingat
        await androidPlugin.requestExactAlarmsPermission();
      } catch (_) {
        // Abaikan jika tidak didukung versi OS/library tertentu
      }
    }

    // iOS/Darwin
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Menghitung waktu instansi berikutnya untuk alarm
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, [int? dayOfWeek]) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (dayOfWeek != null) {
      while (scheduledDate.weekday != dayOfWeek) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    return scheduledDate;
  }

  /// Menjadwalkan notifikasi berulang untuk suatu kebiasaan (Habit)
  static Future<void> scheduleHabitNotification(Habit habit) async {
    if (habit.reminderTime == null) {
      // Jika tidak ada pengingat, batalkan notifikasi yang mungkin sudah dijadwalkan sebelumnya
      await cancelHabitNotification(habit.id);
      return;
    }

    final timeParts = habit.reminderTime!.split(':');
    if (timeParts.length != 2) return;

    final int? hour = int.tryParse(timeParts[0]);
    final int? minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) return;

    // Hash UUID String habit.id ke 31-bit Integer non-negatif yang unik
    final int notificationId = habit.id.hashCode & 0x7FFFFFFF;

    // Konfigurasi Detail Saluran Android
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_reminders', // Channel ID
      'Pengingat Kebiasaan', // Channel Name
      channelDescription: 'Saluran notifikasi pengingat kebiasaan harian dan mingguan',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(habit.color),
      playSound: true,
    );

    // Konfigurasi Gabungan Platform
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final bool isWeekly = habit.type == 'weekly';
    final int? dayOfWeek = isWeekly ? habit.createdAt.weekday : null;

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute, dayOfWeek);

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Ayo selesaikan habit-mu! 🌟',
        'Waktunya untuk melakukan: ${habit.name}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: isWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : DateTimeComponents.time,
      );
    } catch (e) {
      // Fallback ke inexact scheduling jika exact alarm tidak diizinkan di OS Android 14+
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Ayo selesaikan habit-mu! 🌟',
        'Waktunya untuk melakukan: ${habit.name}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: isWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : DateTimeComponents.time,
      );
    }
  }

  /// Membatalkan notifikasi untuk habit tertentu
  static Future<void> cancelHabitNotification(String habitId) async {
    final int notificationId = habitId.hashCode & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(notificationId);
  }

  /// Menjadwalkan pengingat secara massal untuk semua habit aktif
  static Future<void> scheduleAllNotifications(List<Habit> habits) async {
    // 1. Batalkan semua untuk menyegarkan state penjadwalan
    await _notificationsPlugin.cancelAll();

    // 2. Jadwalkan ulang yang aktif dan memiliki reminderTime
    for (final habit in habits) {
      if (!habit.isArchived && habit.reminderTime != null) {
        await scheduleHabitNotification(habit);
      }
    }
  }

  /// Mengirim notifikasi uji coba secara instan untuk verifikasi integrasi
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_reminders',
      'Uji Coba Notifikasi',
      channelDescription: 'Saluran notifikasi pengujian instan',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _notificationsPlugin.show(
      999,
      'Halo dari Dailio! 🌿',
      'Notifikasi instan berhasil dikirim. Sistem notifikasi Anda berfungsi!',
      notificationDetails,
    );
  }
}
