import 'dart:collection';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed service powering Lexicor.
///
/// This class encapsulates prepared statements for high performance.
class LexicorService {
  final Database _db;

  // LRU Cache for morphology results
  final LinkedHashMap<String, List<String>> _morphCache = LinkedHashMap();
  final int morphCacheMax;

  // --- Prepared Statements (Compiled once, reused) ---
  late final PreparedStatement _lookupStmt;
  late final PreparedStatement _relatedStmt;
  late final PreparedStatement _lemmatizeStmt; // Finds root from inflection
  late final PreparedStatement _morphStmt; // Finds inflection from root

  LexicorService(this._db, {this.morphCacheMax = 1024}) {
    _prepareStatements();
  }

  void _prepareStatements() {
    // 1. Concept Lookup
    _lookupStmt = _db.prepare('''
      SELECT s.id, s.part_of_speech_id, s.domain_category_id 
      FROM synset s 
      JOIN sense se ON s.id = se.synset_id 
      JOIN word w ON se.word_id = w.id 
      WHERE w.text = ? COLLATE NOCASE 
      ORDER BY se.sense_sort_order ASC
    ''');

    // 2. Relationship Lookup (Union of Semantic and Lexical)
    _relatedStmt = _db.prepare('''
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

    // 3. Lemmatization (Input "went" -> Find "go")
    // We look in morphological_form to find the ID, then map back to the base word.
    _lemmatizeStmt = _db.prepare('''
      SELECT DISTINCT w.text
      FROM morphological_form mf
      JOIN word_morphology wm ON mf.id = wm.morphological_form_id
      JOIN word w ON wm.word_id = w.id
      WHERE mf.text = ? COLLATE NOCASE
    ''');

    // 4. Morphology (Input "go" -> Find "went")
    // Used for specific morphology lookups
    _morphStmt = _db.prepare('''
      SELECT w.text 
      FROM morphological_form mf
      JOIN word_morphology wm ON mf.id = wm.morphological_form_id
      JOIN word w ON wm.word_id = w.id
      WHERE mf.text = ? COLLATE NOCASE AND wm.part_of_speech_id = ?
    ''');
  }

  /// Perform a morphology-aware lookup.
  LookupResult lookup(String word) {
    // A. Resolve Base Forms (e.g. "fetches" -> ["fetches", "fetch"])
    final forms = _resolveBaseForms(word);

    final concepts = <Concept>[];
    final seenIds = <int>{};

    // B. Query for every form found
    for (final form in forms) {
      final rows = _lookupStmt.select([form]);

      for (final row in rows) {
        final id = row['id'] as int;

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

    return LookupResult(query: word, resolvedForms: forms, concepts: concepts);
  }

  List<RelatedWord> getRelated(Concept concept, [RelationType? type]) {
    if (concept is! ConceptImpl) {
      throw ArgumentError('Invalid Concept provided. Use object from lookup().');
    }

    final synsetId = concept.id;
    final results = _relatedStmt.select([synsetId, synsetId]);

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

  String getMorphology(String word, SpeechPart pos) {
    final result = _morphStmt.select([word, pos.id]);
    if (result.isEmpty) return word;
    return result.first['text'] as String;
  }

  // --- Helpers ---

  /// Finds the base root(s) for a given word.
  /// Example: "went" -> ["went", "go"]
  List<String> _resolveBaseForms(String word) {
    if (_morphCache.containsKey(word)) return _morphCache[word]!;

    final rows = _lemmatizeStmt.select([word]);

    // Always include the original query (it might be a base word itself)
    final forms = <String>{word};

    for (final row in rows) {
      forms.add(row['text'] as String);
    }

    final resultList = forms.toList();

    // Cache maintenance
    if (_morphCache.length >= morphCacheMax) _morphCache.remove(_morphCache.keys.first);
    _morphCache[word] = resultList;

    return resultList;
  }

  /// Dispose prepared statements and close the DB.
  void close() {
    _lookupStmt.dispose();
    _relatedStmt.dispose();
    _lemmatizeStmt.dispose();
    _morphStmt.dispose();
    _db.dispose();
  }
}
