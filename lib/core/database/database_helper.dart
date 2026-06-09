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
      version: 7, // Naikkan versi ke 7 untuk mendukung journal_entries & task tags
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
        alarm_sound TEXT
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
  }

  /// Menutup koneksi database (opsional, berguna untuk testing)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

