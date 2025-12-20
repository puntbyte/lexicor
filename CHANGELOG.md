## [0.1.0]

### Added
- Initial public release.
- `Lexicor` public API with `Lexicor.init`, `lookup`, `getRelatedConcepts`, `getMorphology`, and `close`.
- `LookupResult` and `RelationResult` richer result objects with convenience helpers.
- `LexicorService` (SQLite-backed) with prepared statements and morphology cache.
- Models: `Concept`, `RelatedWord`.
- Enums: `PartOfSpeech`, `DomainCategory`, `RelationshipType`.
- Example usage and benchmarks (in `example/`).
- README and packaging metadata.
