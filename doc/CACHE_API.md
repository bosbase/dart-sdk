# Cache API (Dart SDK)

BosBase caches combine fast in-memory [FreeCache](https://github.com/coocood/freecache) storage with a persistent database copy. Each cache is safe to use in single-node or cluster deployments: when the value is missing from FreeCache, BosBase automatically falls back to the database and rehydrates the cache.

The Dart SDK exposes cache management through `pb.caches`.

## Manage cache configurations

```dart
import "package:bosbase/bosbase.dart";

final pb = Bosbase("http://127.0.0.1:8090");
await pb.admins.authWithPassword("root@example.com", "hunter2");

// Create a 64MB cache with a 5 minute TTL and 25ms read timeout.
await pb.caches.create(
  name: "ai-session",
  sizeBytes: 64 * 1024 * 1024,
  defaultTTLSeconds: 300,
  readTimeoutMs: 25,
);

// Inspect all caches.
final caches = await pb.caches.list();

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

// Delete the entry when no longer needed.
await pb.caches.deleteEntry("ai-session", "dialog:42");
```

### Cluster-aware behaviour

1. **Write-through persistence** – every `setEntry` writes to FreeCache and `_cache_entries`, allowing other nodes to reload the value immediately.
2. **Read fallback** – BosBase reads from FreeCache first. If the entry is missing, expired, or the read times out, it pulls from the database and refreshes FreeCache automatically.
3. **Automatic cleanup** – expired entries are ignored and removed from the database when encountered, keeping all nodes consistent.

Use caches when you need ultra-fast responses that still survive restarts or must be shared between BosBase nodes (prompt caches, feature flags, short-lived query results, etc.).

