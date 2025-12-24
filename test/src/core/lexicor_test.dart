// test/lexicor_test.dart

import 'dart:io';
import 'package:lexicor/lexicor.dart';
import 'package:test/test.dart';

void main() {
  group('Lexicor Public API', () {
    // Note: These tests require the actual assets/dictionary.sqlite to exist
    // and be readable in the test environment.

    test('init(inMemory: true) initializes successfully', () async {
      // We assume the test runner runs from project root
      final file = File('lib/assets/dictionary.sqlite');
      if (!file.existsSync()) {
        // Skip if DB isn't built yet (CI/CD safety)
        print('Skipping DB test: lib/assets/dictionary.sqlite not found.');
        return;
      }

      // Use custom path because package: uri resolution might fail in raw test environment
      final lexicor = await Lexicor.init(
        mode: StorageMode.inMemory,
        customPath: file.path,
      );

      expect(lexicor, isNotNull);

      // Basic sanity check
      final result = lexicor.lookup('run');
      expect(result.concepts, isNotEmpty);

      lexicor.close();
    });

    test('API facade forwards calls to service correctly', () async {
      final file = File('lib/assets/dictionary.sqlite');
      if (!file.existsSync()) return;

      final lexicor = await Lexicor.init(
        mode: StorageMode.onDisk,
        customPath: file.path,
      );

      // 1. Lookup
      final result = lexicor.lookup('better');
      expect(result.resolvedForms, contains('good'));

      // 2. Relations
      if (result.isNotEmpty) {
        final rels = lexicor.related(result.primary!);
        expect(rels, isNotNull);
      }

      // 3. Morphology
      final morph = lexicor.morphology('ran', SpeechPart.verb);
      expect(morph, 'run');

      lexicor.close();
    });
  });
}
