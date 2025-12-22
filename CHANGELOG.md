## 0.1.1

- **Documentation**: Improved README and added example.
- **Performance**: Added benchmark script.

## 0.1.0

- 🚀 **Initial Release**: Launched Lexicor, the strictly typed Open English WordNet interface.
- **Database**: Included optimized SQLite database.
- **API**:
  - Added `Lexicor` facade with `init()`, `lookup()`, and `related()`.
  - Added `StorageMode` to support both Disk and In-Memory operations.
  - Added `SpeechPart`, `DomainCategory`, and `RelationType` enums for strict typing.
  - Added smart morphology resolution (stemming) for lookups.
