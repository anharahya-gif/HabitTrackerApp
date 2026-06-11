import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/vision_item_model.dart';

/// Data Source lokal untuk mengelola operasi CRUD Vision Board (tabel vision_items).
class VisionLocalDataSource {
  final DatabaseHelper _dbHelper;

  VisionLocalDataSource(this._dbHelper);

  /// Menambahkan Vision Item baru ke database SQLite.
  Future<void> insertVisionItem(VisionItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'vision_items',
      item.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua Vision Items dari database diurutkan dari yang terbaru dibuat.
  Future<List<VisionItemModel>> getVisionItems() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vision_items',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => VisionItemModel.fromSqlMap(map)).toList();
  }

  /// Memperbarui Vision Item yang sudah ada di database.
  Future<void> updateVisionItem(VisionItemModel item) async {
    final db = await _dbHelper.database;
    await db.update(
      'vision_items',
      item.toSqlMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Menghapus Vision Item berdasarkan ID.
  Future<void> deleteVisionItem(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'vision_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
