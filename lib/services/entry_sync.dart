import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pending_entry_queue.dart';
import 'remote_insert.dart';

abstract final class EntrySync {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    await PendingEntryQueue.refreshCount();
    await flush();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);
      if (!offline) flush();
    });
  }

  static Future<int> flush() async {
    if (await RemoteInsert.isOffline()) return 0;
    try {
      return await PendingEntryQueue.flush((entry) async {
        final payload = {...entry.payload}
          ..remove('id')
          ..remove('pending_sync');
        try {
          await Supabase.instance.client.from(entry.table).insert(payload);
        } catch (error) {
          debugPrint('EntrySync kept ${entry.table}/${entry.id}: $error');
          rethrow;
        }
      });
    } catch (error) {
      debugPrint('EntrySync flush failed: $error');
      return 0;
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
