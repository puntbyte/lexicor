// lib/src/core/lexicor.dart

import 'dart:io';
import 'dart:isolate';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:lexicor/src/results/lookup_result.dart';
import 'package:lexicor/src/results/relation_result.dart';
import 'package:sqlite3/sqlite3.dart';

/// Public entrypoint for the Lexicor WordNet engine.
///
/// Use [Lexicor.init] to create an instance. Always call [close] when done to
/// release native resources.
///
/// The API exposes high-level, discoverable results:
/// - [lookup] returns a [LookupResult] (includes resolved morphological forms
///   and ordered `Concept`s).
/// - [related] returns a [RelationResult] (semantic & lexical links).
class Lexicor {
  final LexicorService _service;

  Lexicor._(this._service);

  /// Initialize the Lexicor engine from the packaged SQLite asset.
  ///
  /// By default this will resolve the package asset at:
  /// `package:lexicor/assets/dictionary.sqlite`. Pass [packageAssetPath] to
  /// override when embedding the DB elsewhere.
  ///
  /// If [inMemory] is true, the DB will be copied into an in-memory SQLite
  /// instance (faster lookups at the cost of startup time and memory).
  ///
  /// Throws [FileSystemException] when the asset cannot be resolved.
  static Future<Lexicor> init({
    bool inMemory = false,
    String packageAssetPath = 'package:lexicor/assets/dictionary.sqlite',
  }) async {
    final uri = await Isolate.resolvePackageUri(Uri.parse(packageAssetPath));
    if (uri == null) {
      throw FileSystemException('Could not resolve $packageAssetPath');
    }

    final diskDb = sqlite3.open(uri.toFilePath());
    if (!inMemory) {
      return Lexicor._(LexicorService(diskDb));
    }

    // Copy DB into memory for faster queries; await the backup stream.
    final memoryDb = sqlite3.openInMemory();
    try {
      await diskDb.backup(memoryDb, nPage: -1).drain();
      diskDb.dispose();
      return Lexicor._(LexicorService(memoryDb));
    } catch (e) {
      // Clean up on failure.
      try {
        memoryDb.dispose();
      } catch (_) {}
      diskDb.dispose();
      rethrow;
    }
  }

  /// Close the Lexicor instance and free native resources.
  ///
  /// After calling this method the instance must not be used.
  void close() => _service.close();

  /// Look up [word] and return a rich [LookupResult].
  ///
  /// The result:
  /// - includes `resolvedForms` (morphological base forms tried, original first),
  /// - contains deduplicated, ordered `Concept` objects,
  /// - preserves sense priority (WordNet ordering).
  LookupResult lookup(String word) => _service.lookupResult(word);

  /// Return related words for a concept id as a [RelationResult].
  ///
  /// Optionally filter by [type] to restrict results to a specific
  /// [RelationType] (e.g. `hypernym`).
  RelationResult related(int conceptId, {RelationType? type}) {
    final items = _service.getRelated(conceptId, type);
    return RelationResult(conceptId: conceptId, items: items);
  }

  /// Return the morphological base form for [word] and [pos], if available.
  ///
  /// This method is provided for advanced callers who need direct morphological
  /// access. For general lookups prefer [lookup] which performs morphology
  /// resolution automatically.
  String morphology(String word, PartOfSpeech pos) => _service.getMorphology(word, pos);
}
