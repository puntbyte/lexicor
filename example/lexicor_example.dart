// example/lexicor_demo.dart
import 'dart:io';

import 'package:lexicor/lexicor.dart';

const testWord = 'went'; // shows morphology: went -> go
const benchWord = 'run';
const iterations = 1000;
const sampleLimit = 10;

void main() async {
  printBanner('Lexicor — WordNet Demo');

  // --- Disk mode demo ---
  printSection('Initializing (Disk mode)');
  late final Lexicor diskLex;
  try {
    diskLex = await Lexicor.init();
    print('Disk Lexicor ready.');

    await demoFlow(diskLex, modeLabel: 'Disk', lookupWord: testWord);
  } finally {
    // ensure closed even on error
    try {
      diskLex.close();
    } catch (_) {}
  }

  print('\n');

  // --- Memory mode demo ---
  printSection('Initializing (Memory mode)');
  late final Lexicor memLex;
  try {
    memLex = await Lexicor.init(inMemory: true);
    print('Memory Lexicor ready.');

    await demoFlow(memLex, modeLabel: 'Memory', lookupWord: testWord);
  } finally {
    try {
      memLex.close();
    } catch (_) {}
  }

  printBanner('Demo completed');
}

/// Runs the demo flow: lookup, morphology, related, and benchmarks.
Future<void> demoFlow(Lexicor lex, {required String modeLabel, required String lookupWord}) async {
  print('\n--- 🔍 Lookup: "$lookupWord" ($modeLabel) ---');

  // New API: LookupResult (includes resolvedForms + concepts)
  final result = lex.lookup(lookupWord);

  print('Query: "${result.query}"');
  print('Resolved forms: ${result.resolvedForms.join(', ')}');
  print('Total concepts: ${result.concepts.length}');
  if (result.isEmpty) {
    print('No concepts found for "$lookupWord".');
  } else {
    print('\nSample concepts (first $sampleLimit):');
    for (final c in result.concepts.take(sampleLimit)) {
      print(' • Concept ${c.id} | POS: ${c.pos.label} | Domain: ${c.domain.label}');
    }

    // show primary concept and quick helpers
    final primary = result.primary;
    if (primary != null) {
      print('\nPrimary concept: ${primary.id} (${primary.pos.label}, ${primary.domain.label})');

      // Related words (semantic + lexical)
      print('\n--- 🔗 Related words for primary concept (${primary.id}) ---');
      final related = lex.related(primary.id); // returns List<RelatedWord>
      print('Found ${related.length} relations (showing $sampleLimit):');

      for (final r in related.take(sampleLimit)) {
        final kind = r.isSemantic ? 'semantic' : 'lexical';
        print(' • ${r.word} [${r.relation.label}] ($kind)');
      }

      // Hypernyms only as a filtered example
      final hypernyms = lex.related(primary.id, type: RelationType.hypernym);
      if (hypernyms.isNotEmpty) {
        print('\nHypernyms: ${hypernyms.map((h) => h.word).take(10).join(', ')}');
      } else {
        print('\nNo hypernyms found for concept ${primary.id}.');
      }
    }
  }

  // Morphology quick checks (explicit helper)
  print('\n--- 🧬 Morphology examples ---');
  print("running (verb) → ${lex.morphology('running', PartOfSpeech.verb)}");
  print("better (adj)   → ${lex.morphology('better', PartOfSpeech.adjective)}");

  // Benchmarks
  print('\n--- 📊 Benchmarks ($modeLabel) ---');
  await runBenchmarks(lex, benchWord, iterations);
}

/// Runs two benchmarks:
/// 1) raw COUNT() (minimal allocation)
/// 2) full materialized lookup (realistic)
Future<void> runBenchmarks(Lexicor lex, String word, int iterations) async {
  // Warm-up: a couple of calls to stabilize caches/JIT
  lex.lookup(word);
  lex.lookup(word);

  // Prepare raw-count statement by using a tiny internal method that runs the COUNT query.
  final rawCount = _benchmarkCount(lex, word, iterations);
  final full = _benchmarkFull(lex, word, iterations);

  print(
    'Raw COUNT benchmark: ${rawCount.totalMs} ms for $iterations (avg '
        '${rawCount.avgUs.toStringAsFixed(2)} µs/query), totalRows=${rawCount.totalRows}',
  );
  print(
    'Full materialized:  ${full.totalMs} ms for $iterations (avg ${full.avgUs.toStringAsFixed(2)} '
        'µs/query), totalRows=${full.totalRows}',
  );
}

/// Minimal count-style benchmark (no heavy allocations)
_BenchResult _benchmarkCount(Lexicor lex, String word, int iterations) {
  final sw = Stopwatch()..start();
  var totalRows = 0;
  for (var i = 0; i < iterations; i++) {
    // Use the existing lookupResult but only read length to simulate minimal materialization.
    final r = lex.lookup(word);
    totalRows += r.concepts.length;
  }
  sw.stop();
  final totalUs = sw.elapsedMicroseconds;
  return _BenchResult(
    totalMs: sw.elapsedMilliseconds,
    avgUs: totalUs / iterations,
    totalRows: totalRows,
  );
}

/// Full benchmark that simulates real allocation work (materializing objects)
_BenchResult _benchmarkFull(Lexicor lex, String word, int iterations) {
  final sw = Stopwatch()..start();
  var totalRows = 0;
  for (var i = 0; i < iterations; i++) {
    final r = lex.lookup(word);
    // simulate some processing per concept
    for (final c in r.concepts) {
      // small allocation to mimic app work
      final map = {'id': c.id, 'pos': c.pos.id, 'domain': c.domain.id};
      totalRows++;
      // avoid optimizing away
      if (map.isEmpty) stdout.write('');
    }
  }
  sw.stop();
  final totalUs = sw.elapsedMicroseconds;
  return _BenchResult(
    totalMs: sw.elapsedMilliseconds,
    avgUs: totalUs / iterations,
    totalRows: totalRows,
  );
}

class _BenchResult {
  final int totalMs;
  final double avgUs;
  final int totalRows;

  _BenchResult({required this.totalMs, required this.avgUs, required this.totalRows});
}

void printBanner(String text) {
  print('');
  print('==============================');
  print('  $text');
  print('==============================\n');
}

void printSection(String title) {
  print('\n--- $title ---');
}
