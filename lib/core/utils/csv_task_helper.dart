import 'package:uuid/uuid.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Helper kelas untuk proses serialization & deserialization list [Task] ke format CSV (.csv).
class CsvTaskHelper {
  CsvTaskHelper._();

  /// Mengubah daftar [Task] menjadi string CSV
  static String tasksToCsv(List<Task> tasks) {
    final List<String> csvRows = [];
    
    // 1. Tambahkan Header
    csvRows.add('id,title,description,due_date,priority,category,is_completed,completed_at,created_at,updated_at');
    
    // 2. Tambahkan Data
    for (final task in tasks) {
      final id = _escapeField(task.id);
      final title = _escapeField(task.title);
      final description = _escapeField(task.description ?? '');
      final dueDate = task.dueDate?.toIso8601String() ?? '';
      final priority = _escapeField(task.priority);
      final category = _escapeField(task.category);
      final isCompleted = task.isCompleted ? '1' : '0';
      final completedAt = task.completedAt?.toIso8601String() ?? '';
      final createdAt = task.createdAt.toIso8601String();
      final updatedAt = task.updatedAt.toIso8601String();
      
      csvRows.add('$id,$title,$description,$dueDate,$priority,$category,$isCompleted,$completedAt,$createdAt,$updatedAt');
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

  /// Membaca string CSV dan mengembalikannya menjadi daftar [Task]
  static List<Task> csvToTasks(String csvContent) {
    final List<Task> tasks = [];
    final List<String> lines = csvContent.split(RegExp(r'\r?\n'));
    
    if (lines.isEmpty) return tasks;
    
    // Baris data dimulai setelah baris pertama (header)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final fields = _parseCsvLine(line);
      if (fields.length < 8) continue; // Pastikan kolom esensial lengkap
      
      final id = fields[0].isNotEmpty ? fields[0] : const Uuid().v4();
      final title = fields[1].isNotEmpty ? fields[1] : 'Tanpa Judul';
      final description = fields[2].isNotEmpty ? fields[2] : null;
      final dueDate = fields[3].isNotEmpty ? DateTime.tryParse(fields[3]) : null;
      final priority = fields[4].isNotEmpty ? fields[4] : 'medium';
      final category = fields[5].isNotEmpty ? fields[5] : 'Lainnya';
      final isCompleted = fields[6] == '1';
      final completedAt = fields[7].isNotEmpty ? DateTime.tryParse(fields[7]) : null;
      final createdAt = fields.length > 8 && fields[8].isNotEmpty 
          ? (DateTime.tryParse(fields[8]) ?? DateTime.now()) 
          : DateTime.now();
      final updatedAt = fields.length > 9 && fields[9].isNotEmpty 
          ? (DateTime.tryParse(fields[9]) ?? DateTime.now()) 
          : DateTime.now();
      
      tasks.add(Task(
        id: id,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        category: category,
        isCompleted: isCompleted,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isSynced: false,
      ));
    }
    
    return tasks;
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
