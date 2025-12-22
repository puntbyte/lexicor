# Lexicor

[![pub package](https://img.shields.io/pub/v/lexicor.svg)](https://pub.dev/packages/lexicor)

**Lexicor** is a strictly typed, highly optimized, offline interface for the 
[Open English WordNet](https://en-word.net/).

It provides a high-performance, embedded SQL engine to query English definitions, synonyms, 
antonyms, hypernyms, and more, without relying on external APIs or raw text parsing.

## ✨ Features

- **🚀 Ultra Fast:** Microsecond-level lookups (~20µs on disk). Powered by a custom SQLite database
  using `WITHOUT ROWID` optimizations and specific covering indexes.
- **🔒 Strictly Typed:** No magic strings or integers. Work with `Concept`, `SpeechPart`, 
  `RelationType`, and `DomainCategory` objects.
- **🧠 Morphology Aware:** Automatically handles stem resolution. Searching for *"ran"* matches 
  *"run"*; *"better"* matches *"good"*.
- **⚡ Dual Modes:**
  - **Disk Mode:** Instant startup (<25ms), low memory usage.
  - **Memory Mode:** Loads DB into RAM for nanosecond-level query speeds.
- **🔗 Rich Relations:** Distinguishes between **Semantic** relations (Concept-to-Concept) and 
  **Lexical** relations (Word-to-Word).

## 📦 Installation

Add `lexicor` to your `pubspec.yaml`:

```yaml
dependencies:
  lexicor: ^0.1.0
```

## 🚀 Quick Start

```dart
import 'package:lexicor/lexicor.dart';

void main() async {
  // 1. Initialize (Disk mode is default)
  final lexicor = await Lexicor.init();

  // 2. Lookup a word
  final result = lexicor.lookup('bank');
  
  print('Found ${result.concepts.length} concepts for "${result.query}"');

  // 3. Iterate concepts
  for (final concept in result.concepts) {
    print('[${concept.part.label}] ${concept.category.label}');
    
    // 4. Get relationships (Hypernyms, Parts, Antonyms...)
    final relations = lexicor.related(concept);
    
    for (final rel in relations.withRelation(RelationType.hypernym)) {
      print('  -> is a type of: ${rel.word}');
    }
  }

  // 5. Cleanup
  lexicor.close();
}
```

## 📖 Usage Guide

### Initialization Modes

Lexicor offers two ways to load the database via `StorageMode`:

```dart
// 1. StorageMode.onDisk (Default)
// Instant startup (~25ms). Queries take ~20-50µs. 
// Best for CLI tools and Mobile apps.
final db = await Lexicor.init(mode: StorageMode.onDisk);

// 2. StorageMode.inMemory
// Slower startup (~100ms copy time) but faster queries (~15µs). 
// Best for backend servers or heavy batch processing.
final db = await Lexicor.init(mode: StorageMode.inMemory);
```

### Flutter Integration

Because Flutter assets are packed into the app bundle, `sqlite3` cannot open them directly from the
bundle. You must copy the asset to a file path first (e.g., using `path_provider`).

```dart
// 1. Copy 'dictionary.sqlite' from assets to Application Documents Directory.
// 2. Pass that path to Lexicor:
final lexicor = await Lexicor.init(
  customPath: '/path/to/app_documents/dictionary.sqlite',
);
```

### Morphology

Lexicor automatically resolves word forms. You don't need to manually stem words.

```dart
// The user types "running"
final result = lexicor.lookup('running');

// Lexicor automatically searches for "run"
print(result.resolvedForms); // ['running', 'run']
```

If you need raw access to morphology:

```dart
final root = lexicor.morphology('better', SpeechPart.adjective);
print(root); // "good"
```

### Relationships

WordNet distinguishes between two types of links:

1.  **Semantic (Concept-to-Concept):** e.g., A *Dog* is an *Animal*.
2.  **Lexical (Word-to-Word):** e.g., *Slow* is the antonym of *Fast*.

`lexicor.related()` returns both, but you can filter them:

```dart
final rels = lexicor.related(concept);

// Get synonyms, hypernyms, etc.
final semantic = rels.semanticOnly;

// Get antonyms, derivations, etc.
final lexical = rels.lexicalOnly;

// Filter by specific type
final parts = rels.byType(RelationType.partMeronym);
```

## 📊 Database Stats

Lexicor uses a highly optimized database structure. Unlike raw SQL dumps (often 100MB+), Lexicor is 
compressed to **~27 MB** while maintaining full relationship graphs.

| Component              | Size    | Description                                      |
|:-----------------------|:--------|:-------------------------------------------------|
| **Words**              | 3.0 MB  | ~150k unique lemmas                              |
| **Concepts**           | 1.36 MB | ~120k Synsets                                    |
| **Senses**             | 3.4 MB  | ~210k Word-Concept pairs                         |
| **Semantic Relations** | 3.7 MB  | Hypernyms, Holonyms, Entailments (WITHOUT ROWID) |
| **Lexical Relations**  | 4.0 MB  | Antonyms, Derivations (WITHOUT ROWID)            |
| **Indexes**            | ~11 MB  | `COLLATE NOCASE` indexes for instant lookups     |

## 📂 Database Source & License

This package includes a compressed, optimized version of 
**[Open English WordNet 2025](https://github.com/x-englishwordnet/sqlite)** (v2.3.2).

- **Source:** [Open English Wordnet in Sqlite form](https://github.com/x-englishwordnet/sqlite)
- **Database License:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (Open English 
  WordNet).
- **Package License:** MIT.

Using this package in your commercial app requires you to attribute the Open English WordNet 
project in your app's About/License section.
