// tool/build_database.dart
//
// Usage:
//   dart run tool/build_database.dart <path_to_oewn.sqlite>           # light build
//   dart run tool/build_database.dart <path_to_oewn.sqlite> --full    # full build (with definitions)
//   dart run tool/build_database.dart <path_to_oewn.sqlite> --all     # both builds

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/build_database.dart <path_to_oewn.sqlite> [--full|--all]');
    exit(1);
  }

  final sourcePath = args[0];
  if (!File(sourcePath).existsSync()) {
    print('Error: Source file not found at $sourcePath');
    exit(1);
  }

  final buildFull = args.contains('--full') || args.contains('--all');
  final buildLight = !args.contains('--full') || args.contains('--all');

  final projectRoot = Directory.current.path;

  if (buildLight) {
    _build(
      sourcePath: sourcePath,
      projectRoot: projectRoot,
      sqlFile: 'migration.sql',
      targetName: 'dictionary.sqlite',
      label: 'Light (no definitions)',
    );
  }

  if (buildFull) {
    _build(
      sourcePath: sourcePath,
      projectRoot: projectRoot,
      sqlFile: 'migration_full.sql',
      targetName: 'dictionary_full.sqlite',
      label: 'Full (with definitions)',
    );
  }
}

void _build({
  required String sourcePath,
  required String projectRoot,
  required String sqlFile,
  required String targetName,
  required String label,
}) {
  final sqlPath = p.join(projectRoot, 'tool', 'sql', sqlFile);
  final targetDbPath = p.join(projectRoot, 'lib', 'assets', targetName);

  print('\n--- Lexicor Database Builder: $label ---');
  print('Source : $sourcePath');
  print('Script : $sqlPath');
  print('Target : $targetDbPath');

  if (!File(sqlPath).existsSync()) {
    print('Error: SQL migration file not found at $sqlPath');
    exit(1);
  }

  // Delete existing target to start fresh
  if (File(targetDbPath).existsSync()) {
    print('Deleting old target database...');
    File(targetDbPath).deleteSync();
  } else {
    Directory(p.dirname(targetDbPath)).createSync(recursive: true);
  }

  final db = sqlite3.open(targetDbPath);

  try {
    print('Attaching source...');
    db.execute("ATTACH DATABASE '$sourcePath' AS source;");

    print('Reading SQL migration script...');
    final migrationSql = File(sqlPath).readAsStringSync();

    print('Executing migration (this may take a few seconds)...');
    db.execute(migrationSql);

    print('Detaching source...');
    db.execute('DETACH DATABASE source;');

    final size = File(targetDbPath).lengthSync();
    print('✅ Done! $targetName → ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  } catch (e) {
    print('❌ Error: $e');
    // Clean up incomplete output
    if (File(targetDbPath).existsSync()) File(targetDbPath).deleteSync();
    exit(1);
  } finally {
    db.dispose();
  }
}