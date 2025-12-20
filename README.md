# Lexicor

**Lexicor** — a Dart WordNet engine.  
Provides offline, fast lookup of meanings (concepts), morphology resolution, and lexical/semantic relations.

## Features
- Morphology-aware lookup (handles `running` → `run`, `went` → `go`).
- Fast queries with prepared statements and optional in-memory DB mode.
- Rich result objects: `LookupResult` and `RelationResult`.
- Small LRU cache for morphology.
- Offline: ship `dictionary.sqlite` in package `lib/assets/`.

## Quick start

Add to `pubspec.yaml`:

```yaml
dependencies:
  lexicor:
    path: ../path-to-lexicor
