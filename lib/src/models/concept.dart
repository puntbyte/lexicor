// lib/src/models/concept.dart

import 'package:meta/meta.dart';
import 'package:lexicor/src/enums/part_of_speech.dart';
import 'package:lexicor/src/enums/domain_category.dart';

/// Represents a semantic concept (WordNet synset) returned by lookups.
///
/// A `Concept` is a small, immutable model containing the numeric [id] of the
/// synset, the [PartOfSpeech], and the domain category.
@immutable
class Concept {
  /// Numeric synset/concept id from the database.
  final int id;

  /// Part of speech for the concept (noun, verb, etc).
  final PartOfSpeech pos;

  /// Domain category of the concept (e.g. `noun.food`).
  final DomainCategory domain;

  /// Create a new [Concept].
  const Concept({
    required this.id,
    required this.pos,
    required this.domain,
  });

  @override
  String toString() => 'Concept(id: $id, pos: ${pos.name}, domain: ${domain.label})';
}
