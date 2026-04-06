// lib/src/models/concept.dart

import 'package:lexicor/src/core/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:lexicor/src/enums/domain_category.dart';
import 'package:lexicor/src/enums/speech_part.dart';
import 'package:meta/meta.dart';

/// Represents a semantic concept (WordNet synset).
///
/// Obtain instances via [Lexicor.lookup] — do not instantiate directly.
abstract class Concept {
  /// The part of speech for this concept (e.g., Noun, Verb).
  SpeechPart get part;

  /// The domain category of the concept (e.g., `noun.food`, `verb.motion`).
  DomainCategory get category;

  /// The synset definition (gloss), or `null` when the package was initialised
  /// without definitions (the default).
  ///
  /// Enable definitions at init time:
  /// ```dart
  /// final lexicor = await Lexicor.init(withDefinitions: true);
  /// final concept = lexicor.lookup('bank').primary!;
  /// print(concept.definition); // "a financial institution..."
  /// ```
  String? get definition;
}

/// Internal implementation of [Concept] that carries the database synset ID.
///
/// Not exported from `lexicor.dart`. Only [LexicorService] creates instances.
@internal
@immutable
class ConceptImpl implements Concept {
  final int id;

  @override
  final SpeechPart part;

  @override
  final DomainCategory category;

  @override
  final String? definition;

  const ConceptImpl({
    required this.id,
    required this.part,
    required this.category,
    this.definition,
  });

  @override
  String toString() {
    final defPreview = definition != null
        ? ', def: "${definition!.substring(0, definition!.length.clamp(0, 40))}…"'
        : '';
    return 'Concept(id: $id, pos: ${part.label}, domain: ${category.label}$defPreview)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptImpl && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
