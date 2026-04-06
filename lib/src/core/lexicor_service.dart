// lib/src/core/lexicor_service.dart

import 'dart:collection';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed service powering Lexicor.
///
/// All public methods are accessed via the [Lexicor] facade — this class is
/// an internal implementation detail.
class LexicorService {
  final Database _db;

  /// Whether this instance was initialised against `dictionary_full.sqlite`.
  ///
  /// When `true`, [lookup] populates [Concept.definition] and [examples]
  /// returns usage sentences. When `false`, both return null / empty.
  final bool withDefinitions;

  // --- LRU Caches ---

  /// Cache for resolved base-form lists (morph resolution).
  final LinkedHashMap<String, List<String>> _morphCache = LinkedHashMap();

  /// Cache for full [LookupResult] objects, keyed by the original query word.
  final LinkedHashMap<String, LookupResult> _lookupCache = LinkedHashMap();

  final int morphCacheMax;
  final int lookupCacheMax;

  // --- Prepared Statements (compiled once, reused for lifetime of service) ---

  late final PreparedStatement _lookupStmt;
  late final PreparedStatement _relatedStmt;
  late final PreparedStatement _relatedByTypeStmt;
  late final PreparedStatement _synonymsStmt;

  /// Recursive CTE statement for hierarchy traversal.
  /// Parameters: [synsetId, typeId, typeId, maxDepth]
  late final PreparedStatement _traverseStmt;

  late final PreparedStatement _lemmatizeStmt;
  late final PreparedStatement _morphStmt;

  /// Only prepared when [withDefinitions] is `true` (table may not exist otherwise).
  PreparedStatement? _examplesStmt;

  LexicorService(
      this._db, {
        this.withDefinitions = false,
        this.morphCacheMax = 1024,
        this.lookupCacheMax = 512,
      }) {
    _prepareStatements();
  }

  void _prepareStatements() {
    // 1. Concept lookup — conditionally includes definition column.
    final defColumn = withDefinitions ? ', s.definition' : '';
    _lookupStmt = _db.prepare('''
      SELECT s.id, s.part_of_speech_id, s.domain_category_id$defColumn
      FROM synset s
      JOIN sense se ON s.id = se.synset_id
      JOIN word w ON se.word_id = w.id
      WHERE w.text = ? COLLATE NOCASE
      ORDER BY se.sense_sort_order ASC
    ''');

    // 2a. All relationships for a concept (no type filter).
    _relatedStmt = _db.prepare('''
      SELECT w.text, rel.relationship_type_id, 1 AS is_semantic
      FROM semantic_relationship rel
      JOIN sense target_s ON rel.target_synset_id = target_s.synset_id
      JOIN word w ON target_s.word_id = w.id
      WHERE rel.source_synset_id = ?
      UNION ALL
      SELECT w.text, lex_rel.relationship_type_id, 0 AS is_semantic
      FROM sense source_s
      JOIN lexical_relationship lex_rel ON source_s.id = lex_rel.source_sense_id
      JOIN sense target_s ON lex_rel.target_sense_id = target_s.id
      JOIN word w ON target_s.word_id = w.id
      WHERE source_s.synset_id = ?
    ''');

    // 2b. Relationships filtered by type in SQL — avoids fetching unneeded rows.
    // Parameters: [synsetId, typeId, synsetId, typeId]
    _relatedByTypeStmt = _db.prepare('''
      SELECT w.text, rel.relationship_type_id, 1 AS is_semantic
      FROM semantic_relationship rel
      JOIN sense target_s ON rel.target_synset_id = target_s.synset_id
      JOIN word w ON target_s.word_id = w.id
      WHERE rel.source_synset_id = ? AND rel.relationship_type_id = ?
      UNION ALL
      SELECT w.text, lex_rel.relationship_type_id, 0 AS is_semantic
      FROM sense source_s
      JOIN lexical_relationship lex_rel ON source_s.id = lex_rel.source_sense_id
      JOIN sense target_s ON lex_rel.target_sense_id = target_s.id
      JOIN word w ON target_s.word_id = w.id
      WHERE source_s.synset_id = ? AND lex_rel.relationship_type_id = ?
    ''');

    // 3. Synonyms: all words that share the same synset as the given concept.
    // Parameters: [synsetId]
    _synonymsStmt = _db.prepare('''
      SELECT DISTINCT w.text
      FROM sense se
      JOIN word w ON se.word_id = w.id
      WHERE se.synset_id = ?
      ORDER BY se.sense_sort_order ASC
    ''');

    // 4. Recursive hierarchy traversal via recursive CTE.
    // Parameters: [synsetId, typeId, typeId, maxDepth]
    //
    // Only follows semantic (synset-level) relations — lexical relations are
    // word-level and don't form hierarchies worth traversing recursively.
    _traverseStmt = _db.prepare('''
      WITH RECURSIVE chain(synset_id, depth) AS (
        SELECT target_synset_id, 1
        FROM semantic_relationship
        WHERE source_synset_id = ? AND relationship_type_id = ?
        UNION ALL
        SELECT sr.target_synset_id, chain.depth + 1
        FROM semantic_relationship sr
        JOIN chain ON sr.source_synset_id = chain.synset_id
        WHERE sr.relationship_type_id = ? AND chain.depth < ?
      )
      SELECT DISTINCT w.text, chain.depth
      FROM chain
      JOIN sense se ON chain.synset_id = se.synset_id
      JOIN word w ON se.word_id = w.id
      ORDER BY chain.depth ASC, w.text ASC
    ''');

    // 5. Lemmatization: inflected form → base word (e.g. "went" → "go").
    _lemmatizeStmt = _db.prepare('''
      SELECT DISTINCT w.text
      FROM morphological_form mf
      JOIN word_morphology wm ON mf.id = wm.morphological_form_id
      JOIN word w ON wm.word_id = w.id
      WHERE mf.text = ? COLLATE NOCASE
    ''');

    // 6. POS-aware lemmatization: "ran" + verb → "run".
    _morphStmt = _db.prepare('''
      SELECT w.text
      FROM morphological_form mf
      JOIN word_morphology wm ON mf.id = wm.morphological_form_id
      JOIN word w ON wm.word_id = w.id
      WHERE mf.text = ? COLLATE NOCASE AND wm.part_of_speech_id = ?
    ''');

    // 7. Usage examples — only prepared when the sample table exists (full DB).
    if (withDefinitions) {
      _examplesStmt = _db.prepare('''
        SELECT text FROM sample WHERE synset_id = ? ORDER BY id ASC
      ''');
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Morphology-aware concept lookup with LRU result caching.
  LookupResult lookup(String word) {
    if (_lookupCache.containsKey(word)) return _lookupCache[word]!;

    final forms = _resolveBaseForms(word);
    final concepts = <Concept>[];
    final seenIds = <int>{};

    for (final form in forms) {
      for (final row in _lookupStmt.select([form])) {
        final id = row['id'] as int;
        if (!seenIds.add(id)) continue;

        concepts.add(ConceptImpl(
          id: id,
          part: SpeechPart.fromId(row['part_of_speech_id'] as String),
          category: DomainCategory.fromId(row['domain_category_id'] as int),
          definition: withDefinitions ? row['definition'] as String? : null,
        ));
      }
    }

    final result = LookupResult(query: word, resolvedForms: forms, concepts: concepts);
    _evict(_lookupCache, lookupCacheMax);
    _lookupCache[word] = result;
    return result;
  }

  /// Looks up multiple words in one call, returning a map of word → result.
  ///
  /// Results for repeated words are served from the lookup cache — no extra
  /// DB round-trips.
  Map<String, LookupResult> lookupBatch(List<String> words) =>
      {for (final w in words) w: lookup(w)};

  /// Returns all related words for [concept], optionally filtered by [type].
  ///
  /// When [type] is provided, filtering happens in SQL (more efficient than
  /// post-filtering in Dart).
  List<RelatedWord> getRelated(Concept concept, [RelationType? type]) {
    final synsetId = _synsetId(concept);
    final ResultSet rows;

    if (type != null) {
      rows = _relatedByTypeStmt.select([synsetId, type.id, synsetId, type.id]);
    } else {
      rows = _relatedStmt.select([synsetId, synsetId]);
    }

    return rows
        .map((row) => RelatedWord(
      word: row['text'] as String,
      type: RelationType.fromId(row['relationship_type_id'] as int),
      isSemantic: (row['is_semantic'] as int) == 1,
    ))
        .toList();
  }

  /// Returns all words that share the same synset as [concept] (i.e. synonyms
  /// within the exact same sense).
  List<String> getSynonyms(Concept concept) {
    final rows = _synonymsStmt.select([_synsetId(concept)]);
    return rows.map((row) => row['text'] as String).toList();
  }

  /// Recursively walks the [type] relation from [concept] up to [maxDepth] hops.
  ///
  /// Only meaningful for relations where [RelationType.isRecursive] is `true`
  /// (e.g. [RelationType.hypernym], [RelationType.hyponym]). The [depth] field
  /// on each [RelatedWord] indicates how many hops away the word is.
  ///
  /// Throws [ArgumentError] if [type] is not a recursive relation.
  List<RelatedWord> traverse(Concept concept, RelationType type, {int maxDepth = 5}) {
    if (!type.isRecursive) {
      throw ArgumentError(
        'RelationType.${type.name} (id: ${type.id}) is not recursive — '
            'traversal is only supported for relations where isRecursive is true '
            '(e.g. hypernym, hyponym, partMeronym).',
      );
    }

    final rows = _traverseStmt.select([_synsetId(concept), type.id, type.id, maxDepth]);

    return rows
        .map((row) => RelatedWord(
      word: row['text'] as String,
      type: type,
      isSemantic: true, // traverse only follows semantic links
      depth: row['depth'] as int,
    ))
        .toList();
  }

  /// Returns usage example sentences for [concept].
  ///
  /// Returns an empty list when the instance was initialised with
  /// `withDefinitions: false` (i.e. using the light database).
  List<String> getExamples(Concept concept) {
    if (_examplesStmt == null) return const [];
    final rows = _examplesStmt!.select([_synsetId(concept)]);
    return rows.map((row) => row['text'] as String).toList();
  }

  /// Returns the base lemma of [word] for the given [pos].
  ///
  /// Falls back to [word] itself when no mapping exists.
  String lemmatize(String word, SpeechPart pos) {
    final result = _morphStmt.select([word, pos.id]);
    return result.isEmpty ? word : result.first['text'] as String;
  }

  /// Dispose all prepared statements and close the database connection.
  void close() {
    _lookupStmt.dispose();
    _relatedStmt.dispose();
    _relatedByTypeStmt.dispose();
    _synonymsStmt.dispose();
    _traverseStmt.dispose();
    _lemmatizeStmt.dispose();
    _morphStmt.dispose();
    _examplesStmt?.dispose();
    _db.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _synsetId(Concept concept) {
    if (concept is! ConceptImpl) {
      throw ArgumentError('Invalid Concept: use an object returned by lookup().');
    }
    return concept.id;
  }

  /// Resolves all base forms for [word] via the morphology table with LRU caching.
  ///
  /// Example: `"fetches"` → `["fetches", "fetch"]`.
  List<String> _resolveBaseForms(String word) {
    if (_morphCache.containsKey(word)) return _morphCache[word]!;

    final forms = <String>{word};
    for (final row in _lemmatizeStmt.select([word])) {
      forms.add(row['text'] as String);
    }

    final result = forms.toList();
    _evict(_morphCache, morphCacheMax);
    _morphCache[word] = result;
    return result;
  }

  /// LRU eviction: removes the oldest entry when the cache is full.
  void _evict<K, V>(LinkedHashMap<K, V> cache, int max) {
    if (cache.length >= max) cache.remove(cache.keys.first);
  }
}