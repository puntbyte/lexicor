import 'package:sqlite3/sqlite3.dart';

/// Creates an in-memory database with the Lexicor schema and minimal test data.
Database createTestDatabase() {
  final db = sqlite3.openInMemory();

  // 1. Setup Schema
  db.execute('''
    CREATE TABLE part_of_speech (id CHAR(1) PRIMARY KEY, name VARCHAR(20));
    CREATE TABLE domain_category (id INTEGER PRIMARY KEY, name VARCHAR(32), part_of_speech_id CHAR(1));
    CREATE TABLE relationship_type (id INTEGER PRIMARY KEY, name VARCHAR(50), is_recursive BOOLEAN);
    CREATE TABLE word (id INTEGER PRIMARY KEY, text VARCHAR(80));
    CREATE TABLE synset (id INTEGER PRIMARY KEY, part_of_speech_id CHAR(1), domain_category_id INTEGER);
    CREATE TABLE sense (id INTEGER PRIMARY KEY, word_id INTEGER, synset_id INTEGER, sense_sort_order INTEGER);
    
    CREATE TABLE morphological_form (id INTEGER PRIMARY KEY, text VARCHAR(70));
    CREATE TABLE word_morphology (word_id INTEGER, part_of_speech_id CHAR(1), morphological_form_id INTEGER);

    CREATE TABLE semantic_relationship (source_synset_id INTEGER, target_synset_id INTEGER, relationship_type_id INTEGER, PRIMARY KEY (source_synset_id, target_synset_id, relationship_type_id)) WITHOUT ROWID;
    CREATE TABLE lexical_relationship (source_sense_id INTEGER, target_sense_id INTEGER, relationship_type_id INTEGER, PRIMARY KEY (source_sense_id, target_sense_id, relationship_type_id)) WITHOUT ROWID;
  ''');

  // 2. Insert Lookups
  db.execute("INSERT INTO part_of_speech VALUES ('n', 'noun'), ('v', 'verb'), ('a', 'adjective');");
  db.execute("INSERT INTO domain_category VALUES (3, 'noun.Tops', 'n'), (29, 'verb.body', 'v'), (0, 'adj.all', 'a');");
  db.execute("INSERT INTO relationship_type VALUES (1, 'hypernym', 1), (30, 'antonym', 0);");

  // 3. Insert Data
  // Words (Base Forms)
  db.execute("INSERT INTO word VALUES (1, 'run'), (2, 'move'), (3, 'sprint'), (4, 'fast'), (5, 'slow');");

  // Synsets (Concepts)
  db.execute("INSERT INTO synset VALUES (100, 'v', 29), (101, 'v', 29), (102, 'v', 29);");

  // Senses (Links)
  // run(v) -> 100, move(v) -> 101, sprint(v) -> 102
  db.execute("INSERT INTO sense VALUES (10, 1, 100, 1), (11, 2, 101, 1), (12, 3, 102, 1);");

  // 4. Insert Relations
  // Semantic: Run(100) is Hypernym(1) of Sprint(102) -> Inverted: Move(101) is Hypernym of Run(100)
  db.execute("INSERT INTO semantic_relationship VALUES (100, 101, 1);");

  // Lexical: Fast(4) is Antonym(30) of Slow(5)
  // Need senses for fast/slow first
  db.execute("INSERT INTO synset VALUES (200, 'a', 0), (201, 'a', 0);");
  db.execute("INSERT INTO sense VALUES (20, 4, 200, 1), (21, 5, 201, 1);");
  db.execute("INSERT INTO lexical_relationship VALUES (20, 21, 30);");

  // 5. Insert Morphology
  // Inflection 'ran' points to Base 'run'
  db.execute("INSERT INTO morphological_form VALUES (50, 'ran');");
  db.execute("INSERT INTO word_morphology VALUES (1, 'v', 50);"); // 1='run'

  return db;
}