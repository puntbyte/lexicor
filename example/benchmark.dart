// example/benchmark.dart

import 'dart:io';
import 'dart:isolate';
import 'package:sqlite3/sqlite3.dart';

/// Config
const packageDbPath = 'package:lexicor/assets/dictionary.sqlite';
const testWord = 'run';
const iterations = 1000;

void main() async {
  print('Starting Lexicor benchmark example\n');

  // Disk mode benchmark
  print('--- 💾 Disk Mode ---');
  await runBenchmark(loadInMemory: false);

  print('\n');

  // Memory mode benchmark
  print('--- ⚡ Memory Mode ---');
  await runBenchmark(loadInMemory: true);
}

/// High-level runner for one mode
Future<void> runBenchmark({required bool loadInMemory}) async {
  final initSw = Stopwatch()..start();

  // 1. Resolve package URI
  final uri = await Isolate.resolvePackageUri(Uri.parse(packageDbPath));
  if (uri == null) {
    stderr.writeln('Could not resolve $packageDbPath.');
    return;
  }
  final dbPath = uri.toFilePath();

  // 2. Open disk DB (Read-Only to ensure no modifications)
  final diskDb = sqlite3.open(dbPath, mode: OpenMode.readOnly);

  Database activeDb = diskDb;

  // 3. Handle Memory Mode
  if (loadInMemory) {
    final memoryDb = sqlite3.openInMemory();
    try {
      // Copy all pages (-1) and await the stream
      await diskDb.backup(memoryDb, nPage: -1).drain();

      // Close disk handle immediately to free resources
      diskDb.dispose();
      activeDb = memoryDb;
    } catch (e) {
      memoryDb.dispose();
      diskDb.dispose();
      rethrow;
    }
  }

  initSw.stop();
  print('Initialization: ${initSw.elapsedMilliseconds} ms (In-Memory: $loadInMemory)');

  // 4. Prepare Statements
  // We use the exact schema column names.
  final lookupStmt = activeDb.prepare('''
    SELECT s.id AS id, s.part_of_speech_id AS pos, s.domain_category_id AS domain
    FROM synset s
    JOIN sense se ON s.id = se.synset_id
    JOIN word w ON se.word_id = w.id
    WHERE w.text = ?
    ORDER BY se.sense_sort_order ASC
  ''');

  final countStmt = activeDb.prepare('''
    SELECT COUNT(*) AS cnt
    FROM synset s
    JOIN sense se ON s.id = se.synset_id
    JOIN word w ON se.word_id = w.id
    WHERE w.text = ?
  ''');

  try {
    // Warm-up (stabilize JIT)
    lookupStmt.select([testWord]);
    countStmt.select([testWord]);

    // === Benchmark 1: Raw Count (Engine Speed) ===
    final countSw = Stopwatch()..start();
    int totalCountResults = 0;

    for (var i = 0; i < iterations; i++) {
      final rows = countStmt.select([testWord]);
      totalCountResults += rows.first['cnt'] as int;
    }

    countSw.stop();
    final avgCountUs = (countSw.elapsedMicroseconds / iterations);

    print(
      'Raw COUNT(*) : $iterations iterations, '
          '${countSw.elapsedMilliseconds} ms '
          '(avg ${avgCountUs.toStringAsFixed(2)} µs/query)',
    );

    // === Benchmark 2: Full Lookup (Data Access) ===
    final lookupSw = Stopwatch()..start();
    int totalRows = 0;

    for (var i = 0; i < iterations; i++) {
      final rows = lookupStmt.select([testWord]);

      // Materialize rows to simulate real usage
      for (final row in rows) {
        final id = row['id'] as int;
        final pos = row['pos'] as String;
        final domain = row['domain'] as int;

        // Prevent compiler optimization
        if (id > 0 && pos.isNotEmpty && domain >= 0) totalRows++;
      }
    }

    lookupSw.stop();
    final avgLookupUs = (lookupSw.elapsedMicroseconds / iterations);

    print(
      'Full Materialize: $iterations iterations, '
          '${lookupSw.elapsedMilliseconds} ms '
          '(avg ${avgLookupUs.toStringAsFixed(2)} µs/query)',
    );

    // === Validation ===
    final sampleRows = lookupStmt.select([testWord]).take(3).toList();
    if (sampleRows.isNotEmpty) {
      print('Verified: Found ${sampleRows.length}+ rows for "$testWord" (e.g., ID: ${sampleRows.first['id']})');
    }

  } finally {
    // 5. Cleanup
    lookupStmt.dispose();
    countStmt.dispose();
    activeDb.dispose();
  }
}