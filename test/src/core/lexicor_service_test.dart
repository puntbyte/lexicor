import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../../utils/test_db.dart';

void main() {
  late Database db;
  late LexicorService service;

  setUp(() {
    db = createTestDatabase();
    service = LexicorService(db);
  });

  tearDown(() {
    service.close();
  });

  group('LexicorService', () {
    test('lookup returns results for exact match', () {
      final result = service.lookup('run');

      expect(result.query, 'run');
      expect(result.concepts, isNotEmpty);
      expect(result.concepts.first.part, equals(SpeechPart.verb));
      expect(result.concepts.first.category, equals(DomainCategory.verbBody));
    });

    test('lookup resolves morphology (ran -> run)', () {
      // "ran" is in our test DB linked to morph "run"
      final result = service.lookup('ran');

      expect(result.resolvedForms, contains('run'));
      expect(result.concepts, isNotEmpty);
      // It should find the concept for 'run' (ID 100)
      expect(
        result.concepts.any((c) => (c as ConceptImpl).id == 100),
        isTrue,
        reason: 'Should find the concept ID for "run"',
      );
    });

    test('lookup returns empty for unknown word', () {
      final result = service.lookup('xyz');
      expect(result.isEmpty, isTrue);
      expect(result.resolvedForms, equals(['xyz']));
    });

    test('getRelated returns semantic relationships (Hypernym)', () {
      // Lookup 'run' -> get concept 100
      final lookup = service.lookup('run');
      final concept = lookup.concepts.first;

      final relations = service.getRelated(concept);

      // In setup: Move(101) is Hypernym(1) of Run(100)
      final hypernym = relations.firstWhere((r) => r.type == RelationType.hypernym);

      expect(hypernym.word, 'move');
      expect(hypernym.isSemantic, isTrue);
    });

    test('getRelated returns lexical relationships (Antonym)', () {
      final lookup = service.lookup('fast');
      final concept = lookup.concepts.first;

      final relations = service.getRelated(concept, RelationType.antonym);

      expect(relations, isNotEmpty);
      expect(relations.first.word, 'slow');
      expect(relations.first.isSemantic, isFalse);
    });

    test('getMorphology returns base form', () {
      // Input: 'ran' (Inflection) -> Expect: 'run' (Base)
      final root = service.getMorphology('ran', SpeechPart.verb);
      expect(root, 'run');
    });

    test('getMorphology returns original if no root found', () {
      // Input: 'run' (Already Base, not in morph table as an inflection)
      // -> Expect: 'run' (Fallback)
      final root = service.getMorphology('run', SpeechPart.verb);
      expect(root, 'run');
    });
  });
}
