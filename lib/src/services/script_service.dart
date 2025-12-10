import "../dtos/script.dart";
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
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmedName = _normalizeName(name, "script name is required");

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(trimmedName)}/execute",
          method: "POST",
          query: query,
          headers: headers,
        )
        .then(ScriptExecutionResult.fromJson);
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
}
