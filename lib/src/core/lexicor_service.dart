// lib/src/core/lexicor_service.dart

import 'dart:collection';

import 'package:lexicor/src/enums/domain_category.dart';
import 'package:lexicor/src/enums/part_of_speech.dart';
import 'package:lexicor/src/enums/relation_type.dart';
import 'package:lexicor/src/models/concept.dart';
import 'package:lexicor/src/models/related_word.dart';
import 'package:lexicor/src/results/lookup_result.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed service powering Lexicor.
///
/// This class encapsulates prepared statements and the tiny morphology cache. It returns plain
/// model objects and does not perform any I/O beyond queries.
class LexicorService {
  final Database _db;

  /// Create a new service backed by a [sqlite3.Database] instance.
  ///
  /// [morphCacheMax] controls the LRU size for cached morphology resolutions.
  LexicorService(this._db, {this.morphCacheMax = 1024}) {
    _prepareStatements();
  }

  late final PreparedStatement _morphStmt;
  late final PreparedStatement _lookupStmt;
  late final PreparedStatement _relatedStmt;

  final LinkedHashMap<String, List<String>> _morphCache = LinkedHashMap();
  final int morphCacheMax;

  void _prepareStatements() {
    _morphStmt = _db.prepare('''
      SELECT DISTINCT mf.text AS base
      FROM word w
      JOIN word_morphology wm ON w.id = wm.word_id
      JOIN morphological_form mf ON wm.morphological_form_id = mf.id
      WHERE w.text = ?
    ''');

    _lookupStmt = _db.prepare('''
      SELECT s.id AS id, s.part_of_speech_id AS pos, s.domain_category_id AS domain
      FROM synset s
      JOIN sense se ON s.id = se.synset_id
      JOIN word w ON se.word_id = w.id
      WHERE w.text = ?
      ORDER BY se.sense_sort_order ASC
    ''');

    _relatedStmt = _db.prepare('''
      SELECT w.text AS text, rel.relationship_type_id AS relationship_type_id, 1 as is_semantic
      FROM semantic_relationship rel
      JOIN sense target_s ON rel.target_synset_id = target_s.synset_id
      JOIN word w ON target_s.word_id = w.id
      WHERE rel.source_synset_id = ?
      UNION ALL
      SELECT w.text AS text, lex_rel.relationship_type_id AS relationship_type_id, 0 as is_semantic
      FROM sense source_s
      JOIN lexical_relationship lex_rel ON source_s.id = lex_rel.source_sense_id
      JOIN sense target_s ON lex_rel.target_sense_id = target_s.id
      JOIN word w ON target_s.word_id = w.id
      WHERE source_s.synset_id = ?
    ''');
  }

  /// Perform a morphology-aware lookup for [word].
  ///
  /// The returned [LookupResult] contains:
  /// - `resolvedForms` (original word first, then base forms),
  /// - `concepts` (ordered, deduplicated `Concept` objects).
  LookupResult lookupResult(String word) {
    final forms = _resolveBaseForms(word);
    final seen = <int>{};
    final concepts = <Concept>[];

    for (final form in forms) {
      final rows = _lookupStmt.select([form]);
      for (final row in rows) {
        final id = row['id'] as int;
        if (!seen.add(id)) continue;
        final pos = PartOfSpeech.fromDbValue(row['pos']);
        final domain = DomainCategory.fromId(row['domain'] as int);
        concepts.add(Concept(id: id, pos: pos, domain: domain));
      }
    }

    return LookupResult(query: word, resolvedForms: forms, concepts: concepts);
  }

  /// Return related words (lexical + semantic) for [conceptId].
  ///
  /// If [type] is provided, results are filtered to that [RelationType].
  List<RelatedWord> getRelated(int conceptId, [RelationType? type]) {
    final rows = _relatedStmt.select([conceptId, conceptId]);
    final list = <RelatedWord>[];

    for (final row in rows) {
      list.add(RelatedWord(
        word: row['text'] as String,
        relation: RelationType.fromId(row['relationship_type_id'] as int),
        isSemantic: (row['is_semantic'] as int) == 1,
      ));
    }

    if (type != null) {
      return list.where((r) => r.relation == type).toList();
    }
    return list;
  }

  /// Return the morphological base form for [word] and [pos], or [word] if none.
  String getMorphology(String word, PartOfSpeech pos) {
    final rows = _morphStmt.select([word]);
    if (rows.isEmpty) return word;
    return rows.first['base'] as String;
  }

  List<String> _resolveBaseForms(String word) {
    final cached = _morphCache.remove(word);
    if (cached != null) {
      _morphCache[word] = cached; // mark MRU
      return cached;
    }

    final rows = _morphStmt.select([word]);
    final set = <String>{};
    for (final r in rows) {
      set.add(r['base'] as String);
    }

    final result = <String>[word];
    for (final f in set) {
      if (f != word) result.add(f);
    }

    _morphCache[word] = result;
    if (_morphCache.length > morphCacheMax) {
      _morphCache.remove(_morphCache.keys.first);
    }

    return result;
  }

  /// Dispose prepared statements and close the DB.
  void close() {
    try {
      _morphStmt.dispose();
    } catch (_) {}
    try {
      _lookupStmt.dispose();
    } catch (_) {}
    try {
      _relatedStmt.dispose();
    } catch (_) {}
    try {
      _db.dispose();
    } catch (_) {}
  }
}
