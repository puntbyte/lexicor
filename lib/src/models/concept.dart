// lib/src/models/concept.dart

import 'package:lexicor/src/enums/domain_category.dart';
import 'package:lexicor/src/enums/speech_part.dart';

/// Represents a semantic concept (WordNet synset).
///
/// This is an abstract interface. The internal implementation holds the
/// database ID, which is hidden from the public API to ensure encapsulation.
abstract class Concept {
  /// The part of speech for this concept (e.g., Noun, Verb).
  SpeechPart get part;

  /// The domain category of the concept (e.g., `noun.food`, `verb.motion`).
  DomainCategory get category;
}
