# Lexicor

[![pub package](https://img.shields.io/pub/v/lexicor.svg)](https://pub.dev/packages/lexicor)

**Lexicor** is a strictly typed, highly optimized, offline interface for the
[Open English WordNet](https://en-word.net/).


Powered by an embedded SQLite database — no external APIs, no raw text parsing.

## ✨ Features

- **🚀 Ultra Fast:** Microsecond-level lookups (~20µs on disk). `WITHOUT ROWID`
  tables, covering indexes, and LRU result caching.
- **🔒 Strictly Typed:** `Concept`, `SpeechPart`, `RelationType`, `DomainCategory` —
  no magic strings or integers anywhere.
- **🧠 Morphology Aware:** Automatic stem resolution. *"ran"* → *"run"*,
  *"better"* → *"good"*.
- **📖 Optional Definitions:** Pass `withDefinitions: true` to get WordNet glosses
  on every concept — or keep the default lightweight build when you don't need them.
- **🔗 Rich Relations:** Semantic (Concept-to-Concept) and Lexical (Word-to-Word)
  relations, filterable by type in SQL.
- **🌲 Recursive Traversal:** Walk hypernym/hyponym chains to arbitrary depth via
  a single SQLite recursive CTE.
- **⚡ Dual Storage Modes:** Disk mode (instant startup) or Memory mode (fastest
  queries).

## 📦 Installation

```yaml
dependencies:
  lexicor: ^0.2.0
```

## 🚀 Quick Start

```dart
import 'package:lexicor/lexicor.dart';

void main() async {
  final lexicor = await Lexicor.init();           // lightweight, no definitions
  // final lexicor = await Lexicor.init(withDefinitions: true); // full mode

  final result = lexicor.lookup('bank');
  print('Found ${result.concepts.length} concepts for "${result.query}"');

  for (final concept in result.concepts) {
    print('[${concept.part.label}] ${concept.category.label}');
    if (concept.definition != null) print('  ${concept.definition}');

    final hypernyms = lexicor.related(concept, type: RelationType.hypernym);
    for (final rel in hypernyms.items) {
      print('  -> is a type of: ${rel.word}');
    }
  }

  lexicor.close();
}
```

## 📖 Usage Guide

### Initialization

```dart
// Light mode — no definitions (~28 MB asset, default)
final lexicor = await Lexicor.init();

// Full mode — definitions + usage examples (~40 MB asset)
final lexicor = await Lexicor.init(withDefinitions: true);

// Memory mode — copy DB into RAM for fastest repeated queries
final lexicor = await Lexicor.init(
  mode: StorageMode.inMemory,
  withDefinitions: true,
);
```

| Flag                               | Asset                           | `Concept.definition` | `examples()` | Best for               |
|------------------------------------|---------------------------------|----------------------|--------------|------------------------|
| `withDefinitions: false` (default) | `dictionary.sqlite` ~28 MB      | `null`               | `[]`         | Mobile, CLI, embedding |
| `withDefinitions: true`            | `dictionary_full.sqlite` ~40 MB | populated            | sentences    | Dictionaries, NLP      |

### Definitions

```dart
final lexicor = await Lexicor.init(withDefinitions: true);
final result = lexicor.lookup('bank');
for (final concept in result.concepts) {
  print(concept.definition);
  // "a financial institution that accepts deposits..."
  // "a long ridge or pile..."
}
```

`concept.definition` is always `null` in light mode — safe to use without
checking the mode:

```dart
final def = concept.definition ?? '(no definition)';
```

### Usage Examples

```dart
final lexicor = await Lexicor.init(withDefinitions: true);
final concept = lexicor.lookup('run').primary!;

for (final example in lexicor.examples(concept)) {
  print(example); // "she ran to catch the bus"
}
```

Returns an empty list in light mode.

### Synonyms

```dart
final concept = lexicor.lookup('car').primary!;
final syns = lexicor.synonyms(concept);
// ['car', 'auto', 'automobile', 'motorcar']
```

These are strict synonyms — words that share the exact same synset. For broader
similarity, use `related(concept, type: RelationType.similar)`.

### Recursive Traversal

Walk a relation chain to arbitrary depth in a single DB call:

```dart
final dog = lexicor.lookup('dog').primary!;
final chain = lexicor.traverse(dog, RelationType.hypernym, maxDepth: 5);

for (final word in chain) {
  print('${'  ' * word.depth}${word.word}');
}
// canine
//   carnivore
//     placental
//       mammal
//         ...
```

`traverse` uses a SQLite recursive CTE — the entire hierarchy walk is done in
one round-trip. Only works for relations where `RelationType.isRecursive` is
`true` (hypernym, hyponym, partMeronym, etc.).

### Relationships

```dart
final rels = lexicor.related(concept);

// SQL-level type filter — no wasted data transfer
final hypernyms = lexicor.related(concept, type: RelationType.hypernym);

// Or filter the result object
final semantic = rels.semantic;            // Concept-to-Concept links
final lexical  = rels.lexical;             // Word-to-Word links
final antonyms = rels.byType(RelationType.antonym);
```

### Batch Lookup

```dart
final results = lexicor.lookupBatch(['run', 'walk', 'swim', 'run']);
// 'run' is only queried once; the second entry is served from cache.
results['run']?.concepts.length;
```

### Morphology

```dart
// Automatic during lookup:
lexicor.lookup('running').resolvedForms; // ['running', 'run']

// Direct lemmatization:
lexicor.lemmatize('ran', SpeechPart.verb);        // 'run'
lexicor.lemmatize('better', SpeechPart.adjective); // 'good'
```

### Flutter Integration

```dart
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:lexicor/lexicor.dart';

Future<Lexicor> initLexicor({bool withDefinitions = false}) async {
  final assetName = withDefinitions ? 'dictionary_full.sqlite' : 'dictionary.sqlite';
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$assetName');

  if (!file.existsSync()) {
    final data = await rootBundle.load('packages/lexicor/assets/$assetName');
    await file.writeAsBytes(data.buffer.asUint8List());
  }

  return Lexicor.init(customPath: file.path, withDefinitions: withDefinitions);
}
```

## 🛠 Building the Database

Place your `oewn.sqlite` (~165 MB source file) at `tool/db/oewn.sqlite`, then:

```bash
# Light build only (~28 MB)
dart run tool/build_database.dart tool/db/oewn.sqlite

# Full build only (~40 MB)
dart run tool/build_database.dart tool/db/oewn.sqlite --full

# Both at once
dart run tool/build_database.dart tool/db/oewn.sqlite --all

# Or via melos
melos run build
melos run build:full
melos run build:all
```

## 📊 Database Stats

| Component              | Light   | Full    | Description                          |
|:-----------------------|:--------|:--------|:-------------------------------------|
| **Words**              | 3.0 MB  | 3.0 MB  | ~150k unique lemmas                  |
| **Concepts**           | 1.36 MB | 1.36 MB | ~120k Synsets                        |
| **Senses**             | 3.4 MB  | 3.4 MB  | ~210k Word-Concept pairs             |
| **Semantic Relations** | 3.7 MB  | 3.7 MB  | Hypernyms, Holonyms, Entailments     |
| **Lexical Relations**  | 4.0 MB  | 4.0 MB  | Antonyms, Derivations                |
| **Indexes**            | ~11 MB  | ~11 MB  | `COLLATE NOCASE` indexes             |
| **Definitions**        | —       | ~10 MB  | Synset glosses (~120k rows)          |
| **Examples**           | —       | ~2 MB   | Usage sentences from `samples` table |
| **Total**              | ~28 MB  | ~40 MB  |                                      |

## 📂 License

- **Package License:** MIT
- **Database:** [Open English WordNet 2025](https://github.com/x-englishwordnet/sqlite) (v2.3.2),
  licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Commercial use requires attribution to the Open English WordNet project in your
app's About / Licenses section.