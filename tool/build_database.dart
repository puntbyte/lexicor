import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/build_db.dart <path_to_source_oewn.sqlite>');
    exit(1);
  }

  final sourcePath = args[0];
  if (!File(sourcePath).existsSync()) {
    print('Error: Source file not found at $sourcePath');
    exit(1);
  }

  // Target paths
  final projectRoot = Directory.current.path;
  final sqlPath = p.join(projectRoot, 'tool', 'sql', 'migration.sql');
  final targetDbPath = p.join(projectRoot, 'lib', 'assets', 'dictionary.sqlite');

  print('--- Lexicor Database Builder ---');
  print('Source: $sourcePath');
  print('Target: $targetDbPath');

  // 1. Delete existing target to start fresh
  if (File(targetDbPath).existsSync()) {
    print('Deleting old target database...');
    File(targetDbPath).deleteSync();
  } else {
    // Ensure directory exists
    Directory(p.dirname(targetDbPath)).createSync(recursive: true);
  }

  // 2. Open new DB
  final db = sqlite3.open(targetDbPath);

  try {
    print('Attaching source...');
    // We must execute the ATTACH command separately because the SQL file
    // assumes 'source' alias but doesn't know the path.
    db.execute("ATTACH DATABASE '$sourcePath' AS source;");

    print('Reading SQL migration script...');
    final migrationSql = File(sqlPath).readAsStringSync();

    print('Executing migration (this may take a few seconds)...');
    db.execute(migrationSql);

    print('Detaching source...');
    db.execute('DETACH DATABASE source;');

    print('✅ Success! Database rebuilt.');

    // Check size
    final size = File(targetDbPath).lengthSync();
    print('Final Size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    db.dispose();
  }
}
