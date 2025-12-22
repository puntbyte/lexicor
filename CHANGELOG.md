## 0.1.0

- 🚀 **Initial Release**: Launched Lexicor, the strictly typed Open English WordNet interface.
- **Database**: Included optimized SQLite database (v6.0 based schema) with `WITHOUT ROWID` 
  optimizations for reduced footprint (7.8MB).
- **API**:
  - Added `Lexicor` facade with `init()`, `lookup()`, and `related()`.
  - Added `StorageMode` to support both Disk and In-Memory operations.
  - Added `SpeechPart`, `DomainCategory`, and `RelationType` enums for strict typing.
  - Added smart morphology resolution (stemming) for lookups.
- **Architecture**: Implemented Interface/Implementation pattern to encapsulate database IDs.
