import 'package:lexicor/lexicor.dart';
import 'package:test/test.dart';

void main() {
  group('RelationResult', () {
    const r1 = RelatedWord(word: 'dog', type: RelationType.hyponym, isSemantic: true);
    const r2 = RelatedWord(word: 'cat', type: RelationType.hyponym, isSemantic: true);
    const r3 = RelatedWord(word: 'animal', type: RelationType.hypernym, isSemantic: true);
    const r4 = RelatedWord(word: 'good', type: RelationType.antonym, isSemantic: false);
    // Duplicate entry for unique testing
    const r5 = RelatedWord(word: 'dog', type: RelationType.hyponym, isSemantic: true);

    const result = RelationResult([r1, r2, r3, r4, r5]);

    test('isEmpty / isNotEmpty', () {
      expect(result.isNotEmpty, isTrue);
      expect(const RelationResult([]).isEmpty, isTrue);
    });

    test('byType filters correctly', () {
      final hyponyms = result.byType(RelationType.hyponym);
      expect(hyponyms, containsAll([r1, r2, r5]));
      expect(hyponyms.length, 3);

      final antonyms = result.byType(RelationType.antonym);
      expect(antonyms, [r4]);
    });

    test('semantic filters semantic relations', () {
      final semantic = result.semantic;
      expect(semantic, containsAll([r1, r2, r3, r5]));
      expect(semantic.any((r) => r.word == 'good'), isFalse);
    });

    test('lexical filters lexical relations', () {
      final lexical = result.lexical;
      expect(lexical, [r4]);
    });

    test('words returns list of strings', () {
      // Default distinct = true
      expect(result.words(), ['dog', 'cat', 'animal', 'good']);

      // distinct = false
      expect(result.words(distinct: false), ['dog', 'cat', 'animal', 'good', 'dog']);
    });

    test('unique removes duplicates based on word+type', () {
      final uniqueItems = result.unique();

      // r5 is identical to r1, so it should be removed
      expect(uniqueItems.length, 4);
      expect(uniqueItems, containsAll([r1, r2, r3, r4]));
    });
  });
}
