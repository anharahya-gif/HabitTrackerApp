import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/habit.dart';
import '../controllers/habit_list_controller.dart';

/// Form Tambah Habit baru dengan pilihan warna, kategori, tipe, dan pengingat waktu.
class AddHabitPage extends ConsumerStatefulWidget {
  final bool isPrivateDefault;
  const AddHabitPage({super.key, this.isPrivateDefault = false});

  @override
  ConsumerState<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends ConsumerState<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _category = 'Kesehatan';
  String _type = 'daily'; // 'daily', 'weekly', 'specific_days', 'interval', 'flexible_weekly'
  TimeOfDay? _reminderTime;
  bool _isPrivate = false;

  // Variabel konfigurasi frekuensi kustom
  final List<int> _specificDays = [1, 3, 5]; // default: Senin, Rabu, Jumat
  int _intervalDays = 2; // default: Setiap 2 hari
  int _flexibleWeeklyTarget = 3; // default: 3x seminggu
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _reminderType = 'notification';
  
  List<Map<String, String>> _availableSounds = [];
  String? _selectedSoundUri;
  bool _isPlayingPreview = false;
  
  // Pilihan warna premium untuk habit
  final List<int> _colors = [
    0xFF6366F1, // Indigo
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFFEC4899, // Pink
    0xFF8B5CF6, // Purple
  ];
  late int _selectedColor;

  final List<String> _categories = [
    'Kesehatan',
    'Produktivitas',
    'Kebugaran',
    'Mental/Pikiran',
    'Sosial/Hubungan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.isPrivateDefault;
    _selectedColor = _colors.first;
    _loadAlarmSounds();
  }

  @override
  void dispose() {
    _stopPreview();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadAlarmSounds() async {
    try {
      const platform = MethodChannel('com.anhar.dailio/alarm');
      final List<dynamic>? sounds = await platform.invokeMethod<List<dynamic>>('getAlarmSounds');
      if (sounds != null) {
        setState(() {
          _availableSounds = sounds.map((s) => Map<String, String>.from(s as Map)).toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat nada alarm: $e');
    }
  }

  Future<void> _playPreview() async {
    final uri = _selectedSoundUri;
    const platform = MethodChannel('com.anhar.dailio/alarm');
    if (uri == null) {
      try {
        final defaultUri = await platform.invokeMethod<String>('getAlarmUri');
        if (defaultUri != null) {
          await platform.invokeMethod('playAlarmSound', {'uri': defaultUri});
          setState(() {
            _isPlayingPreview = true;
          });
        }
      } catch (e) {
        debugPrint('Gagal memutar nada default: $e');
      }
    } else {
      try {
        await platform.invokeMethod('playAlarmSound', {'uri': uri});
        setState(() {
          _isPlayingPreview = true;
        });
      } catch (e) {
        debugPrint('Gagal memutar nada terpilih: $e');
      }
    }
  }

  Future<void> _stopPreview() async {
    if (!_isPlayingPreview) return;
    try {
      const platform = MethodChannel('com.anhar.dailio/alarm');
      await platform.invokeMethod('stopAlarmSound');
      setState(() {
        _isPlayingPreview = false;
      });
    } catch (e) {
      debugPrint('Gagal menghentikan nada: $e');
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _selectExecutionTime(BuildContext context, bool isStart) async {
    final initialTime = isStart 
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 9, minute: 0));
        
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String? get _calculatedDuration {
    if (_startTime == null || _endTime == null) return null;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    int diff = endMinutes - startMinutes;
    if (diff < 0) {
      // Menangani rentang waktu yang melewati tengah malam (misal 23:00 - 01:00)
      diff += 24 * 60;
    }
    
    final hours = diff ~/ 60;
    final mins = diff % 60;
    
    String res = '';
    if (hours > 0) res += '$hours jam';
    if (mins > 0) {
      if (res.isNotEmpty) res += ' ';
      res += '$mins menit';
    }
    return res.isEmpty ? '0 menit' : res;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_startTime != null && _endTime == null) || (_startTime == null && _endTime != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam Mulai dan Selesai harus diisi keduanya jika ingin menyetel target waktu pelaksanaan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String? reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final String? startTimeStr = _startTime != null
        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
        : null;
    final String? endTimeStr = _endTime != null
        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
        : null;

    String? frequencyConfigStr;
    if (_type == 'specific_days') {
      frequencyConfigStr = jsonEncode({'days': _specificDays});
    } else if (_type == 'interval') {
      frequencyConfigStr = jsonEncode({'interval_days': _intervalDays});
    } else if (_type == 'flexible_weekly') {
      frequencyConfigStr = jsonEncode({'target_count': _flexibleWeeklyTarget});
    }

    // Buat entitas Habit baru
    final newHabit = Habit(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      category: _category,
      type: _type,
      createdAt: DateTime.now(),
      reminderTime: reminderStr,
      color: _selectedColor,
      startTime: startTimeStr,
      endTime: endTimeStr,
      reminderType: _reminderType,
      alarmSound: _selectedSoundUri,
      frequencyConfig: frequencyConfigStr,
      isPrivate: _isPrivate,
    );

    // Kirim aksi ke controller
    final result = await ref.read(habitListProvider.notifier).addHabit(newHabit);

    if (mounted) {
      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        },
        onFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Habit Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Nama Habit
                  Text(
                    'Apa kebiasaan yang ingin Anda bangun?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Olahraga Pagi, Baca Buku, Minum Air...',
                    ),
                    maxLength: 50,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama habit wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Deskripsi (Opsional)
                  const Text(
                    'Deskripsi / Catatan Tambahan (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Minimal 20 menit, 2 liter sehari...',
                    ),
                    maxLines: 2,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Row Kategori & Frekuensi
                  Row(
                    children: [
                      // Dropdown Kategori
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _category,
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Frekuensi Tipe
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frekuensi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _type,
                              items: const [
                                DropdownMenuItem(
                                  value: 'daily',
                                  child: Text('Harian', style: TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'weekly',
                                  child: Text('Mingguan', style: TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'specific_days',
                                  child: Text('Hari Spesifik', style: TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'interval',
                                  child: Text('Interval Hari', style: TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'flexible_weekly',
                                  child: Text('Kustom Mingguan', style: TextStyle(fontSize: 14)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Panel Konfigurasi Frekuensi Kustom
                  if (_type == 'specific_days') ...[
                    const SizedBox(height: 16),
                    const Text('Pilih Hari Pelaksanaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayVal = index + 1; // 1 = Mon, 7 = Sun
                        final labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                        final isSelected = _specificDays.contains(dayVal);

                        return ChoiceChip(
                          label: Text(labels[index], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                          selected: isSelected,
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: Colors.transparent,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.transparent),
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!_specificDays.contains(dayVal)) {
                                  _specificDays.add(dayVal);
                                }
                              } else {
                                if (_specificDays.length > 1) {
                                  _specificDays.remove(dayVal);
                                }
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ] else if (_type == 'interval') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Setiap Berapa Hari?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        Text('Setiap $_intervalDays hari sekali', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: _intervalDays.toDouble(),
                      min: 2,
                      max: 30,
                      divisions: 28,
                      label: 'Setiap $_intervalDays hari',
                      onChanged: (val) {
                        setState(() {
                          _intervalDays = val.toInt();
                        });
                      },
                    ),
                  ] else if (_type == 'flexible_weekly') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target Frekuensi Per Minggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        Text('$_flexibleWeeklyTarget kali seminggu', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: _flexibleWeeklyTarget.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: '$_flexibleWeeklyTarget kali',
                      onChanged: (val) {
                        setState(() {
                          _flexibleWeeklyTarget = val.toInt();
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Pengingat Waktu (Reminder Time)
                  const Text(
                    'Pengingat Waktu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _reminderTime != null
                                ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                                : 'Tidak ada pengingat',
                            style: TextStyle(
                              color: _reminderTime != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          Icon(
                            Icons.access_time_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_reminderTime != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tipe Pengingat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'notification',
                            label: Text('Notifikasi Biasa'),
                            icon: Icon(Icons.notifications_none_rounded),
                          ),
                          ButtonSegment<String>(
                            value: 'alarm',
                            label: Text('Alarm Berdering'),
                            icon: Icon(Icons.alarm_on_rounded),
                          ),
                        ],
                        selected: <String>{_reminderType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _reminderType = newSelection.first;
                          });
                          _stopPreview();
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          selectedForegroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_reminderType == 'alarm') ...[
                      const SizedBox(height: 16),
                      Text(
                        'Nada Suara Alarm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSoundUri ?? 'default',
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: 'default',
                                  child: Text('Nada Alarm Default'),
                                ),
                                ..._availableSounds.map((sound) {
                                  return DropdownMenuItem<String>(
                                    value: sound['uri'],
                                    child: Text(
                                      sound['title'] ?? 'Unknown Sound',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSoundUri = val == 'default' ? null : val;
                                });
                                _stopPreview();
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: () {
                              if (_isPlayingPreview) {
                                _stopPreview();
                              } else {
                                _playPreview();
                              }
                            },
                            icon: Icon(
                              _isPlayingPreview
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // Target Waktu Pelaksanaan (Opsional)
                  const Text(
                    'Target Waktu Pelaksanaan (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Jam Mulai
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectExecutionTime(context, true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startTime != null
                                      ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Jam Mulai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startTime != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Jam Selesai
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectExecutionTime(context, false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endTime != null
                                      ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Jam Selesai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _endTime != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                Icon(
                                  Icons.stop_circle_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_startTime != null && _endTime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Estimasi durasi: $_calculatedDuration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Color Picker Bullets Row
                  const Text(
                    'Pilih Warna Tema Habit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final colorInt = _colors[index];
                        final isSelected = _selectedColor == colorInt;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = colorInt;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(colorInt),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(colorInt).withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Privat
                  SwitchListTile(
                    title: const Text(
                      'Habit Privat (Simpan di Vault) 🔒',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Sembunyikan dari dashboard umum, widget, dan calendar sync',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _isPrivate,
                    onChanged: (val) {
                      setState(() {
                        _isPrivate = val;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 40),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Simpan Habit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
