import 'package:flutter_test/flutter_test.dart';
import 'package:ridewealth_assistant/services/pending_entry_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('queued entries stay until they are removed and show up in the list', () async {
    await PendingEntryQueue.enqueue(PendingEntry(
      id: '11111111-1111-4111-8111-111111111111',
      table: 'mileage',
      payload: {
        'id': '11111111-1111-4111-8111-111111111111',
        'start_mileage': 10,
        'end_mileage': 25,
      },
    ));

    expect(PendingEntryQueue.count.value, 1);

    final merged = await PendingEntryQueue.merge('mileage', []);
    expect(merged, hasLength(1));
    expect(merged.first['pending_sync'], isTrue);
    expect(merged.first['end_mileage'], 25);

    final removed = await PendingEntryQueue.deleteIfQueued(
      '11111111-1111-4111-8111-111111111111',
    );
    expect(removed, isTrue);
    expect(PendingEntryQueue.count.value, 0);
    expect(await PendingEntryQueue.merge('mileage', []), isEmpty);
  });

  test('a flushed entry leaves the queue', () async {
    await PendingEntryQueue.enqueue(PendingEntry(
      id: '22222222-2222-4222-8222-222222222222',
      table: 'income',
      payload: {'id': '22222222-2222-4222-8222-222222222222', 'amount': 12.5},
    ));

    final synced = await PendingEntryQueue.flush((entry) async {
      expect(entry.payload['amount'], 12.5);
    });

    expect(synced, 1);
    expect(await PendingEntryQueue.load(), isEmpty);
  });
}
