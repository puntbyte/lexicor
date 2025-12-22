## 0.1.3

- **Documentation**: Fixed typo in README.

## 0.1.2

- **Refactor**: Consolidated the internal `ConceptImpl` class into `concept.dart` to improve code 
  organization while maintaining strict API encapsulation.
- **Features**: Added `example/check_db_size.dart` tool to analyze database table and index sizes.
- **Documentation**: Updated README with accurate database statistics (size breakdown) and license
  details.

## 0.1.1

- **Examples**: Added `lexicor_demo.dart` to demonstrate lookup, filtering, and relationship 
  traversal.
- **Dev**: Added `benchmark.dart` to measure performance differences between Disk and Memory modes.
- **Documentation**: polished `README.md` with installation steps and Flutter integration guide.

## 0.1.0

- 🚀 **Initial Release**: Launched Lexicor, the strictly typed Open English WordNet interface.
- **Database**: Embedded a highly optimized SQLite database (v2.3.2) with `WITHOUT ROWID` tables 
  and custom indexes.
- **API**:
  - Added `Lexicor` facade with `init()`, `lookup()`, and `related()` methods.
  - Added `StorageMode` to support both Disk (low memory) and In-Memory (high speed) operations.
  - Introduced `SpeechPart`, `DomainCategory`, and `RelationType` enums for strict typing.
  - Implemented automatic morphology resolution (e.g., resolving "better" to "good").
