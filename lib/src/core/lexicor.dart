// lib/src/core/lexicor.dart

import 'dart:io';
import 'dart:isolate';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// The public entry point for the Lexicor WordNet engine.
///
/// Use [Lexicor.init] to create an instance. Always call [close] when done
/// to release native resources.
///
/// ```dart
/// // Light mode — no definitions (~28 MB asset).
/// final lexicor = await Lexicor.init();
///
/// // Full mode — definitions + usage examples (~40 MB asset).
/// final lexicor = await Lexicor.init(withDefinitions: true);
/// ```
class Lexicor {
  final LexicorService _service;

  Lexicor._(this._service);

  /// Initialises the Lexicor engine.
  ///
  /// **Parameters:**
  /// * [mode]: Whether to load the DB into RAM or stream from disk.
  ///   Defaults to [StorageMode.onDisk].
  /// * [withDefinitions]: When `true`, loads `dictionary_full.sqlite` and
  ///   populates [Concept.definition] and [examples]. Defaults to `false`.
  /// * [customPath]: Overrides the bundled asset path. Required for Flutter —
  ///   pass the file path after copying the asset via `path_provider`.
  ///
  /// **Throws:**
  /// * [FileSystemException] if the asset cannot be resolved without [customPath].
  /// * [SqliteException] if the database file is corrupt or unreadable.
  static Future<Lexicor> init({
    StorageMode mode = StorageMode.onDisk,
    bool withDefinitions = false,
    String? customPath,
  }) async {
    String path;

    if (customPath != null) {
      path = customPath;
    } else {
      final assetName = withDefinitions ? 'dictionary_full.sqlite' : 'dictionary.sqlite';
      final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:lexicor/assets/$assetName'),
      );
      if (uri == null) {
        throw FileSystemException(
          "Could not find package asset '$assetName'. "
          "If running in Flutter, copy the asset and pass its path via 'customPath'.",
        );
      }
      path = uri.toFilePath();
    }

    // Always open in read-only mode — we never modify the bundled asset.
    final diskDb = sqlite3.open(path, mode: OpenMode.readOnly);

    if (mode == StorageMode.onDisk) {
      return Lexicor._(LexicorService(diskDb, withDefinitions: withDefinitions));
    }

    // Memory mode: copy disk → RAM, then release the disk handle.
    try {
      final memDb = sqlite3.openInMemory();
      await diskDb.backup(memDb, nPage: -1).drain.call();
      diskDb.dispose();
      return Lexicor._(LexicorService(memDb, withDefinitions: withDefinitions));
    } catch (e) {
      diskDb.dispose();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Core API
  // ---------------------------------------------------------------------------

  /// Looks up [word] and returns a [LookupResult].
  ///
  /// Morphology is resolved automatically — *"ran"* also matches *"run"*.
  /// Results are LRU-cached so repeated lookups for the same word are free.
  ///
  /// [Concept.definition] is populated only when the instance was created
  /// with `withDefinitions: true`.
  LookupResult lookup(String word) => _service.lookup(word);

  /// Looks up every word in [words] and returns a `word → result` map.
  ///
  /// Words already in the lookup cache are not re-queried. Useful for batch
  /// NLP pipelines.
  ///
  /// ```dart
  /// final results = lexicor.lookupBatch(['run', 'walk', 'swim']);
  /// results['run']?.concepts.length; // e.g. 15
  /// ```
  Map<String, LookupResult> lookupBatch(List<String> words) => _service.lookupBatch(words);

  /// Returns words related to [concept].
  ///
  /// Pass [type] to restrict results to a single [RelationType]. The filter
  /// runs in SQL — no wasted data transfer.
  ///
  /// ```dart
  /// final hypernyms = lexicor.related(concept, type: RelationType.hypernym);
  /// ```
  RelationResult related(Concept concept, {RelationType? type}) =>
      RelationResult(_service.getRelated(concept, type));

  /// Returns all words that share the same synset as [concept].
  ///
  /// These are strict synonyms — words that carry the exact same meaning in
  /// the same context. For broader similarity, use
  /// `related(concept, type: RelationType.similar)`.
  ///
  /// ```dart
  /// final syns = lexicor.synonyms(concept); // e.g. ['car', 'auto', 'automobile']
  /// ```
  List<String> synonyms(Concept concept) => _service.getSynonyms(concept);

  /// Recursively walks the [type] relation from [concept] up to [maxDepth] hops.
  ///
  /// Only valid for relations where [RelationType.isRecursive] is `true`
  /// (e.g. [RelationType.hypernym], [RelationType.hyponym],
  /// [RelationType.partMeronym]). Uses a SQLite recursive CTE — the entire
  /// traversal is done in a single DB call.
  ///
  /// Each [RelatedWord] in the result carries a [RelatedWord.depth] value
  /// indicating how many hops away it is from [concept].
  ///
  /// ```dart
  /// final chain = lexicor.traverse(concept, RelationType.hypernym);
  /// for (final word in chain) {
  ///   print('${'  ' * word.depth}${word.word}'); // indented hierarchy
  /// }
  /// ```
  ///
  /// Throws [ArgumentError] if [type] is not a recursive relation.
  List<RelatedWord> traverse(
    Concept concept,
    RelationType type, {
    int maxDepth = 5,
  }) => _service.traverse(concept, type, maxDepth: maxDepth);

  /// Returns usage example sentences for [concept].
  ///
  /// Returns an empty list when the instance was created with
  /// `withDefinitions: false` (the default). Example sentences are stored in
  /// the full database (`dictionary_full.sqlite`) only.
  ///
  /// ```dart
  /// final lexicor = await Lexicor.init(withDefinitions: true);
  /// final examples = lexicor.examples(concept);
  /// // e.g. ["she ran to the store", "he ran the marathon"]
  /// ```
  List<String> examples(Concept concept) => _service.getExamples(concept);

  // ---------------------------------------------------------------------------
  // Morphology
  // ---------------------------------------------------------------------------

  /// Returns the base lemma of [word] for a specific [pos].
  ///
  /// ```dart
  /// lexicor.lemmatize('ran', SpeechPart.verb);        // 'run'
  /// lexicor.lemmatize('better', SpeechPart.adjective); // 'good'
  /// ```
  ///
  /// For general use, prefer [lookup] which handles lemmatisation
  /// automatically and returns full concept data.
  String lemmatize(String word, SpeechPart pos) => _service.lemmatize(word, pos);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Closes the instance and releases all native resources.
  void close() => _service.close();
}
