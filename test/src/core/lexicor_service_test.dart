// test/src/core/lexicor_service_test.dart

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../../utils/test_db.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  LexicorService makeService({bool withSamples = false, bool withDefinitions = false}) {
    final db = createTestDatabase(withSamples: withSamples);
    return LexicorService(db, withDefinitions: withDefinitions);
  }

  // ---------------------------------------------------------------------------
  // Lookup
  // ---------------------------------------------------------------------------
  group('lookup', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('returns results for an exact match', () {
      final result = service.lookup('run');
      expect(result.query, 'run');
      expect(result.concepts, isNotEmpty);
      expect(result.concepts.first.part, SpeechPart.verb);
    });

    test('resolves morphology — ran → run', () {
      final result = service.lookup('ran');
      expect(result.resolvedForms, contains('run'));
      expect(result.concepts, isNotEmpty);
      expect(result.concepts.any((c) => (c as ConceptImpl).id == 100), isTrue);
    });

    test('returns empty for an unknown word', () {
      final result = service.lookup('xyz');
      expect(result.isEmpty, isTrue);
      expect(result.resolvedForms, equals(['xyz']));
    });

    test('caches results — second call does not hit the DB', () {
      // Call twice; if caching is broken this can expose a dispose issue.
      final r1 = service.lookup('run');
      final r2 = service.lookup('run');
      expect(identical(r1, r2), isTrue, reason: 'Should return the cached instance');
    });
  });

  // ---------------------------------------------------------------------------
  // lookupBatch
  // ---------------------------------------------------------------------------
  group('lookupBatch', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('returns a result for every requested word', () {
      final results = service.lookupBatch(['run', 'sprint', 'xyz']);
      expect(results.keys, containsAll(['run', 'sprint', 'xyz']));
      expect(results['run']!.isNotEmpty, isTrue);
      expect(results['xyz']!.isEmpty, isTrue);
    });

    test('repeated words are served from cache', () {
      final batch = service.lookupBatch(['run', 'run', 'sprint']);
      // Both 'run' entries should be the same cached instance.
      expect(identical(batch['run'], service.lookup('run')), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getRelated
  // ---------------------------------------------------------------------------
  group('getRelated', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('returns semantic hypernym', () {
      final concept = service.lookup('run').concepts.first;
      final relations = service.getRelated(concept);
      final hypernym = relations.firstWhere((r) => r.type == RelationType.hypernym);
      expect(hypernym.word, 'move');
      expect(hypernym.isSemantic, isTrue);
    });

    test('filters by type in SQL — returns only requested type', () {
      final concept = service.lookup('run').concepts.first;
      final only = service.getRelated(concept, RelationType.hypernym);
      expect(only, isNotEmpty);
      expect(only.every((r) => r.type == RelationType.hypernym), isTrue);
    });

    test('returns lexical antonym', () {
      final concept = service.lookup('fast').concepts.first;
      final rels = service.getRelated(concept, RelationType.antonym);
      expect(rels, isNotEmpty);
      expect(rels.first.word, 'slow');
      expect(rels.first.isSemantic, isFalse);
    });

    test('depth is always 1 for direct relations', () {
      final concept = service.lookup('run').concepts.first;
      final rels = service.getRelated(concept);
      expect(rels.every((r) => r.depth == 1), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // synonyms
  // ---------------------------------------------------------------------------
  group('getSynonyms', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('returns all words in the same synset', () {
      // synset 100 contains 'run' (word 1) and 'jog' (word 7)
      final concept = service.lookup('run').concepts.first;
      final syns = service.getSynonyms(concept);
      expect(syns, containsAll(['run', 'jog']));
    });

    test('returns at least the word itself', () {
      final concept = service.lookup('move').concepts.first;
      final syns = service.getSynonyms(concept);
      expect(syns, contains('move'));
    });
  });

  // ---------------------------------------------------------------------------
  // traverse
  // ---------------------------------------------------------------------------
  group('traverse', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('walks hypernym chain and returns correct depths', () {
      // run(100) --hypernym--> move(101) --hypernym--> locomote(103)
      final concept = service.lookup('run').concepts.first;
      final chain = service.traverse(concept, RelationType.hypernym, maxDepth: 5);

      final words = chain.map((r) => r.word).toList();
      expect(words, containsAll(['move', 'locomote']));

      final moveEntry = chain.firstWhere((r) => r.word == 'move');
      final locomoteEntry = chain.firstWhere((r) => r.word == 'locomote');
      expect(moveEntry.depth, 1);
      expect(locomoteEntry.depth, 2);
    });

    test('respects maxDepth — stops at the specified level', () {
      final concept = service.lookup('run').concepts.first;
      final chain = service.traverse(concept, RelationType.hypernym, maxDepth: 1);
      expect(chain.every((r) => r.depth <= 1), isTrue);
      // Should not reach locomote at depth 2
      expect(chain.any((r) => r.word == 'locomote'), isFalse);
    });

    test('all results have isSemantic = true', () {
      final concept = service.lookup('run').concepts.first;
      final chain = service.traverse(concept, RelationType.hypernym);
      expect(chain.every((r) => r.isSemantic), isTrue);
    });

    test('throws ArgumentError for non-recursive relation type', () {
      final concept = service.lookup('run').concepts.first;
      expect(
            () => service.traverse(concept, RelationType.antonym),
        throwsArgumentError,
      );
    });

    test('returns empty list when no relations exist', () {
      // locomote(103) has no further hypernyms in test data
      final concept = service.lookup('locomote').concepts.first;
      final chain = service.traverse(concept, RelationType.hypernym);
      expect(chain, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // examples (full DB path)
  // ---------------------------------------------------------------------------
  group('getExamples', () {
    test('returns empty list when withDefinitions is false (light DB)', () {
      final service = makeService();
      addTearDown(service.close);
      final concept = service.lookup('run').concepts.first;
      expect(service.getExamples(concept), isEmpty);
    });

    test('returns usage sentences when withDefinitions is true (full DB)', () {
      final service = makeService(withSamples: true, withDefinitions: true);
      addTearDown(service.close);
      final concept = service.lookup('run').concepts.first;
      final examples = service.getExamples(concept);
      expect(examples, isNotEmpty);
      expect(examples, contains('she ran to catch the bus'));
    });
  });

  // ---------------------------------------------------------------------------
  // definitions
  // ---------------------------------------------------------------------------
  group('definitions', () {
    test('concept.definition is null in light mode', () {
      final service = makeService();
      addTearDown(service.close);
      final concept = service.lookup('run').concepts.first;
      expect(concept.definition, isNull);
    });

    test('concept.definition is populated in full mode', () {
      final service = makeService(withDefinitions: true);
      addTearDown(service.close);
      final concept = service.lookup('run').concepts.first;
      expect(concept.definition, isNotNull);
      expect(concept.definition, contains('feet'));
    });
  });

  // ---------------------------------------------------------------------------
  // lemmatize
  // ---------------------------------------------------------------------------
  group('lemmatize', () {
    late LexicorService service;
    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('returns base form for known inflection', () {
      expect(service.lemmatize('ran', SpeechPart.verb), 'run');
    });

    test('returns original word when no mapping exists', () {
      expect(service.lemmatize('run', SpeechPart.verb), 'run');
    });
  });

  // ---------------------------------------------------------------------------
  // Invalid concept guard
  // ---------------------------------------------------------------------------
  group('invalid concept', () {
    late LexicorService service;

    setUp(() => service = makeService());
    tearDown(() => service.close());

    test('getRelated throws for non-ConceptImpl', () {
      expect(
            () => service.getRelated(_FakeConcept()),
        throwsArgumentError,
      );
    });
  });
}

/// A stub [Concept] that is NOT a [ConceptImpl], used to test the guard clause.
class _FakeConcept implements Concept {
  @override
  SpeechPart get part => SpeechPart.noun;
  @override
  DomainCategory get category => DomainCategory.nounTops;
  @override
  String? get definition => null;
}