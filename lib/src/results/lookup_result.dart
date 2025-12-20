// lib/src/results/lookup_result.dart

import 'package:lexicor/src/core/lexicor.dart';
import 'package:lexicor/src/enums/domain_category.dart';
import 'package:lexicor/src/enums/part_of_speech.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:meta/meta.dart';

/// Result wrapper returned by [Lexicor.lookup].
///
/// Contains the original query, the morphological forms tried (original first),
/// and the ordered, deduplicated list of `Concept`s found.
@immutable
class LookupResult extends Iterable<Concept> {
  /// Original query text passed to [Lexicor.lookup].
  final String query;

  /// Morphological forms that were tried, with the original form first.
  final List<String> resolvedForms;

  /// Ordered, deduplicated `Concept` objects for the query.
  final List<Concept> concepts;

  /// Create a new [LookupResult].
  const LookupResult({
    required this.query,
    required this.resolvedForms,
    required this.concepts,
  });

  @override
  Iterator<Concept> get iterator => concepts.iterator;

  /// `true` when no concepts were found.
  @override
  bool get isEmpty => concepts.isEmpty;

  /// `true` when one or more concepts were found.
  @override
  bool get isNotEmpty => concepts.isNotEmpty;

  /// The primary (first) concept, or `null` when none exist.
  Concept? get primary => concepts.isEmpty ? null : concepts.first;

  /// Return concepts matching [pos].
  List<Concept> byPos(PartOfSpeech pos) => concepts.where((c) => c.pos == pos).toList();

  /// Return concepts matching [domain].
  List<Concept> byDomain(DomainCategory domain) =>
      concepts.where((c) => c.domain == domain).toList();

  /// Convenience: all verb concepts.
  List<Concept> get verbs => byPos(PartOfSpeech.verb);

  /// Convenience: all noun concepts.
  List<Concept> get nouns => byPos(PartOfSpeech.noun);

  /// Group concepts by part-of-speech.
  Map<PartOfSpeech, List<Concept>> groupByPos() {
    final map = <PartOfSpeech, List<Concept>>{};
    for (final c in concepts) {
      map.putIfAbsent(c.pos, () => []).add(c);
    }
    return map;
  }

  /// Group concepts by domain.
  Map<DomainCategory, List<Concept>> groupByDomain() {
    final map = <DomainCategory, List<Concept>>{};
    for (final c in concepts) {
      map.putIfAbsent(c.domain, () => []).add(c);
    }
    return map;
  }

  /// Return the concept ids in order.
  List<int> ids() => concepts.map((c) => c.id).toList();

  /// Create a copy with modified fields.
  LookupResult copyWith({
    String? query,
    List<String>? resolvedForms,
    List<Concept>? concepts,
  }) {
    return LookupResult(
      query: query ?? this.query,
      resolvedForms: resolvedForms ?? this.resolvedForms,
      concepts: concepts ?? this.concepts,
    );
  }

  @override
  String toString() => 'LookupResult(query: $query, concepts: ${concepts.length})';
}
