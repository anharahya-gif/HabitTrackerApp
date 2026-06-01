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
      version: 1, // Siap untuk migrasi dengan menaikkan versi ini
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
        color INTEGER NOT NULL
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Logika migrasi siap ditaruh di sini jika skema berubah pada update berikutnya.
    // Contoh:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE habits ADD COLUMN category_id TEXT');
    // }
  }

  /// Menutup koneksi database (opsional, berguna untuk testing)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
