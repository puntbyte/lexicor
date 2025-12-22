// example/check_db_size.dart

import 'dart:isolate';
import 'package:sqlite3/sqlite3.dart';

void main() async {
  // 1. Resolve path to the database
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:lexicor/assets/dictionary.sqlite'),
  );

  if (uri == null) {
    print('Could not find database asset.');
    return;
  }

  final path = uri.toFilePath();
  print('Checking database at: $path\n');

  // 2. Open directly (Read Only)
  final db = sqlite3.open(path, mode: OpenMode.readOnly);

  try {
    print('--- 📊 Total Database Size ---');
    _checkTotalSize(db);

    print('\n--- 📑 Table & Index Sizes ---');
    _checkTableSizes(db);
  } finally {
    db.dispose();
  }
}

void _checkTotalSize(Database db) {
  try {
    // Using the exact SQL you provided (requires SQLite 3.16+)
    final results = db.select('''
      SELECT
          page_count * page_size as size_bytes,
          (page_count * page_size) / 1024.0 / 1024.0 as size_mb
      FROM pragma_page_count(), pragma_page_size();
    ''');

    for (final row in results) {
      final mb = (row['size_mb'] as double).toStringAsFixed(2);
      print('Physical File Size: $mb MB (${row['size_bytes']} bytes)');
    }
  } catch (e) {
    print('Error checking total size: $e');
  }
}

void _checkTableSizes(Database db) {
  try {
    // Using the dbstat virtual table
    final results = db.select('''
      SELECT 
          name,
          SUM(pgsize) as size_bytes,
          ROUND(SUM(pgsize) / 1024.0 / 1024.0, 2) as size_mb
      FROM dbstat
      GROUP BY name
      ORDER BY size_bytes DESC;
    ''');

    if (results.isEmpty) {
      print('No data returned from dbstat.');
      return;
    }

    // Print Header
    print('${'Name'.padRight(35)} | ${'Size (MB)'.padLeft(10)} | Bytes');
    print('-' * 60);

    for (final row in results) {
      final name = row['name'].toString();
      final mb = row['size_mb'].toString(); // Already rounded in SQL
      final bytes = row['size_bytes'].toString();

      print('${name.padRight(35)} | ${mb.padLeft(10)} | $bytes');
    }
  } catch (e) {
    print('⚠️ Could not run `dbstat` query.');
    print('Reason: $e');
    print('NOTE: The `dbstat` virtual table is a compile-time option in SQLite.');
    print('It might not be enabled in the default `sqlite3` Dart package library on this OS.');
  }
}