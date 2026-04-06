## 0.2.0


### Breaking changes
- `Lexicor.morphology()` renamed to `Lexicor.lemmatize()`. The old name was
  misleading — the method returns the base lemma of an inflected form.

### New features
- **`withDefinitions` mode** — `Lexicor.init(withDefinitions: true)` loads
  `dictionary_full.sqlite` and populates `Concept.definition` on every lookup
  result. Defaults to `false` for backward-compatible lightweight operation.
- **`Concept.definition`** — new nullable getter on the `Concept` interface.
  Returns the WordNet synset gloss when `withDefinitions: true`, otherwise `null`.
- **`Lexicor.synonyms(concept)`** — returns all words that share the same synset
  (strict synonyms within the exact same sense).
- **`Lexicor.traverse(concept, type, {maxDepth})`** — recursively walks a
  relation hierarchy (e.g. hypernym chain) using a single SQLite recursive CTE.
  Returns `List<RelatedWord>` where each entry carries a `depth` field. Throws
  `ArgumentError` for non-recursive relation types.
- **`Lexicor.examples(concept)`** — returns usage example sentences from the
  `sample` table in the full database. Returns an empty list in light mode.
- **`Lexicor.lookupBatch(words)`** — looks up a list of words, returning a
  `Map<String, LookupResult>`. Repeated words are served from the lookup cache.
- **`RelatedWord.depth`** — new field (default `1`). Always `1` for `related()`;
  reflects traversal depth for `traverse()`.

### Performance improvements
- `Lexicor.related(concept, type: ...)` now filters in SQL via a dedicated
  prepared statement, avoiding unnecessary row fetches.
- `lookup()` results are LRU-cached (default 512 entries).
- Both caches share the same LRU eviction helper.

### Fixes
- `Lexicor.init()` now opens assets in `OpenMode.readOnly`.
- `path` moved from `dependencies` to `dev_dependencies`.
- README corrected (`semantic`/`lexical`, `byType`, version badge).

### Build tooling
- `tool/sql/migration_full.sql` — full schema with `definition` + `sample` table.
- `tool/sql/oewn.sql` — source schema reference.
- `build_database.dart` — supports `--full`, no flag, `--all`.
- Three melos scripts: `build`, `build:full`, `build:all`.

### Tests
- Integration tests use `markTestSkipped` when assets are absent.
- New unit tests: `lookupBatch`, `synonyms`, `traverse`, `examples`,
  `definitions`, lookup caching, invalid-concept guard.
- `test_db.dart` extended with synonym, traverse, and sample data.

---

## 0.1.4

- **Performance**: All SQL queries are `PreparedStatement` instances.
- **Example**: `lexicor_demo.dart` expanded.

## 0.1.3

- **Documentation**: Fixed typo in README.

## 0.1.2

- **Refactor**: Consolidated `ConceptImpl` into `concept.dart`.
- **Feature**: Added `example/check_db_size.dart`.

## 0.1.1

- **Examples**: Added `lexicor_demo.dart` and `benchmark.dart`.

## 0.1.0

- 🚀 Initial release.