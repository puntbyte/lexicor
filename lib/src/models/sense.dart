// lib/src/models/sense.dart

import 'package:lexicor/lexicor.dart';
import 'package:meta/meta.dart';

/// A single row from the `sense` table: a link between a [Word] and a
/// [Concept] (synset).
///
/// `Sense` instances are tiny, immutable data holders used internally and in
/// tests.
@immutable
class Sense {
  /// Primary key of the sense row.
  final int id;

  /// The word id (references `word.id`).
  final int wordId;

  /// The concept id (synset id) this sense belongs to.
  final int conceptId;

  /// The sort order for the sense (WordNet sense ordering).
  final int sortOrder;

  /// Create a new [Sense].
  const Sense({
    required this.id,
    required this.wordId,
    required this.conceptId,
    required this.sortOrder,
  });

  @override
  String toString() =>
      'Sense(id: $id, wordId: $wordId, conceptId: $conceptId, sortOrder: $sortOrder)';
}
