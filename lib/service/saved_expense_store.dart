import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps saved (not yet submitted) expenses on the device, per employee.
///
/// Files live in the app documents folder, not secure storage, so they
/// survive logout (which clears secure storage). Receipts are copied in
/// because image_picker files sit in a temp folder the OS may clear.
class SavedExpenseStore {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Directory> _dir() async {
    final employee = await _secureStorage.read(key: 'employee_id');
    final key = (employee == null || employee.isEmpty)
        ? '_unknown'
        : employee.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/saved_expenses/$key');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _indexFile() async => File('${(await _dir()).path}/index.json');

  Future<List<SavedExpense>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => SavedExpense.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<SavedExpense> items) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Copies [receipts] into the store unless they are already there.
  Future<List<String>> _keepReceipts(String id, List<File> receipts) async {
    final dir = await _dir();
    final kept = <String>[];
    for (var i = 0; i < receipts.length; i++) {
      final src = receipts[i];
      if (src.path.startsWith(dir.path)) {
        kept.add(src.path);
        continue;
      }
      final ext = src.path.contains('.') ? src.path.split('.').last : 'jpg';
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final copy = await src.copy('${dir.path}/${id}_${stamp}_$i.$ext');
      kept.add(copy.path);
    }
    return kept;
  }

  Future<void> _deleteFiles(Iterable<String> paths) async {
    for (final p in paths) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
  }

  /// Adds a new entry, or replaces the one with the same [id].
  Future<List<SavedExpense>> save({
    String? id,
    required List<NewExpenseLine> lines,
    List<File> receipts = const [],
    String? remark,
  }) async {
    final items = await load();
    final entryId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final paths = await _keepReceipts(entryId, receipts);
    final entry = SavedExpense(
      id: entryId,
      savedAt: DateTime.now(),
      lines: lines,
      receiptPaths: paths,
      remark: remark,
    );

    final index = items.indexWhere((e) => e.id == entryId);
    if (index == -1) {
      items.add(entry);
    } else {
      final dropped = items[index].receiptPaths.where(
        (p) => !paths.contains(p),
      );
      await _deleteFiles(dropped);
      items[index] = entry;
    }
    await _write(items);
    return items;
  }

  /// Removes entries and their receipt files.
  Future<List<SavedExpense>> remove(Set<String> ids) async {
    final items = await load();
    await _deleteFiles(
      items.where((e) => ids.contains(e.id)).expand((e) => e.receiptPaths),
    );
    items.removeWhere((e) => ids.contains(e.id));
    await _write(items);
    return items;
  }
}
