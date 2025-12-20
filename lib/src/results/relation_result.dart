// lib/src/results/relation_result.dart

import 'package:lexicor/src/enums/relation_type.dart';
import 'package:lexicor/src/models/related_word.dart';
import 'package:meta/meta.dart';

/// Wrapper for related-word results for a concept.
@immutable
class RelationResult extends Iterable<RelatedWord> {
  /// The source concept id for which relations were fetched.
  final int conceptId;

  /// The returned related words (semantic + lexical).
  final List<RelatedWord> items;

  /// Create a new [RelationResult].
  const RelationResult({
    required this.conceptId,
    required this.items,
  });

  @override
  Iterator<RelatedWord> get iterator => items.iterator;

  @override
  bool get isEmpty => items.isEmpty;

  @override
  bool get isNotEmpty => items.isNotEmpty;

  /// Filter by relationship [type].
  List<RelatedWord> withRelation(RelationType type) =>
      items.where((r) => r.relation == type).toList();

  /// Only semantic relations.
  List<RelatedWord> semantic() => items.where((r) => r.isSemantic).toList();

  /// Only lexical relations.
  List<RelatedWord> lexical() => items.where((r) => !r.isSemantic).toList();

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
      final key = '${r.word}|${r.relation.id}';
      if (seen.add(key)) out.add(r);
    }
    return out;
  }

  /// Create a copy of this [RelationResult] with the given fields changed.
  RelationResult copyWith({int? conceptId, List<RelatedWord>? items}) => RelationResult(
    conceptId: conceptId ?? this.conceptId,
    items: items ?? this.items,
  );

  @override
  String toString() => 'RelationResult(conceptId: $conceptId, items: ${items.length})';
}
