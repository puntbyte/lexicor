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

  // Resolve package URI (ensure DB is under lib/ so package: URI resolves)
  final uri = await Isolate.resolvePackageUri(Uri.parse(packageDbPath));
  if (uri == null) {
    stderr.writeln(
      'Could not resolve $packageDbPath. Ensure DB exists under lib/ and package name is correct.',
    );
    return;
  }
  final dbPath = uri.toFilePath();

  // Open disk DB first
  final diskDb = sqlite3.open(dbPath);

  // OPTIONAL: ensure indexes exist (run once; cheap if already present)
  _createRecommendedIndexes(diskDb);

  Database activeDb = diskDb;

  // If memory mode requested, copy disk -> memory using backup stream and then close disk handle
  if (loadInMemory) {
    final memoryDb = sqlite3.openInMemory();
    try {
      // copy all pages (-1) and wait until done
      await diskDb.backup(memoryDb, nPage: -1).drain();
      diskDb.dispose(); // close disk handle
      activeDb = memoryDb;
    } catch (e) {
      // cleanup on failure
      try {
        memoryDb.dispose();
      } catch (_) {}
      diskDb.dispose();
      rethrow;
    }
  }

  initSw.stop();
  print('Initialization: ${initSw.elapsedMilliseconds} ms (loadInMemory: $loadInMemory)');

  // Construct prepared statements once (reused for all queries)
  final lookupStmt = activeDb.prepare('''
    SELECT s.id AS id, s.part_of_speech_id AS pos, s.domain_category_id AS domain
    FROM synset s
    JOIN sense se ON s.id = se.synset_id
    JOIN word w ON se.word_id = w.id
    WHERE w.text = ?
    ORDER BY se.sense_sort_order ASC
  ''');

  // Also prepare a COUNT(*) variant for raw minimal-allocation benchmarking
  final countStmt = activeDb.prepare('''
    SELECT COUNT(*) AS cnt
    FROM synset s
    JOIN sense se ON s.id = se.synset_id
    JOIN word w ON se.word_id = w.id
    WHERE w.text = ?
  ''');

  // Warm-up (do a couple of quick calls to warm caches / JIT)
  lookupStmt.select([testWord]);
  countStmt.select([testWord]);

  // === Benchmark 1: raw count (minimal allocations) ===
  final countSw = Stopwatch()..start();
  int totalCountResults = 0;
  for (var i = 0; i < iterations; i++) {
    final rows = countStmt.select([testWord]);
    final cnt = rows.first['cnt'] as int;
    totalCountResults += cnt;
  }
  countSw.stop();
  final avgCountUs = (countSw.elapsedMicroseconds / iterations);
  print(
    'Raw COUNT(*) benchmark: $iterations iterations, totalCountResults=$totalCountResults, '
    'total ${countSw.elapsedMilliseconds} ms (avg ${avgCountUs.toStringAsFixed(2)} µs/query)',
  );

  // === Benchmark 2: full lookup (materialize rows -> small objects) ===
  final lookupSw = Stopwatch()..start();
  int totalRows = 0;
  for (var i = 0; i < iterations; i++) {
    final rows = lookupStmt.select([testWord]);
    // materialize: create a very small object (map) per row to simulate real workload
    for (final row in rows) {
      // row['pos'] is CHAR(1) (e.g. 'n','v','a','r','s'); domain is integer id
      final id = row['id'] as int;
      final posRaw = row['pos']; // could be String or int depending on DB binding
      final domainId = row['domain'] as int;
      // simulate small allocation
      final m = <String, Object>{'id': id, 'pos': posRaw.toString(), 'domain': domainId};
      totalRows += 1;
      // avoid optimizing away (no-op)
      if (m.isEmpty) stdout.write('');
    }
  }
  lookupSw.stop();
  final avgLookupUs = (lookupSw.elapsedMicroseconds / iterations);
  print(
    'Full materialized lookup: $iterations iterations, totalRows=$totalRows, '
    'total ${lookupSw.elapsedMilliseconds} ms (avg ${avgLookupUs.toStringAsFixed(2)} µs/query)',
  );

  // === Print a small example output for the word ===
  final sampleRows = lookupStmt.select([testWord]).take(10).toList();
  print('\nSample lookup rows for "$testWord" (first ${sampleRows.length} rows):');
  for (final row in sampleRows) {
    print('  synset_id=${row['id']}, pos=${row['pos']}, domain=${row['domain']}');
  }

  // clean up
  try {
    lookupStmt.dispose();
    countStmt.dispose();
  } catch (_) {}
  try {
    activeDb.dispose();
  } catch (_) {}

  print('\nBenchmark finished for loadInMemory=$loadInMemory');
}

/// Creates recommended indexes to speed up the common joins/lookups.
/// Safe to call repeatedly due to CREATE INDEX IF NOT EXISTS.
void _createRecommendedIndexes(Database db) {
  try {
    db.execute('CREATE INDEX IF NOT EXISTS idx_word_text ON word(text);');
    db.execute('CREATE INDEX IF NOT EXISTS idx_sense_word_id ON sense(word_id);');
    db.execute('CREATE INDEX IF NOT EXISTS idx_sense_synset_id ON sense(synset_id);');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_morph_word_pos ON word_morphology(word_id, part_of_speech_id);',
    );
    db.execute('CREATE INDEX IF NOT EXISTS idx_synset_domain ON synset(domain_category_id);');
    // lexical/semantic source indexes are often present for WITHOUT ROWID tables, but safe to run:
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_semrel_source ON semantic_relationship(source_synset_id);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lexrel_source ON lexical_relationship(source_sense_id);',
    );
  } catch (e) {
    // If any CREATE INDEX fails on a read-only DB or unsupported platform, ignore and continue.
    stderr.writeln('Warning: index creation failed or not supported: $e');
  }
}
