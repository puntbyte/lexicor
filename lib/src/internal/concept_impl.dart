// lib/src/internal/concept_impl.dart

import 'package:lexicor/lexicor.dart';
import 'package:meta/meta.dart';

/// Internal implementation of [Concept] that holds the Database ID.
///
/// This class is NOT exported in `lexicor.dart`, so users cannot see it
/// or instantiate it. Only the `LexicorService` uses this.
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
