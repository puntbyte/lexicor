// lib/src/results/relation_result.dart

import 'package:lexicor/lexicor.dart';
import 'package:meta/meta.dart';

/// Wrapper for related-word results for a concept.
@immutable
class RelationResult {
  /// The returned related words (semantic + lexical).
  final List<RelatedWord> items;

  /// Create a new [RelationResult].
  const RelationResult(this.items);

  /// Returns true if no related words were found.
  bool get isEmpty => items.isEmpty;

  /// Returns true if one or more related words were found.
  bool get isNotEmpty => items.isNotEmpty;

  /// Returns a list filtered by a specific relationship type.
  List<RelatedWord> byType(RelationType type) =>
      items.where((word) => word.type == type).toList();

  /// Filters the results to only semantic relations (Concept-to-Concept).
  List<RelatedWord> get semantic => items.where((word) => word.isSemantic).toList();

  /// Filters the results to only lexical relations (Word-to-Word).
  List<RelatedWord> get lexical => items.where((word) => !word.isSemantic).toList();

  /// Extract distinct words preserving insertion order.
  List<String> words({bool distinct = true}) {
    if (!distinct) return items.map((r) => r.word).toList();
    final seen = <String>{};
    final out = <String>[];
    for (final r in items) {
      if (seen.add(r.word)) out.add(r.word);
    }
    return out;
  }

  /// Remove duplicate pairs and preserve order.
  List<RelatedWord> unique() {
    final seen = <String>{};
    final out = <RelatedWord>[];
    for (final r in items) {
      final key = '${r.word}|${r.type.id}';
      if (seen.add(key)) out.add(r);
    }
    return out;
  }

  @override
  String toString() => 'RelationResult(items: ${items.length})';
}
