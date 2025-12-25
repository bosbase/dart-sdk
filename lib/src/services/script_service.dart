import "package:http/http.dart" as http;
import "package:web_socket_channel/web_socket_channel.dart";

import "../dtos/script.dart";
import "../sse/sse_client.dart";
import "base_service.dart";

/// Service for managing server-side scripts.
///
/// All endpoints require superuser privileges.
class ScriptService extends BaseService {
  ScriptService(super.client);

  static const String _basePath = "/api/scripts";

  Future<ScriptRecord> create(
    String name,
    String content, {
    String? description,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError("script content is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["name"] ??= trimmedName;
    enrichedBody["content"] ??= trimmedContent;
    if (description != null) {
      enrichedBody["description"] = description;
    }

    return client
        .send<Map<String, dynamic>>(
          _basePath,
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptRecord.fromJson);
  }

  Future<ScriptExecutionResult> command(
    String command, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("command is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["command"] ??= trimmed;

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/command",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptExecutionResult.fromJson);
  }

  Future<ScriptCommandAsyncResponse> commandAsync(
    String command, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("command is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["command"] ??= trimmed;
    enrichedBody["async"] ??= true;

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/command",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptCommandAsyncResponse.fromJson);
  }

  Future<ScriptCommandJob> commandStatus(
    String id, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("command id is required");
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/command/${Uri.encodeComponent(trimmed)}",
          query: query,
          headers: headers,
        )
        .then(ScriptCommandJob.fromJson);
  }

  Future<ScriptUploadResult> upload(
    http.MultipartFile file, {
    String? path,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    if (path != null && path.trim().isNotEmpty) {
      enrichedBody["path"] = path.trim();
    }

    final normalizedFile = file.field == "file"
        ? file
        : http.MultipartFile(
            "file",
            file.finalize(),
            file.length,
            filename: file.filename,
            contentType: file.contentType,
          );

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/upload",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
          files: [normalizedFile],
        )
        .then(ScriptUploadResult.fromJson);
  }

  Future<ScriptRecord> get(
    String name, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(trimmedName)}",
          query: query,
          headers: headers,
        )
        .then(ScriptRecord.fromJson);
  }

  Future<List<ScriptRecord>> list({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final response = await client.send<Map<String, dynamic>>(
      _basePath,
      query: query,
      headers: headers,
    );
    final items = response["items"] as List<dynamic>? ?? const [];
    return items
        .map((item) => ScriptRecord.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ScriptRecord> update(
    String name, {
    String? content,
    String? description,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");
    final hasContent = content != null;
    final hasDescription = description != null;

    if (!hasContent && !hasDescription) {
      throw ArgumentError(
        "at least one of content or description must be provided",
      );
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    if (hasContent) {
      enrichedBody["content"] = content;
    }
    if (hasDescription) {
      enrichedBody["description"] = description;
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(trimmedName)}",
          method: "PATCH",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptRecord.fromJson);
  }

  Future<ScriptExecutionResult> execute(
    String name, {
    List<dynamic>? arguments,
    String? functionName,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");

    final enrichedBody = Map<String, dynamic>.of(body);
    if (arguments != null) {
      enrichedBody["arguments"] ??= _normalizeArgs(arguments);
    }
    if (functionName != null && functionName.trim().isNotEmpty) {
      enrichedBody["function_name"] ??= functionName.trim();
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(trimmedName)}/execute",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptExecutionResult.fromJson);
  }

  SseClient executeSSE(
    String name, {
    List<dynamic>? arguments,
    String? functionName,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");
    final url = _buildExecuteURL(
      "$_basePath/${Uri.encodeComponent(trimmedName)}/execute/sse",
      arguments: arguments,
      functionName: functionName,
      query: query,
      includeToken: true,
    );

    final enrichedHeaders = Map<String, String>.of(headers);
    if (!enrichedHeaders.containsKey("Authorization") &&
        client.authStore.token.isNotEmpty) {
      enrichedHeaders["Authorization"] = client.authStore.token;
    }

    return SseClient(
      url.toString(),
      headers: enrichedHeaders,
      httpClientFactory: client.httpClientFactory,
    );
  }

  WebSocketChannel executeWebSocket(
    String name, {
    List<dynamic>? arguments,
    String? functionName,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    List<String>? websocketProtocols,
  }) {
    final trimmedName = _normalizeName(name, "script name is required");
    final url = _buildExecuteURL(
      "$_basePath/${Uri.encodeComponent(trimmedName)}/execute/ws",
      arguments: arguments,
      functionName: functionName,
      query: query,
      includeToken: true,
    );

    final wsUrl = url.replace(scheme: url.scheme == "https" ? "wss" : "ws");

    return WebSocketChannel.connect(
      wsUrl,
      protocols: websocketProtocols,
    );
  }

  Future<ScriptExecuteAsyncResponse> executeAsync(
    String name, {
    List<dynamic>? arguments,
    String? functionName,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");

    final enrichedBody = Map<String, dynamic>.of(body);
    if (arguments != null) {
      enrichedBody["arguments"] ??= _normalizeArgs(arguments);
    }
    if (functionName != null && functionName.trim().isNotEmpty) {
      enrichedBody["function_name"] ??= functionName.trim();
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/async/${Uri.encodeComponent(trimmedName)}/execute",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptExecuteAsyncResponse.fromJson);
  }

  Future<ScriptExecuteJob> executeAsyncStatus(
    String id, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("execution job id is required");
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/async/${Uri.encodeComponent(trimmed)}",
          query: query,
          headers: headers,
        )
        .then(ScriptExecuteJob.fromJson);
  }

  Future<ScriptExecutionResult> wasm(
    String cliOptions,
    String wasmName, {
    String? params,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = wasmName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError("wasm name is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["options"] ??= cliOptions.trim();
    enrichedBody["wasm"] ??= trimmedName;
    enrichedBody["params"] ??= params?.trim() ?? "";

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/wasm",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptExecutionResult.fromJson);
  }

  Future<ScriptWasmAsyncResponse> wasmAsync(
    String cliOptions,
    String wasmName, {
    String? params,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = wasmName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError("wasm name is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["options"] ??= cliOptions.trim();
    enrichedBody["wasm"] ??= trimmedName;
    enrichedBody["params"] ??= params?.trim() ?? "";

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/wasm/async",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptWasmAsyncResponse.fromJson);
  }

  Future<ScriptWasmJob> wasmAsyncStatus(
    String id, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("wasm execution job id is required");
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/wasm/async/${Uri.encodeComponent(trimmed)}",
          query: query,
          headers: headers,
        )
        .then(ScriptWasmJob.fromJson);
  }

  Future<void> delete(
    String name, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");

    return client.send(
      "$_basePath/${Uri.encodeComponent(trimmedName)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  String _normalizeName(String value, String error) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError(error);
    }
    return trimmed;
  }

  List<String> _normalizeArgs(List<dynamic> arguments) {
    return arguments.map((arg) => arg is String ? arg : arg.toString()).toList();
  }

  Uri _buildExecuteURL(
    String path, {
    List<dynamic>? arguments,
    String? functionName,
    Map<String, dynamic> query = const {},
    bool includeToken = false,
  }) {
    final enrichedQuery = Map<String, dynamic>.of(query);

    if (arguments != null && arguments.isNotEmpty) {
      enrichedQuery["arguments"] = _normalizeArgs(arguments);
    }
    if (functionName != null && functionName.trim().isNotEmpty) {
      enrichedQuery["function_name"] = functionName.trim();
    }
    if (includeToken && client.authStore.token.isNotEmpty) {
      enrichedQuery["token"] ??= client.authStore.token;
    }

    return client.buildURL(path, enrichedQuery);
  }
}
