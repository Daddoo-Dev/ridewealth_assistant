import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pendingSyncMessage =
    'Saved on this phone. It will sync when you are back online.';

class PendingEntry {
  const PendingEntry({
    required this.id,
    required this.table,
    required this.payload,
  });

  final String id;
  final String table;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'payload': payload,
      };

  factory PendingEntry.fromJson(Map<String, dynamic> json) {
    return PendingEntry(
      id: json['id'].toString(),
      table: json['table'].toString(),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

abstract final class PendingEntryQueue {
  static const storageKey = 'pendingEntryQueue';
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<void> _tail = Future<void>.value();

  static Future<T> _sync<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static Future<List<PendingEntry>> load() => _sync(_read);

  static Future<void> refreshCount() => _sync(() async {
        final entries = await _read();
        count.value = entries.length;
      });

  static Future<void> enqueue(PendingEntry entry) => _sync(() async {
        final entries = await _read();
        entries.removeWhere((existing) => existing.id == entry.id);
        entries.add(entry);
        await _write(entries);
      });

  static Future<bool> deleteIfQueued(String id) => _sync(() async {
        final entries = await _read();
        final next = entries.where((entry) => entry.id != id).toList();
        if (next.length == entries.length) return false;
        await _write(next);
        return true;
      });

  static Future<List<PendingEntry>> forTable(String table) async {
    final entries = await load();
    return entries.where((entry) => entry.table == table).toList();
  }

  static Future<List<Map<String, dynamic>>> merge(
    String table,
    List<Map<String, dynamic>> remote,
  ) async {
    final pending = await forTable(table);
    final remoteIds = remote.map((row) => row['id']?.toString()).toSet();
    final extras = <Map<String, dynamic>>[];
    for (final entry in pending) {
      if (remoteIds.contains(entry.id)) continue;
      extras.add({
        ...entry.payload,
        'id': entry.id,
        'pending_sync': true,
      });
    }
    return [...extras, ...remote];
  }

  /// Sends each queued row. Stops on the first failure and keeps that row.
  static Future<int> flush(
    Future<void> Function(PendingEntry entry) send,
  ) {
    return _sync(() async {
      final entries = await _read();
      final remaining = <PendingEntry>[];
      var synced = 0;
      var failed = false;
      for (final entry in entries) {
        if (failed) {
          remaining.add(entry);
          continue;
        }
        try {
          await send(entry);
          synced++;
        } catch (_) {
          failed = true;
          remaining.add(entry);
        }
      }
      await _write(remaining);
      return synced;
    });
  }

  static Future<List<PendingEntry>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((item) => PendingEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<void> _write(List<PendingEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(
        storageKey,
        jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      );
    }
    count.value = entries.length;
  }
}
