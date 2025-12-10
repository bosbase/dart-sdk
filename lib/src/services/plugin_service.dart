import "package:http/http.dart" as http;
import "package:web_socket_channel/web_socket_channel.dart";

import "../sse/sse_client.dart";
import "base_service.dart";

const Set<String> _pluginHttpMethods = {
  "GET",
  "POST",
  "PUT",
  "PATCH",
  "DELETE",
  "HEAD",
  "OPTIONS",
};
const Set<String> _pluginSseMethods = {"SSE"};
const Set<String> _pluginWebSocketMethods = {"WS", "WEBSOCKET"};

/// PluginService forwards requests to the configured plugin proxy endpoint.
class PluginService extends BaseService {
  PluginService(super.client);

  /// Sends a plugin request using HTTP, SSE or WebSocket.
  ///
  /// - HTTP methods return a [Future] with the decoded response.
  /// - `SSE` returns an [SseClient] instance.
  /// - `WS`/`WEBSOCKET` return a [WebSocketChannel] instance.
  dynamic request<T>(
    String method,
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic> body = const {},
    List<http.MultipartFile> files = const [],
    List<String>? websocketProtocols,
  }) {
    final normalizedMethod = method.trim().toUpperCase();
    if (normalizedMethod.isEmpty) {
      throw ArgumentError("method is required");
    }

    final normalizedPath = _normalizePath(path);
    final mergedQuery = _mergePathQuery(path, query);

    if (_pluginSseMethods.contains(normalizedMethod)) {
      final url = _buildURL(normalizedPath, mergedQuery, includeToken: true);
      final enrichedHeaders = Map<String, String>.of(headers);
      if (!enrichedHeaders.containsKey("Authorization") &&
          client.authStore.isValid) {
        enrichedHeaders["Authorization"] = client.authStore.token;
      }
      return SseClient(
        url.toString(),
        headers: enrichedHeaders,
        httpClientFactory: client.httpClientFactory,
      );
    }

    if (_pluginWebSocketMethods.contains(normalizedMethod)) {
      final wsUrl = _buildWebSocketURL(normalizedPath, mergedQuery);
      return WebSocketChannel.connect(
        wsUrl,
        protocols: websocketProtocols,
      );
    }

    if (!_pluginHttpMethods.contains(normalizedMethod)) {
      throw ArgumentError(
        'Unsupported plugin method "$method", expected one of ${[
          ..._pluginHttpMethods,
          ..._pluginSseMethods,
          ..._pluginWebSocketMethods,
        ].join(", ")}',
      );
    }

    return client.send<T>(
      normalizedPath,
      method: normalizedMethod,
      query: mergedQuery,
      headers: headers,
      body: body,
      files: files,
    );
  }

  String _normalizePath(String path) {
    final trimmed = path.trim();
    final hasQuery = trimmed.contains("?");
    final cleanPath = hasQuery ? trimmed.split("?").first : trimmed;

    var normalized = cleanPath.replaceFirst(RegExp(r"^/+"), "");
    if (normalized.isEmpty) {
      return "/api/plugins";
    }

    if (!normalized.startsWith("api/plugins")) {
      normalized = "api/plugins/$normalized";
    }

    return "/$normalized";
  }

  Uri _buildURL(
    String path,
    Map<String, dynamic> query, {
    bool includeToken = false,
  }) {
    final enrichedQuery = Map<String, dynamic>.of(query);
    if (includeToken && client.authStore.isValid) {
      enrichedQuery["token"] ??= client.authStore.token;
    }

    return client.buildURL(path, enrichedQuery);
  }

  Uri _buildWebSocketURL(String path, Map<String, dynamic> query) {
    final url = _buildURL(path, query, includeToken: true);
    final isSecure = url.scheme == "https";
    return url.replace(scheme: isSecure ? "wss" : "ws");
  }

  Map<String, dynamic> _mergePathQuery(
    String path,
    Map<String, dynamic> query,
  ) {
    final merged = Map<String, dynamic>.of(query);
    final queryIndex = path.indexOf("?");
    if (queryIndex == -1 || queryIndex >= path.length - 1) {
      return merged;
    }

    final queryString = path.substring(queryIndex + 1);
    var pathQuery = <String, String>{};
    try {
      pathQuery = Uri.splitQueryString(queryString);
    } catch (_) {}

    for (final entry in pathQuery.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }

    return merged;
  }
}
