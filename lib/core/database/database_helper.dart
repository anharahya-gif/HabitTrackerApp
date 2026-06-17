import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Helper Singleton SQLite database yang mengelola siklus hidup database,
/// pembuatan tabel, dan migrasi di masa depan.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habit_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, filePath);

    return await openDatabase(
      pathString,
      version: 14, // Naikkan versi ke 14 untuk mendukung Fitur Doa Favorit
      onCreate: _createDB,
      onConfigure: _configureDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Wajib untuk memastikan integritas Foreign Key di SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Membuat tabel habits
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        reminder_time TEXT,
        color INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        reminder_type TEXT NOT NULL DEFAULT 'notification',
        alarm_sound TEXT,
        frequency_config TEXT,
        is_private INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Membuat tabel habit_logs dengan FK ke habits
    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        completed_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // 3. Membuat tabel habit_streaks dengan FK ke habits
    await db.execute('''
      CREATE TABLE habit_streaks (
        habit_id TEXT PRIMARY KEY,
        current_streak INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Opsional: Buat index untuk meningkatkan kecepatan pencarian log berdasarkan habit dan tanggal
    await db.execute('CREATE INDEX idx_logs_habit_date ON habit_logs (habit_id, date)');

    // 4. Membuat tabel tasks untuk fitur Tugas Harian (to-do list)
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        priority TEXT NOT NULL DEFAULT 'medium',
        category TEXT NOT NULL DEFAULT 'Lainnya',
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        tags TEXT
      )
    ''');

    // 5. Membuat tabel journal_entries untuk Catatan Harian & Mood Tracker
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        mood TEXT NOT NULL,
        content TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index untuk pencarian jurnal berdasarkan tanggal
    await db.execute('CREATE INDEX idx_journal_date ON journal_entries (date)');

    // 6. Membuat tabel vision_items untuk Papan Visi / My Why
    await _createVisionItemsTable(db);

    // 7. Membuat tabel urge_logs untuk Catatan Pemicu / Urge Log
    await _createUrgeLogsTable(db);

    // 8. Membuat tabel prayer_times untuk Jadwal Shalat
    await _createPrayerTimesTable(db);

    // 9. Membuat tabel ibadah_logs untuk Catatan Ibadah Harian
    await _createIbadahLogsTable(db);

    // 10. Membuat tabel daily_ayah untuk Ayat Hari Ini
    await _createDailyAyahTable(db);

    // 11. Membuat tabel favorite_ayahs untuk Ayat Favorit
    await _createFavoriteAyahsTable(db);

    // 12. Membuat tabel favorite_doas untuk Doa Favorit
    await _createFavoriteDoasTable(db);
  }

  Future<void> _createVisionItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE vision_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createUrgeLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE urge_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        severity INTEGER NOT NULL,
        trigger_emotion TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPrayerTimesTable(Database db) async {
    await db.execute('''
      CREATE TABLE prayer_times (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        city TEXT NOT NULL,
        fajr TEXT NOT NULL,
        dhuhr TEXT NOT NULL,
        asr TEXT NOT NULL,
        maghrib TEXT NOT NULL,
        isha TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createIbadahLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ibadah_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        subuh TEXT NOT NULL DEFAULT 'belum',
        dzuhur TEXT NOT NULL DEFAULT 'belum',
        ashar TEXT NOT NULL DEFAULT 'belum',
        maghrib TEXT NOT NULL DEFAULT 'belum',
        isya TEXT NOT NULL DEFAULT 'belum',
        quran_pages INTEGER NOT NULL DEFAULT 0,
        dhikr_count INTEGER NOT NULL DEFAULT 0,
        duha INTEGER NOT NULL DEFAULT 0,
        tahajjud INTEGER NOT NULL DEFAULT 0,
        sedekah INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createDailyAyahTable(Database db) async {
    await db.execute('''
      CREATE TABLE daily_ayah (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        arabic_text TEXT NOT NULL,
        translation TEXT NOT NULL,
        audio_url TEXT,
        tajwid_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFavoriteAyahsTable(Database db) async {
    await db.execute('''
      CREATE TABLE favorite_ayahs (
        id TEXT PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        arabic_text TEXT NOT NULL,
        translation TEXT NOT NULL,
        audio_url TEXT,
        tajwid_json TEXT,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFavoriteDoasTable(Database db) async {
    await db.execute('''
      CREATE TABLE favorite_doas (
        doa_id TEXT PRIMARY KEY,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah kolom is_synced dan updated_at ke tabel habits
      if (!await _columnExists(db, 'habits', 'is_synced')) {
        await db.execute('ALTER TABLE habits ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      }
      if (!await _columnExists(db, 'habits', 'updated_at')) {
        await db.execute('ALTER TABLE habits ADD COLUMN updated_at TEXT NOT NULL DEFAULT ""');
      }

      // Tambah kolom is_synced dan updated_at ke tabel habit_logs
      if (!await _columnExists(db, 'habit_logs', 'is_synced')) {
        await db.execute('ALTER TABLE habit_logs ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      }
      if (!await _columnExists(db, 'habit_logs', 'updated_at')) {
        await db.execute('ALTER TABLE habit_logs ADD COLUMN updated_at TEXT NOT NULL DEFAULT ""');
      }
    }

    if (oldVersion < 3) {
      // Tambah kolom start_time dan end_time ke tabel habits
      if (!await _columnExists(db, 'habits', 'start_time')) {
        await db.execute('ALTER TABLE habits ADD COLUMN start_time TEXT');
      }
      if (!await _columnExists(db, 'habits', 'end_time')) {
        await db.execute('ALTER TABLE habits ADD COLUMN end_time TEXT');
      }
    }

    if (oldVersion < 4) {
      // Tambah kolom reminder_type ke tabel habits
      if (!await _columnExists(db, 'habits', 'reminder_type')) {
        await db.execute("ALTER TABLE habits ADD COLUMN reminder_type TEXT NOT NULL DEFAULT 'notification'");
      }
    }

    if (oldVersion < 5) {
      // Buat tabel tasks jika belum ada
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          due_date TEXT,
          priority TEXT NOT NULL DEFAULT 'medium',
          category TEXT NOT NULL DEFAULT 'Lainnya',
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 6) {
      if (!await _columnExists(db, 'habits', 'alarm_sound')) {
        await db.execute('ALTER TABLE habits ADD COLUMN alarm_sound TEXT');
      }
    }

    if (oldVersion < 7) {
      // Tambah kolom tags ke tabel tasks
      if (!await _columnExists(db, 'tasks', 'tags')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN tags TEXT');
      }

      // Buat tabel journal_entries untuk Catatan Harian & Mood Tracker
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL UNIQUE,
          mood TEXT NOT NULL,
          content TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries (date)');
    }

    if (oldVersion < 8) {
      if (!await _columnExists(db, 'habits', 'frequency_config')) {
        await db.execute('ALTER TABLE habits ADD COLUMN frequency_config TEXT');
      }
    }

    if (oldVersion < 9) {
      if (!await _columnExists(db, 'habits', 'is_private')) {
        await db.execute('ALTER TABLE habits ADD COLUMN is_private INTEGER NOT NULL DEFAULT 0');
      }
    }

    if (oldVersion < 10) {
      await _createVisionItemsTable(db);
    }

    if (oldVersion < 11) {
      await _createUrgeLogsTable(db);
    }

    if (oldVersion < 12) {
      await _createPrayerTimesTable(db);
      await _createIbadahLogsTable(db);
    }

    if (oldVersion < 13) {
      await _createDailyAyahTable(db);
      await _createFavoriteAyahsTable(db);
    }

    if (oldVersion < 14) {
      await _createFavoriteDoasTable(db);
    }
  }

  /// Menutup koneksi database (opsional, berguna untuk testing)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      try {
        await db.close();
      } catch (_) {}
      _database = null;
    }
  }
}

