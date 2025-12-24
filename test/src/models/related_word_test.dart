import 'package:lexicor/lexicor.dart';
import 'package:test/test.dart';

void main() {
  group('RelatedWord', () {
    test('instantiation stores correct values', () {
      const related = RelatedWord(
        word: 'fast',
        type: RelationType.antonym,
        isSemantic: false,
      );

      expect(related.word, 'fast');
      expect(related.type, RelationType.antonym);
      expect(related.isSemantic, isFalse);
    });

    test('toString returns formatted string', () {
      const related = RelatedWord(
        word: 'animal',
        type: RelationType.hypernym,
        isSemantic: true,
      );

      expect(
        related.toString(),
        'RelatedWord(animal, hypernym, semantic: true)',
      );
    });
  });
}
