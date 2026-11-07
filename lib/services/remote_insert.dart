import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_failure.dart';
import 'pending_entry_queue.dart';

class InsertResult {
  const InsertResult.saved(this.id) : queued = false;
  const InsertResult.queued(this.id) : queued = true;

  final String id;
  final bool queued;
}

abstract final class RemoteInsert {
  static Future<bool> isOffline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  static Future<InsertResult> insert({
    required String table,
    required Map<String, dynamic> row,
  }) async {
    final localId = PendingEntryQueue.newId();
    final payload = {...row}..remove('pending_sync')..remove('id');

    Future<InsertResult> queue() async {
      await PendingEntryQueue.enqueue(
        PendingEntry(id: localId, table: table, payload: payload),
      );
      return InsertResult.queued(localId);
    }

    if (await isOffline()) return queue();

    try {
      await Supabase.instance.client.from(table).insert(payload);
      return InsertResult.saved(localId);
    } catch (error, stack) {
      if (isRetryableNetworkError(error)) return queue();
      debugPrint('RemoteInsert failed for $table: $error');
      await Sentry.captureException(error, stackTrace: stack);
      rethrow;
    }
  }
}
