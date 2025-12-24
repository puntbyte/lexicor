import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:test/test.dart';

void main() {
  group('Concept', () {
    test('instantiation stores correct values', () {
      const concept = ConceptImpl(
        id: 123,
        part: SpeechPart.noun,
        category: DomainCategory.nounFood,
      );

      expect(concept.id, 123);
      expect(concept.part, SpeechPart.noun);
      expect(concept.category, DomainCategory.nounFood);
    });

    test('equality is based on ID', () {
      const conceptA = ConceptImpl(
        id: 100,
        part: SpeechPart.verb,
        category: DomainCategory.verbMotion,
      );

      // conceptB has same ID, should be equal
      const conceptB = ConceptImpl(
        id: 100,
        part: SpeechPart.verb,
        category: DomainCategory.verbMotion,
      );

      // conceptC has different ID
      const conceptC = ConceptImpl(
        id: 101,
        part: SpeechPart.verb,
        category: DomainCategory.verbMotion,
      );

      expect(conceptA, equals(conceptB));
      expect(conceptA.hashCode, equals(conceptB.hashCode));

      expect(conceptA, isNot(equals(conceptC)));
    });

    test('toString returns formatted string', () {
      const concept = ConceptImpl(
        id: 55,
        part: SpeechPart.adjective,
        category: DomainCategory.adjAll,
      );

      expect(
        concept.toString(),
        'Concept(id: 55, pos: adjective, domain: adj.all)',
      );
    });
  });
}
