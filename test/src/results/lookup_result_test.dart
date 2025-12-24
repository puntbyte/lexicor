import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:test/test.dart';

void main() {
  // Helpers to create concepts quickly
  ConceptImpl create(int id, SpeechPart pos, DomainCategory domain) {
    return ConceptImpl(id: id, part: pos, category: domain);
  }

  group('LookupResult', () {
    final c1 = create(1, SpeechPart.noun, DomainCategory.nounFood);
    final c2 = create(2, SpeechPart.noun, DomainCategory.nounArtifact);
    final c3 = create(3, SpeechPart.verb, DomainCategory.verbConsumption);

    final result = LookupResult(
      query: 'test',
      resolvedForms: const ['test', 'tested'],
      concepts: [c1, c2, c3],
    );

    test('properties are set correctly', () {
      expect(result.query, 'test');
      expect(result.resolvedForms, ['test', 'tested']);
      expect(result.concepts, [c1, c2, c3]);
    });

    test('isEmpty / isNotEmpty', () {
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);

      const empty = LookupResult(query: '', resolvedForms: [], concepts: []);
      expect(empty.isEmpty, isTrue);
    });

    test('primary returns the first concept or null', () {
      expect(result.primary, c1);

      const empty = LookupResult(query: '', resolvedForms: [], concepts: []);
      expect(empty.primary, isNull);
    });

    test('bySpeechPart filters correctly', () {
      final nouns = result.bySpeechPart(SpeechPart.noun);
      expect(nouns, [c1, c2]);

      final verbs = result.bySpeechPart(SpeechPart.verb);
      expect(verbs, [c3]);

      final adjs = result.bySpeechPart(SpeechPart.adjective);
      expect(adjs, isEmpty);
    });

    test('byDomainCategory filters correctly', () {
      final food = result.byDomainCategory(DomainCategory.nounFood);
      expect(food, [c1]);
    });

    test('groupByPos returns correct map', () {
      final groups = result.groupByPos();

      expect(groups.keys, containsAll([SpeechPart.noun, SpeechPart.verb]));
      expect(groups[SpeechPart.noun], [c1, c2]);
      expect(groups[SpeechPart.verb], [c3]);
    });

    test('groupByDomain returns correct map', () {
      final groups = result.groupByDomain();

      expect(groups[DomainCategory.nounFood], [c1]);
      expect(groups[DomainCategory.nounArtifact], [c2]);
      expect(groups[DomainCategory.verbConsumption], [c3]);
    });
  });
}
