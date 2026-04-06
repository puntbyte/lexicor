// lib/src/models/related_word.dart

import 'package:lexicor/src/core/lexicor.dart';
import 'package:lexicor/src/enums/relation_type.dart';

/// Represents a word related to a specific concept, optionally at a traversal depth.
class RelatedWord {
  /// The text of the related word.
  final String word;

  /// The type of relationship (e.g., [RelationType.hypernym], [RelationType.antonym]).
  final RelationType type;

  /// Whether this relationship is Semantic (Concept-to-Concept) or Lexical (Word-to-Word).
  ///
  /// * **Semantic**: Links meanings (e.g., "Car" is a kind of "Vehicle").
  /// * **Lexical**: Links word forms (e.g., "good" is the antonym of "bad").
  final bool isSemantic;

  /// How many hops away this word is from the origin concept.
  ///
  /// Always `1` for results from [Lexicor.related]. Greater than `1` only for
  /// results from [Lexicor.traverse], which walks the hierarchy recursively.
  final int depth;

  /// Create a new [RelatedWord].
  const RelatedWord({
    required this.word,
    required this.type,
    required this.isSemantic,
    this.depth = 1,
  });

  @override
  String toString() => 'RelatedWord($word, ${type.label}, semantic: $isSemantic, depth: $depth)';
}
