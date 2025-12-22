// lib/src/models/concept.dart

import 'package:lexicor/src/enums/domain_category.dart';
import 'package:lexicor/src/enums/speech_part.dart';
import 'package:meta/meta.dart';

/// Represents a semantic concept (WordNet synset).
///
/// This is an abstract interface.
abstract class Concept {
  /// The part of speech for this concept (e.g., Noun, Verb).
  SpeechPart get part;

  /// The domain category of the concept (e.g., `noun.food`, `verb.motion`).
  DomainCategory get category;
}

/// Internal implementation of [Concept] that holds the Database ID.
///
/// This class is NOT exported in `lexicor.dart`, so users cannot see it or instantiate it. Only
/// the `LexicorService` uses this.
@internal
@immutable
class ConceptImpl implements Concept {
  /// The private database primary key.
  final int id;

  @override
  final SpeechPart part;

  @override
  final DomainCategory category;

  /// Create a new [ConceptImpl].
  const ConceptImpl({
    required this.id,
    required this.part,
    required this.category,
  });

  @override
  String toString() => 'Concept(id: $id, pos: ${part.label}, domain: ${category.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptImpl && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
