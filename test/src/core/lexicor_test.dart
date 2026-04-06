// test/src/core/lexicor_test.dart

import 'dart:io';

import 'package:lexicor/lexicor.dart';
import 'package:test/test.dart';

/// Integration tests against the real packaged SQLite assets.
///
/// These tests are skipped automatically when the database files have not been
/// built yet (run `melos run build:all` first). A proper `markTestSkipped`
/// call ensures CI reports them as skipped rather than silently passing.
void main() {
  // Paths are relative to the project root, which is where `dart test` runs.
  const lightDbPath = 'lib/assets/dictionary.sqlite';
  const fullDbPath = 'lib/assets/dictionary_full.sqlite';

  // ---------------------------------------------------------------------------
  // Light database (no definitions)
  // ---------------------------------------------------------------------------
  group('Lexicor — light DB', () {
    test('init onDisk succeeds and basic lookup works', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(
        mode: StorageMode.onDisk,
        customPath: file.path,
      );
      addTearDown(lexicor.close);

      final result = lexicor.lookup('run');
      expect(result.concepts, isNotEmpty);
      expect(
        result.concepts.first.definition,
        isNull,
        reason: 'Light DB should not populate definition',
      );
    });

    test('init inMemory succeeds', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(
        mode: StorageMode.inMemory,
        customPath: file.path,
      );
      addTearDown(lexicor.close);

      expect(lexicor.lookup('run').isNotEmpty, isTrue);
    });

    test('lemmatize resolves inflections', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(customPath: file.path);
      addTearDown(lexicor.close);

      expect(lexicor.lemmatize('ran', SpeechPart.verb), 'run');
      expect(lexicor.lemmatize('better', SpeechPart.adjective), 'good');
    });

    test('synonyms returns words from the same synset', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(customPath: file.path);
      addTearDown(lexicor.close);

      final result = lexicor.lookup('car');
      if (result.isEmpty) return; // word may differ across OEWN versions

      final syns = lexicor.synonyms(result.primary!);
      expect(syns, isNotEmpty);
      // All synonym words should be non-empty strings
      expect(syns.every((w) => w.isNotEmpty), isTrue);
    });

    test('traverse walks hypernym chain', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(customPath: file.path);
      addTearDown(lexicor.close);

      final result = lexicor.lookup('dog');
      if (result.isEmpty) return;

      final chain = lexicor.traverse(result.primary!, RelationType.hypernym, maxDepth: 3);
      expect(chain, isNotEmpty);
      // Depth should be ordered 1 → maxDepth
      expect(chain.first.depth, 1);
      expect(chain.every((r) => r.depth >= 1), isTrue);
    });

    test('examples returns empty list in light mode', () async {
      final file = File(lightDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$lightDbPath not found — run `melos run build` first.');
        return;
      }

      final lexicor = await Lexicor.init(customPath: file.path);
      addTearDown(lexicor.close);

      final result = lexicor.lookup('run');
      if (result.isEmpty) return;

      expect(lexicor.examples(result.primary!), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Full database (with definitions + examples)
  // ---------------------------------------------------------------------------
  group('Lexicor — full DB', () {
    test('init with withDefinitions: true populates concept.definition', () async {
      final file = File(fullDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$fullDbPath not found — run `melos run build:full` first.');
        return;
      }

      final lexicor = await Lexicor.init(
        withDefinitions: true,
        customPath: file.path,
      );
      addTearDown(lexicor.close);

      final result = lexicor.lookup('run');
      expect(result.isNotEmpty, isTrue);
      expect(result.primary!.definition, isNotNull);
      expect(result.primary!.definition, isNotEmpty);
    });

    test('examples returns usage sentences in full mode', () async {
      final file = File(fullDbPath);
      if (!file.existsSync()) {
        markTestSkipped('$fullDbPath not found — run `melos run build:full` first.');
        return;
      }

      final lexicor = await Lexicor.init(
        withDefinitions: true,
        customPath: file.path,
      );
      addTearDown(lexicor.close);

      // Not all synsets have examples, so we look for a word known to have some.
      final result = lexicor.lookup('run');
      if (result.isEmpty) return;

      // At least one concept for 'run' should have examples.
      final hasExamples = result.concepts.any((c) => lexicor.examples(c).isNotEmpty);
      expect(hasExamples, isTrue);
    });
  });
}
