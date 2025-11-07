# Cache API (Dart SDK)

BosBase caches combine fast in-memory [FreeCache](https://github.com/coocood/freecache) storage with a persistent database copy. Each cache is safe to use in single-node or cluster deployments: when the value is missing from FreeCache, BosBase automatically falls back to the database and rehydrates the cache.

The Dart SDK exposes cache management through `pb.caches`.

## List available caches

The `list()` function allows you to query and retrieve all currently available caches, including their names and capacities. This is particularly useful for AI systems to discover existing caches before creating new ones, avoiding duplicate cache creation.

```dart
import "package:bosbase/bosbase.dart";

final pb = Bosbase("http://127.0.0.1:8090");
await pb.admins.authWithPassword("root@example.com", "hunter2");

// Query all available caches
final caches = await pb.caches.list();

// Each CacheConfigSummary object contains:
// - name: String - The cache identifier
// - sizeBytes: int - The cache capacity in bytes
// - defaultTTLSeconds: int - Default expiration time
// - readTimeoutMs: int - Read timeout in milliseconds
// - created: String? - Creation timestamp (RFC3339)
// - updated: String? - Last update timestamp (RFC3339)

// Example: Find a cache by name and check its capacity
final matchingCaches = caches.where((c) => c.name == "ai-session");
if (matchingCaches.isNotEmpty) {
  final targetCache = matchingCaches.first;
  print("Cache '${targetCache.name}' has capacity of ${targetCache.sizeBytes} bytes");
  // Use the existing cache directly
} else {
  print("Cache not found, create a new one if needed");
}
```

## Manage cache configurations

```dart
import "package:bosbase/bosbase.dart";

final pb = Bosbase("http://127.0.0.1:8090");
await pb.admins.authWithPassword("root@example.com", "hunter2");

// List all available caches (including name and capacity).
// This is useful for AI to discover existing caches before creating new ones.
final caches = await pb.caches.list();
print("Available caches: $caches");
// Output example:
// [
//   CacheConfigSummary(
//     name: "ai-session",
//     sizeBytes: 67108864,
//     defaultTTLSeconds: 300,
//     readTimeoutMs: 25,
//     created: "2024-01-15T10:30:00Z",
//     updated: "2024-01-15T10:30:00Z"
//   ),
//   CacheConfigSummary(
//     name: "query-cache",
//     sizeBytes: 33554432,
//     defaultTTLSeconds: 600,
//     readTimeoutMs: 50,
//     created: "2024-01-14T08:00:00Z",
//     updated: "2024-01-14T08:00:00Z"
//   )
// ]

// Find an existing cache by name
final matchingCaches = caches.where((c) => c.name == "ai-session");
if (matchingCaches.isNotEmpty) {
  final existingCache = matchingCaches.first;
  print("Found cache '${existingCache.name}' with capacity ${existingCache.sizeBytes} bytes");
  // Use the existing cache directly without creating a new one
} else {
  // Create a new cache only if it doesn't exist
  await pb.caches.create(
    name: "ai-session",
    sizeBytes: 64 * 1024 * 1024,
    defaultTTLSeconds: 300,
    readTimeoutMs: 25,
  );
}

// Update limits after observing usage.
await pb.caches.update("ai-session", body: {"defaultTTLSeconds": 120});

// Remove the cache (clears FreeCache + DB rows).
await pb.caches.delete("ai-session");
```

| Field | Description |
|-------|-------------|
| `sizeBytes` | Approximate FreeCache buffer size. Values smaller than 512KB or larger than 512MB are clamped. |
| `defaultTTLSeconds` | Default expiration for entries. `0` means “never expires” unless overwritten per entry. |
| `readTimeoutMs` | Maximum time spent waiting for a FreeCache segment lock before falling back to the database. |

## Work with cache entries

```dart
// Store a structured value with a per-entry TTL of 90 seconds.
await pb.caches.setEntry(
  "ai-session",
  "dialog:42",
  {
    "prompt": "Describe Saturn",
    "embedding": [/* vector */],
  },
  ttlSeconds: 90,
);

// Fetch the entry (source indicates cache or database).
final entry = await pb.caches.getEntry("ai-session", "dialog:42");
print(entry.source);   // cache | database
print(entry.expiresAt); // RFC3339 string or null if no TTL

// Renew an entry's TTL without changing its value.
// This extends the expiration time by the specified TTL (or uses the cache's default TTL if omitted).
final renewed = await pb.caches.renewEntry("ai-session", "dialog:42", ttlSeconds: 120); // extend by 120 seconds
print(renewed.expiresAt); // new expiration time

// Delete the entry when no longer needed.
await pb.caches.deleteEntry("ai-session", "dialog:42");
```

### Cluster-aware behaviour

1. **Write-through persistence** – every `setEntry` writes to FreeCache and `_cache_entries`, allowing other nodes to reload the value immediately.
2. **Read fallback** – BosBase reads from FreeCache first. If the entry is missing, expired, or the read times out, it pulls from the database and refreshes FreeCache automatically.
3. **Automatic cleanup** – expired entries are ignored and removed from the database when encountered, keeping all nodes consistent.

Use caches when you need ultra-fast responses that still survive restarts or must be shared between BosBase nodes (prompt caches, feature flags, short-lived query results, etc.).

