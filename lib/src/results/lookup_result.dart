// lib/src/results/lookup_result.dart

import 'package:lexicor/lexicor.dart';
import 'package:meta/meta.dart';

/// Result wrapper returned by [Lexicor.lookup].
///
/// Contains the original query, the morphological forms tried (original first), and the ordered,
/// deduplicated list of `Concept`s found.
@immutable
class LookupResult {
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

  /// `true` when no concepts were found.
  bool get isEmpty => concepts.isEmpty;

  /// `true` when one or more concepts were found.
  bool get isNotEmpty => concepts.isNotEmpty;

  /// The primary (first) concept, or `null` when none exist.
  Concept? get primary => concepts.isEmpty ? null : concepts.first;

  /// Return concepts matching [part].
  List<Concept> bySpeechPart(SpeechPart part) =>
      concepts.where((concept) => concept.part == part).toList();

  /// Return concepts matching [category].
  List<Concept> byDomainCategory(DomainCategory category) =>
      concepts.where((concept) => concept.category == category).toList();

  /// Group concepts by part-of-speech.
  Map<SpeechPart, List<Concept>> groupByPos() {
    final map = <SpeechPart, List<Concept>>{};
    for (final concept in concepts) {
      map.putIfAbsent(concept.part, () => []).add(concept);
    }
    return map;
  }

  /// Group concepts by domain.
  Map<DomainCategory, List<Concept>> groupByDomain() {
    final map = <DomainCategory, List<Concept>>{};
    for (final concept in concepts) {
      map.putIfAbsent(concept.category, () => []).add(concept);
    }
    return map;
  }

  @override
  String toString() => 'LookupResult(query: $query, concepts: ${concepts.length})';
}
