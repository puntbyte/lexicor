// lib/src/enums/storage_mode.dart

/// Defines how the Lexicor database is loaded and accessed.
enum StorageMode {
  /// Loads the entire database into RAM.
  ///
  /// - **Pros:** Fastest possible lookups (nanosecond latency).
  /// - **Cons:** Higher memory usage (~10MB) and slower initialization (~50ms to copy data).
  /// - **Best for:** Server-side applications or heavy NLP processing tasks.
  inMemory,

  /// Reads from the file system on demand.
  ///
  /// - **Pros:** Instant startup and minimal memory footprint.
  /// - **Cons:** Slightly slower lookups (microsecond latency) due to disk I/O.
  /// - **Best for:** Mobile apps (Flutter) or CLI tools where startup time matters.
  onDisk,
}
