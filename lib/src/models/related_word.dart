// lib/src/models/related_word.dart

import 'package:lexicor/src/enums/relation_type.dart';

/// Represents a word related to a specific concept.
class RelatedWord {
  /// The text of the related word.
  final String word;

  /// The type of relationship (e.g., Hypernym, Antonym).
  final RelationType type;

  /// Whether this relationship is Semantic (Concept-to-Concept) or Lexical (Word-to-Word).
  ///
  /// * **Semantic**: Links the meaning (e.g., "Car" is a "Vehicle").
  /// * **Lexical**: Links the specific word form (e.g., "Good" is opposite of "Bad").
  final bool isSemantic;

  /// Create a new [RelatedWord].
  const RelatedWord({
    required this.word,
    required this.type,
    required this.isSemantic,
  });

  @override
  String toString() => 'RelatedWord($word, ${type.label}, semantic: $isSemantic)';
}
