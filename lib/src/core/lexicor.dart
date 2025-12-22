// lib/src/core/lexicor.dart

import 'dart:io';
import 'dart:isolate';

import 'package:lexicor/lexicor.dart';
import 'package:lexicor/src/core/lexicor_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// The public entry point for the Lexicor WordNet engine.
///
/// Use [Lexicor.init] to create an instance. Always call [close] when done to release native
/// resources.
class Lexicor {
  final LexicorService _service;

  // Private constructor to enforce async initialization.
  Lexicor._(this._service);

  /// Initializes the Lexicor engine from the packaged SQLite asset.
  ///
  /// **Parameters:**
  /// * [mode]: Determines whether to load the DB into RAM or read from disk.
  ///   Defaults to [StorageMode.onDisk].
  /// * [customPath]: An optional file path to override the bundled asset location.
  ///   Required for Flutter apps (pass the path from `getApplicationDocumentsDirectory`).
  ///
  /// **Throws:**
  /// * [FileSystemException] if the package asset cannot be resolved (e.g., inside a compiled
  ///   Flutter app without [customPath]).
  /// * [SqliteException] if the database file is corrupt or unreadable.
  static Future<Lexicor> init({
    StorageMode mode = StorageMode.onDisk,
    String? customPath,
  }) async {
    String path;

    if (customPath != null) {
      path = customPath;
    } else {
      final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:lexicor/assets/dictionary.sqlite'),
      );
      if (uri == null) {
        throw const FileSystemException(
          "Could not find package asset. If running in Flutter, use 'customPath'.",
        );
      }
      path = uri.toFilePath();
    }

    // Always open disk DB first.
    final diskDatabase = sqlite3.open(path);

    // If disk mode is requested, return immediately.
    if (mode == StorageMode.onDisk) return Lexicor._(LexicorService(diskDatabase));

    // Handle Memory Mode
    try {
      final memoryDatabase = sqlite3.openInMemory();

      // Perform the backup (copy) from Disk -> Memory.
      // nPage: -1 copies the entire database in one step.
      await diskDatabase.backup(memoryDatabase, nPage: -1).drain.call();

      // Close the disk handle as it is no longer needed.
      diskDatabase.dispose();

      return Lexicor._(LexicorService(memoryDatabase));
    } catch (e) {
      // Ensure we don't leave open connections on failure.
      diskDatabase.dispose();
      rethrow;
    }
  }

  /// Closes the Lexicor instance and frees native resources.
  ///
  /// After calling this method, any further calls to the instance will throw an error.
  void close() => _service.close();

  /// Looks up [word] and returns a rich [LookupResult].
  ///
  /// The result contains:
  /// - `resolvedForms`: The morphological base forms tried (original first).
  /// - `concepts`: An ordered, deduplicated list of [Concept] objects found.
  LookupResult lookup(String word) => _service.lookup(word);

  /// Returns related words for a specific [concept].
  ///
  /// Optionally filter by [type] to restrict results to a specific
  /// [RelationType] (e.g., [RelationType.hypernym]).
  RelationResult related(Concept concept, {RelationType? type}) {
    final items = _service.getRelated(concept, type);
    return RelationResult(items);
  }

  /// Returns the morphological root of a word for a specific part of speech.
  ///
  /// Example:
  /// ```dart
  /// lexicor.morphology('ran', SpeechPart.verb); // returns 'run'
  /// ```
  ///
  /// This method is provided for advanced callers who need direct morphological access.
  /// For general use, prefer [lookup], which performs morphology resolution automatically.
  String morphology(String word, SpeechPart pos) => _service.getMorphology(word, pos);
}
