// lib/src/enums/speech_part.dart

/// Part-of-speech used by Lexicor.
///
/// Each enum value maps to a single-character id used in WordNet-style datasets and includes a
/// human-friendly label. These are the basic parts of speech you'll encounter when working with
/// meanings/concepts.
enum SpeechPart {
  /// Words that describe qualities or attributes (e.g. "big", "happy", "blue").
  adjective('a', 'adjective'),

  /// Words that name people, places, things, ideas, or events (e.g. "car", "city", "happiness").
  noun('n', 'noun'),

  /// Words that modify verbs, adjectives, or other adverbs (e.g. "quickly", "very").
  adverb('r', 'adverb'),

  /// Special adjective forms closely linked to a head adjective (used in WordNet for some
  /// adjective groupings).
  adjectiveSatellite('s', 'adjective satellite'),

  /// Action or state words (e.g. "run", "be", "think").
  verb('v', 'verb')
  ;

  /// The single-character ID stored in the database.
  final String id;

  /// A human-readable label.
  final String label;

  const SpeechPart(this.id, this.label);

  // O(1) Lookup Map
  static final Map<String, SpeechPart> _byId = {
    for (var part in SpeechPart.values) part.id: part,
  };

  /// Look up the enum by its database ID.
  ///
  /// Throws [ArgumentError] if the id is unknown.
  static SpeechPart fromId(String id) {
    final result = _byId[id];
    if (result == null) throw ArgumentError('Unknown POS ID: $id');
    return result;
  }

  /// Convenience: accept dynamic DB values (int/string) and convert.
  static SpeechPart fromDbValue(dynamic dbValue) {
    if (dbValue == null) throw ArgumentError('POS db value is null');
    return fromId(dbValue.toString());
  }

  @override
  String toString() => 'PartOfSpeech(label: $label)';
}
