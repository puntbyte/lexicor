// test/utils/test_db.dart

import 'package:sqlite3/sqlite3.dart';

/// Creates an in-memory database with the full Lexicor schema and minimal test data.
///
/// Includes the [sample] table so that tests can exercise the full-database
/// code paths even without `dictionary_full.sqlite` on disk.
Database createTestDatabase({bool withSamples = false}) {
  final db = sqlite3.openInMemory()
    // 1. Schema
    ..execute('''
      CREATE TABLE part_of_speech (id CHAR(1) PRIMARY KEY, name VARCHAR(20));
      CREATE TABLE domain_category (id INTEGER PRIMARY KEY, name VARCHAR(32), part_of_speech_id CHAR(1));
      CREATE TABLE relationship_type (id INTEGER PRIMARY KEY, name VARCHAR(50), is_recursive BOOLEAN);
      CREATE TABLE word (id INTEGER PRIMARY KEY, text VARCHAR(80));
      CREATE TABLE synset (id INTEGER PRIMARY KEY, part_of_speech_id CHAR(1), domain_category_id INTEGER, definition TEXT);
      CREATE TABLE sense (id INTEGER PRIMARY KEY, word_id INTEGER, synset_id INTEGER, sense_sort_order INTEGER);
      CREATE TABLE morphological_form (id INTEGER PRIMARY KEY, text VARCHAR(70));
      CREATE TABLE word_morphology (word_id INTEGER, part_of_speech_id CHAR(1), morphological_form_id INTEGER);
      CREATE TABLE sample (id INTEGER PRIMARY KEY, synset_id INTEGER, text TEXT);
      CREATE TABLE semantic_relationship (
        source_synset_id INTEGER, target_synset_id INTEGER, relationship_type_id INTEGER,
        PRIMARY KEY (source_synset_id, target_synset_id, relationship_type_id)
      ) WITHOUT ROWID;
      CREATE TABLE lexical_relationship (
        source_sense_id INTEGER, target_sense_id INTEGER, relationship_type_id INTEGER,
        PRIMARY KEY (source_sense_id, target_sense_id, relationship_type_id)
      ) WITHOUT ROWID;
    ''')
    // 2. Lookup data
    ..execute("INSERT INTO part_of_speech VALUES ('n','noun'),('v','verb'),('a','adjective');")
    ..execute(
      "INSERT INTO domain_category VALUES (3,'noun.tops','n'),(29,'verb.body','v'),(0,'adj.all','a');",
    )
    // relation types: hypernym(1, recursive), antonym(30, non-recursive), hyponym(2, recursive)
    ..execute(
      "INSERT INTO relationship_type VALUES (1,'hypernym',1),(2,'hyponym',1),(30,'antonym',0);",
    )
    // 3. Words
    // IDs: run=1, move=2, sprint=3, fast=4, slow=5, locomote=6
    ..execute(
      "INSERT INTO word VALUES (1,'run'),(2,'move'),(3,'sprint'),(4,'fast'),(5,'slow'),(6,'locomote');",
    )
    // 4. Synsets + definitions
    //   run->100, move->101, sprint->102, locomote->103
    ..execute('''
      INSERT INTO synset VALUES
        (100,'v',29,'move fast by using one''s feet'),
        (101,'v',29,'change location; move'),
        (102,'v',29,'run or move very quickly'),
        (103,'v',29,'move from one place to another');
    ''')
    // 5. Senses
    ..execute('INSERT INTO sense VALUES (10,1,100,1),(11,2,101,1),(12,3,102,1),(13,6,103,1);')
    // 6. Semantic relations
    //   run(100) --hypernym--> move(101)
    //   move(101) --hypernym--> locomote(103)
    //   move(101) --hyponym--> run(100)
    ..execute('''
      INSERT INTO semantic_relationship VALUES
        (100,101,1),
        (101,103,1),
        (101,100,2);
    ''')
    // 7. Lexical relations — fast(4)<->slow(5) antonym
    ..execute(
      "INSERT INTO synset VALUES (200,'a',0,'moving quickly'),(201,'a',0,'not moving quickly');",
    )
    ..execute('INSERT INTO sense VALUES (20,4,200,1),(21,5,201,1);')
    ..execute('INSERT INTO lexical_relationship VALUES (20,21,30);')
    // 8. Morphology — 'ran' inflects to 'run'
    ..execute("INSERT INTO morphological_form VALUES (50,'ran');")
    ..execute("INSERT INTO word_morphology VALUES (1,'v',50);")
    // 9. Synonyms — add 'jog' to synset 100 so synonyms returns 2 words
    ..execute("INSERT INTO word VALUES (7,'jog');")
    ..execute('INSERT INTO sense VALUES (14,7,100,2);');

  // 10. Sample sentences (only inserted when testing full-DB paths)
  if (withSamples) {
    db.execute('''
      INSERT INTO sample VALUES
        (1, 100, 'she ran to catch the bus'),
        (2, 100, 'he runs every morning');
    ''');
  }

  return db;
}
