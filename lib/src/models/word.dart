// lib/src/models/word.dart

import 'package:meta/meta.dart';

/// Represents a word (lemma) row from the `word` table.
///
/// This is a small, immutable model used by lookups and tests.
@immutable
class Word {
  /// Primary key id of the word.
  final int id;

  /// The textual form stored in the DB.
  final String text;

  /// Create a new [Word].
  const Word({required this.id, required this.text});

  @override
  String toString() => 'Word(id: $id, text: $text)';
}
