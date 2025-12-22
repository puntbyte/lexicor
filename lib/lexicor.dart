// lib/lexicor.dart

/// Lexicor — WordNet for Dart
///
/// Public re-exports for the package;
library;

// Export the main engine
export 'src/core/lexicor.dart';

// Export the categories
export 'src/enums/domain_category.dart';
export 'src/enums/relation_type.dart';
export 'src/enums/speech_part.dart';
export 'src/enums/storage_mode.dart';

// Export models
export 'src/models/concept.dart' hide ConceptImpl;
export 'src/models/related_word.dart';

// Export results
export 'src/results/lookup_result.dart';
export 'src/results/relation_result.dart';
