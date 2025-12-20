// lib/src/models/related_word.dart

import 'package:lexicor/src/enums/relation_type.dart';
import 'package:meta/meta.dart';

/// Represents a single related word returned by relation queries.
///
/// [word] is the lexical form (string), [relation] is the [RelationType], and
/// [isSemantic] indicates whether the relation is semantic (true, e.g. a
/// synset-to-synset link) or lexical (false, e.g. word-to-word).
@immutable
class RelatedWord {
  /// The related word text.
  final String word;

  /// The relation type (hypernym, antonym, etc).
  final RelationType relation;

  /// True if the relation is semantic (concept-level), false if lexical.
  final bool isSemantic;

  /// Create a new [RelatedWord].
  const RelatedWord({
    required this.word,
    required this.relation,
    required this.isSemantic,
  });

  @override
  String toString() =>
      'RelatedWord(word: $word, relation: ${relation.name}, isSemantic: $isSemantic)';
}
