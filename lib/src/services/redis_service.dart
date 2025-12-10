import "base_service.dart";

class RedisKeySummary {
  final String key;

  RedisKeySummary(this.key);

  factory RedisKeySummary.fromJson(Map<String, dynamic> json) {
    return RedisKeySummary(json["key"] as String? ?? "");
  }
}

class RedisEntry<T> {
  final String key;
  final T value;
  final int? ttlSeconds;

  RedisEntry({
    required this.key,
    required this.value,
    this.ttlSeconds,
  });

  factory RedisEntry.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? valueMapper,
  }) {
    final mapper = valueMapper ?? (dynamic v) => v as T;
    return RedisEntry(
      key: (json["key"] as String?) ?? "",
      value: mapper(json["value"]),
      ttlSeconds: json["ttlSeconds"] is int
          ? json["ttlSeconds"] as int
          : int.tryParse("${json["ttlSeconds"] ?? ""}"),
    );
  }
}

class RedisListPage {
  final String cursor;
  final List<RedisKeySummary> items;

  RedisListPage({
    required this.cursor,
    required this.items,
  });

  factory RedisListPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json["items"] as List<dynamic>? ?? const [];
    return RedisListPage(
      cursor: (json["cursor"] as String?) ?? "",
      items: rawItems
          .map((item) => RedisKeySummary.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// Service for Redis key/value helpers exposed by the API.
class RedisService extends BaseService {
  RedisService(super.client);

  Future<RedisListPage> listKeys({
    String? cursor,
    String? pattern,
    int? count,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedQuery = Map<String, dynamic>.of(query);
    if (cursor != null) enrichedQuery["cursor"] = cursor;
    if (pattern != null) enrichedQuery["pattern"] = pattern;
    if (count != null) enrichedQuery["count"] = count;

    return client
        .send<Map<String, dynamic>>(
          "/api/redis/keys",
          query: enrichedQuery,
          headers: headers,
        )
        .then(RedisListPage.fromJson);
  }

  Future<RedisEntry<T>> createKey<T>(
    String key,
    T value, {
    int? ttlSeconds,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    T Function(dynamic)? valueMapper,
  }) {
    final normalizedKey = _normalizeKey(key);
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["key"] ??= normalizedKey;
    enrichedBody["value"] ??= value;
    if (ttlSeconds != null) {
      enrichedBody["ttlSeconds"] ??= ttlSeconds;
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/redis/keys",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then((data) => RedisEntry.fromJson(data, valueMapper: valueMapper));
  }

  Future<RedisEntry<T>> getKey<T>(
    String key, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    T Function(dynamic)? valueMapper,
  }) {
    final normalizedKey = _normalizeKey(key);

    return client
        .send<Map<String, dynamic>>(
          "/api/redis/keys/${Uri.encodeComponent(normalizedKey)}",
          query: query,
          headers: headers,
        )
        .then((data) => RedisEntry.fromJson(data, valueMapper: valueMapper));
  }

  Future<RedisEntry<T>> updateKey<T>(
    String key,
    T value, {
    int? ttlSeconds,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    T Function(dynamic)? valueMapper,
  }) {
    final normalizedKey = _normalizeKey(key);
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["value"] ??= value;
    if (ttlSeconds != null) {
      enrichedBody["ttlSeconds"] ??= ttlSeconds;
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/redis/keys/${Uri.encodeComponent(normalizedKey)}",
          method: "PUT",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then((data) => RedisEntry.fromJson(data, valueMapper: valueMapper));
  }

  Future<void> deleteKey(
    String key, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final normalizedKey = _normalizeKey(key);

    return client.send(
      "/api/redis/keys/${Uri.encodeComponent(normalizedKey)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  String _normalizeKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("key is required");
    }
    return trimmed;
  }
}
