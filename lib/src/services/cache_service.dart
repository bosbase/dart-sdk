import "../client.dart";
import "base_service.dart";

class CacheConfigSummary {
  final String name;
  final int sizeBytes;
  final int defaultTTLSeconds;
  final int readTimeoutMs;
  final String? created;
  final String? updated;

  CacheConfigSummary({
    required this.name,
    required this.sizeBytes,
    required this.defaultTTLSeconds,
    required this.readTimeoutMs,
    this.created,
    this.updated,
  });

  factory CacheConfigSummary.fromJson(Map<String, dynamic> json) {
    return CacheConfigSummary(
      name: (json["name"] as String?) ?? "",
      sizeBytes: json["sizeBytes"] is int
          ? json["sizeBytes"] as int
          : int.tryParse("${json["sizeBytes"]}") ?? 0,
      defaultTTLSeconds: json["defaultTTLSeconds"] is int
          ? json["defaultTTLSeconds"] as int
          : int.tryParse("${json["defaultTTLSeconds"]}") ?? 0,
      readTimeoutMs: json["readTimeoutMs"] is int
          ? json["readTimeoutMs"] as int
          : int.tryParse("${json["readTimeoutMs"]}") ?? 0,
      created: json["created"] as String?,
      updated: json["updated"] as String?,
    );
  }
}

class CacheEntry {
  final String cache;
  final String key;
  final dynamic value;
  final String? source;
  final String? expiresAt;

  CacheEntry({
    required this.cache,
    required this.key,
    this.value,
    this.source,
    this.expiresAt,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      cache: (json["cache"] as String?) ?? "",
      key: (json["key"] as String?) ?? "",
      value: json["value"],
      source: json["source"] as String?,
      expiresAt: json["expiresAt"] as String?,
    );
  }
}

/// The service that handles the **Cache APIs**.
///
/// Usually shouldn't be initialized manually and instead
/// [Bosbase.caches] should be used.
class CacheService extends BaseService {
  CacheService(super.client);

  Future<List<CacheConfigSummary>> list({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final response = await client.send<Map<String, dynamic>>(
      "/api/cache",
      query: query,
      headers: headers,
    );
    final items =
        (response["items"] as List<dynamic>?) ?? const [];
    return items
        .map(
          (item) => CacheConfigSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<CacheConfigSummary> create({
    required String name,
    int? sizeBytes,
    int? defaultTTLSeconds,
    int? readTimeoutMs,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["name"] = name;
    if (sizeBytes != null) enrichedBody["sizeBytes"] = sizeBytes;
    if (defaultTTLSeconds != null) {
      enrichedBody["defaultTTLSeconds"] = defaultTTLSeconds;
    }
    if (readTimeoutMs != null) {
      enrichedBody["readTimeoutMs"] = readTimeoutMs;
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/cache",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(CacheConfigSummary.fromJson);
  }

  Future<CacheConfigSummary> update(
    String name, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "/api/cache/${Uri.encodeComponent(name)}",
          method: "PATCH",
          body: body,
          query: query,
          headers: headers,
        )
        .then(CacheConfigSummary.fromJson);
  }

  Future<void> delete(
    String name, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "/api/cache/${Uri.encodeComponent(name)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  Future<CacheEntry> setEntry(
    String cache,
    String key,
    dynamic value, {
    int? ttlSeconds,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["value"] = value;
    if (ttlSeconds != null) {
      enrichedBody["ttlSeconds"] = ttlSeconds;
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/cache/${Uri.encodeComponent(cache)}/entries/${Uri.encodeComponent(key)}",
          method: "PUT",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(CacheEntry.fromJson);
  }

  Future<CacheEntry> getEntry(
    String cache,
    String key, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "/api/cache/${Uri.encodeComponent(cache)}/entries/${Uri.encodeComponent(key)}",
          query: query,
          headers: headers,
        )
        .then(CacheEntry.fromJson);
  }

  Future<CacheEntry> renewEntry(
    String cache,
    String key, {
    int? ttlSeconds,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    if (ttlSeconds != null) {
      enrichedBody["ttlSeconds"] = ttlSeconds;
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/cache/${Uri.encodeComponent(cache)}/entries/${Uri.encodeComponent(key)}",
          method: "PATCH",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(CacheEntry.fromJson);
  }

  Future<void> deleteEntry(
    String cache,
    String key, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "/api/cache/${Uri.encodeComponent(cache)}/entries/${Uri.encodeComponent(key)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }
}
