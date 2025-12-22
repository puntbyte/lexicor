// lib/src/core/lexicor_service.dart

import 'dart:collection';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/internal/concept_impl.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed service powering Lexicor.
///
/// This class encapsulates prepared statements and the tiny morphology cache. It returns plain
/// model objects and does not perform any I/O beyond queries.
class LexicorService {
  final Database _db;
  final LinkedHashMap<String, List<String>> _morphCache = LinkedHashMap();

  /// Controls the LRU size for cached morphology resolutions.
  final int morphCacheMax;

  /// Create a new service backed by a [Database] instance.
  ///
  /// [morphCacheMax] controls the LRU size for cached morphology resolutions.
  LexicorService(this._db, {this.morphCacheMax = 1024});

  /// Perform a morphology-aware lookup for [word].
  ///
  /// The returned [LookupResult] contains:
  /// - `resolvedForms` (original word first, then base forms),
  /// - `concepts` (ordered, deduplicated `Concept` objects).
  LookupResult lookup(String word) {
    // A. Resolve Morphology (e.g. "running" -> ["running", "run"])
    final forms = _resolveBaseForms(word);

    final concepts = <Concept>[];
    final seenIds = <int>{};

    // B. Prepare Statement
    final statement = _db.prepare('''
      SELECT s.id, s.part_of_speech_id, s.domain_category_id 
      FROM synset s 
      JOIN sense se ON s.id = se.synset_id 
      JOIN word w ON se.word_id = w.id 
      WHERE w.text = ? COLLATE NOCASE 
      ORDER BY se.sense_sort_order ASC
    ''');

    // C. Query for each form
    for (final form in forms) {
      final rows = statement.select([form]);

      for (final row in rows) {
        final id = row['id'] as int;

        // Dedup: If we found this concept via "running", don't add it again via "run"
        if (seenIds.contains(id)) continue;
        seenIds.add(id);

        concepts.add(
          ConceptImpl(
            id: id,
            part: SpeechPart.fromId(row['part_of_speech_id'] as String),
            category: DomainCategory.fromId(row['domain_category_id'] as int),
          ),
        );
      }
    }
    statement.dispose();

    return LookupResult(query: word, resolvedForms: forms, concepts: concepts);
  }

  /// Return related words (lexical + semantic) for [concept].
  ///
  /// If [type] is provided, results are filtered to that [RelationType].
  List<RelatedWord> getRelated(Concept concept, [RelationType? type]) {
    // SECURITY CHECK: Ensure the user passed a valid object we created.
    if (concept is! ConceptImpl) {
      throw ArgumentError(
        'Invalid Concept provided. You must use a Concept object returned by lookup().',
      );
    }

    // Access the hidden ID
    final synsetId = concept.id;

    final statement = _db.prepare('''
      SELECT w.text, rel.relationship_type_id, 1 as is_semantic
      FROM semantic_relationship rel
      JOIN sense target_s ON rel.target_synset_id = target_s.synset_id
      JOIN word w ON target_s.word_id = w.id
      WHERE rel.source_synset_id = ?
      UNION ALL
      SELECT w.text, lex_rel.relationship_type_id, 0 as is_semantic
      FROM sense source_s
      JOIN lexical_relationship lex_rel ON source_s.id = lex_rel.source_sense_id
      JOIN sense target_s ON lex_rel.target_sense_id = target_s.id
      JOIN word w ON target_s.word_id = w.id
      WHERE source_s.synset_id = ?
    ''');

    final results = statement.select([synsetId, synsetId]);
    statement.dispose();

    var list = results.map((row) {
      return RelatedWord(
        word: row['text'] as String,
        type: RelationType.fromId(row['relationship_type_id'] as int),
        isSemantic: (row['is_semantic'] as int) == 1,
      );
    }).toList();

    if (type != null) list = list.where((e) => e.type == type).toList();

    return list;
  }

  /// Return the morphological base form for [word] and [pos], or [word] if none.
  String getMorphology(String word, SpeechPart pos) {
    final statement = _db.prepare('''
      SELECT mf.text FROM word w 
      JOIN word_morphology wm ON w.id = wm.word_id 
      JOIN morphological_form mf ON wm.morphological_form_id = mf.id 
      WHERE w.text = ? COLLATE NOCASE AND wm.part_of_speech_id = ?
    ''');
    final result = statement.select([word, pos.id]);
    statement.dispose();

    if (result.isEmpty) return word;
    return result.first['text'] as String;
  }

  // --- Helpers ---

  List<String> _resolveBaseForms(String word) {
    if (_morphCache.containsKey(word)) return _morphCache[word]!;

    final statement = _db.prepare(
      'SELECT mf.text FROM word w '
      'JOIN word_morphology wm ON w.id = wm.word_id '
      'JOIN morphological_form mf ON wm.morphological_form_id = mf.id '
      'WHERE w.text = ? COLLATE NOCASE',
    );
    final rows = statement.select([word]);
    statement.dispose();

    final forms = <String>{word}; // Always start with original
    for (final row in rows) {
      forms.add(row['text'] as String);
    }

    final resultList = forms.toList();

    // Simple LRU Cache logic
    if (_morphCache.length >= morphCacheMax) _morphCache.remove(_morphCache.keys.first);

    _morphCache[word] = resultList;

    return resultList;
  }

  /// Dispose prepared statements and close the DB.
  void close() => _db.dispose();
}
