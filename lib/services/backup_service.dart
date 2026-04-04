import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';

class BackupService {
  Future<String> exportBackup({
    required CounterProvider counters,
    required SettingsProvider settings,
  }) async {
    final data = {
      "exportedAt": DateTime.now().toIso8601String(),
      "store": counters.toBackupMap(),
      "settings": settings.toBackupMap(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/mantra_backup_${DateTime.now().millisecondsSinceEpoch}.json";
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent("  ").convert(data));
    return path;
  }

  Future<Map<String, dynamic>?> pickAndReadBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;

    final path = result.files.single.path!;
    final raw = await File(path).readAsString();
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}