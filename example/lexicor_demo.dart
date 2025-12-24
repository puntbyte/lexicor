// example/lexicor_demo.dart

import 'package:lexicor/lexicor.dart';

void main() async {
  printBanner('Lexicor — WordNet Demo');

  // --- Initialize Lexicor ---
  // Use `loadInMemory: true` for the fastest queries (recommended for servers).
  // Use `loadInMemory: false` for instant startup (recommended for mobile apps).
  printSection('Initializing Lexicor (in Memory)...');
  final lexicor = await Lexicor.init(mode: StorageMode.inMemory);
  print('✅ Lexicor is ready.');

  // --- Run Demonstrations ---
  await demonstrateLookup(lexicor, 'went'); // Shows morphology: went -> go
  await demonstrateLookup(lexicor, 'go');
  await demonstrateLookup(lexicor, 'fetch');
  await demonstrateLookup(lexicor, 'fetching');
  await demonstrateLookup(lexicor, 'fetches');
  await demonstrateLookup(lexicor, 'xyz');
  await demonstrateLookup(lexicor, 'bank'); // Shows multiple meanings
  await demonstrateLookup(lexicor, 'better'); // Shows adjective morphology

  // --- Clean Up ---
  lexicor.close();
  printBanner('Demo Complete');
}

/// Demonstrates the full lookup and relation-finding flow.
Future<void> demonstrateLookup(Lexicor lexicor, String wordToLookup) async {
  printSection('Looking up: "$wordToLookup"');

  // 1. LOOKUP
  // This is the primary way to find concepts for a word.
  // It automatically handles morphology (e.g., "went" becomes "go").
  final lookupResult = lexicor.lookup(wordToLookup);

  // The result tells you what forms were searched and what concepts were found.
  print(
    ' • Searched for: "${lookupResult.query}"\n'
    ' • Resolved to: ${lookupResult.resolvedForms.join(', ')}\n'
    ' • Found ${lookupResult.concepts.length} unique concepts.',
  );

  // No concepts found, end of demo for this word.
  if (lookupResult.isEmpty) {
    return;
  }

  // 2. FILTERING CONCEPTS
  // You can easily filter the concepts found in the result.
  final nouns = lookupResult.bySpeechPart(SpeechPart.noun);
  final verbs = lookupResult.bySpeechPart(SpeechPart.verb);
  final adjectives = lookupResult.bySpeechPart(SpeechPart.adjective);
  final adverbs = lookupResult.bySpeechPart(SpeechPart.adverb);
  final adjectiveSatellites = lookupResult.bySpeechPart(SpeechPart.adjectiveSatellite);

  print(' • Noun meanings: ${nouns.length}');
  print(' • Verb meanings: ${verbs.length}');
  print(' • Adjective meanings: ${adjectives.length}');
  print(' • Adverb meanings: ${adverbs.length}');
  print(' • Adjective Satellite meanings: ${adjectiveSatellites.length}');

  // 3. GETTING RELATIONS
  // Let's explore the *first* concept found for our word.
  final primaryConcept = lookupResult.primary!;
  print(
    '\nExploring relationships for the primary concept of "${lookupResult.resolvedForms.last}":',
  );

  // The `related()` method returns a rich result object with all relations.
  final relationResult = lexicor.related(primaryConcept);
  print(' • Found ${relationResult.items.length} total relations.');

  // 4. FILTERING RELATIONS
  // The RelationResult object has helpers to find specific relationship types.
  final hypernyms = relationResult.byType(RelationType.hypernym);
  final hyponyms = relationResult.byType(RelationType.hyponym);
  final antonyms = relationResult.byType(RelationType.antonym);
  final meronyms = relationResult.byType(RelationType.partMeronym);

  // Print the findings in a structured way.
  if (hypernyms.isNotEmpty) {
    print('   ➡️ Is a type of (Hypernyms): ${hypernyms.map((r) => r.word).take(5).join(', ')}');
  }
  if (hyponyms.isNotEmpty) {
    print('   ➡️ Has types (Hyponyms): ${hyponyms.map((r) => r.word).take(5).join(', ')}');
  }
  if (meronyms.isNotEmpty) {
    print('   ➡️ Has parts (Meronyms): ${meronyms.map((r) => r.word).take(5).join(', ')}');
  }
  if (antonyms.isNotEmpty) {
    print('   ➡️ Has opposite (Antonyms): ${antonyms.map((r) => r.word).join(', ')}');
  }
}

// --- Helper Functions for Clean Output ---

void printBanner(String text) {
  print('\n========================================');
  print('  $text');
  print('========================================');
}

void printSection(String title) {
  final divider = '-' * (title.length + 4);
  print('\n$divider\n  $title\n$divider');
}
