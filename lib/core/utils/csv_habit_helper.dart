import 'package:uuid/uuid.dart';
import '../../features/habits/domain/entities/habit.dart';

/// Helper kelas untuk proses serialization & deserialization list [Habit] ke format CSV (.csv).
class CsvHabitHelper {
  CsvHabitHelper._();

  /// Mengubah daftar [Habit] menjadi string CSV
  static String habitsToCsv(List<Habit> habits) {
    final List<String> csvRows = [];
    
    // 1. Tambahkan Header
    csvRows.add('id,name,description,category,type,created_at,is_archived,reminder_time,color');
    
    // 2. Tambahkan Data
    for (final habit in habits) {
      final id = _escapeField(habit.id);
      final name = _escapeField(habit.name);
      final description = _escapeField(habit.description ?? '');
      final category = _escapeField(habit.category);
      final type = _escapeField(habit.type);
      final createdAt = habit.createdAt.toIso8601String();
      final isArchived = habit.isArchived ? '1' : '0';
      final reminderTime = _escapeField(habit.reminderTime ?? '');
      final color = habit.color.toString();
      
      csvRows.add('$id,$name,$description,$category,$type,$createdAt,$isArchived,$reminderTime,$color');
    }
    
    return csvRows.join('\n');
  }

  /// Membantu me-escape string khusus yang mengandung koma, baris baru, atau tanda petik ganda
  static String _escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      // Double quotes di-escape dengan menggandakannya menjadi ""
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Membaca string CSV dan mengembalikannya menjadi daftar [Habit]
  static List<Habit> csvToHabits(String csvContent) {
    final List<Habit> habits = [];
    final List<String> lines = csvContent.split(RegExp(r'\r?\n'));
    
    if (lines.isEmpty) return habits;
    
    // Baris data dimulai setelah baris pertama (header)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final fields = _parseCsvLine(line);
      if (fields.length < 9) continue; // Pastikan data kolom lengkap
      
      final id = fields[0].isNotEmpty ? fields[0] : const Uuid().v4();
      final name = fields[1].isNotEmpty ? fields[1] : 'Tanpa Nama';
      final description = fields[2].isNotEmpty ? fields[2] : null;
      final category = fields[3].isNotEmpty ? fields[3] : 'Umum';
      final type = fields[4].isNotEmpty ? fields[4] : 'daily';
      final createdAt = DateTime.tryParse(fields[5]) ?? DateTime.now();
      final isArchived = fields[6] == '1';
      final reminderTime = fields[7].isNotEmpty ? fields[7] : null;
      final color = int.tryParse(fields[8]) ?? 4284128256;
      
      habits.add(Habit(
        id: id,
        name: name,
        description: description,
        category: category,
        type: type,
        createdAt: createdAt,
        isArchived: isArchived,
        reminderTime: reminderTime,
        color: color,
      ));
    }
    
    return habits;
  }

  /// Melakukan parsing satu baris CSV secara tangguh dengan mendukung kolom ber-tanda petik ganda
  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Menangani double quotes yang di-escape ("") -> masukkan satu tanda petik ganda
          currentField.write('"');
          i++; // Lewati tanda petik ganda berikutnya
        } else {
          // Toggle status berada di dalam quotes
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Komma di luar tanda petik menandakan pemisah kolom
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    // Tambahkan kolom terakhir
    fields.add(currentField.toString());
    return fields;
  }
}
