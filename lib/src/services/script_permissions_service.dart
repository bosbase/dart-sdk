import "../dtos/script.dart";
import "base_service.dart";

/// Service for managing script execution permissions.
///
/// All endpoints require superuser privileges.
class ScriptPermissionsService extends BaseService {
  ScriptPermissionsService(super.client);

  static const String _basePath = "/api/script-permissions";

  Future<ScriptPermissionRecord> create({
    required String scriptName,
    String? scriptId,
    required String content,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final normalizedName = _normalizeName(scriptName);
    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      throw ArgumentError("content is required");
    }

    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["script_name"] ??= normalizedName;
    enrichedBody["content"] ??= normalizedContent;
    if (scriptId != null && scriptId.trim().isNotEmpty) {
      enrichedBody["script_id"] ??= scriptId.trim();
    }

    return client
        .send<Map<String, dynamic>>(
          _basePath,
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptPermissionRecord.fromJson);
  }

  Future<ScriptPermissionRecord> get(
    String scriptName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final normalizedName = _normalizeName(scriptName);

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(normalizedName)}",
          query: query,
          headers: headers,
        )
        .then(ScriptPermissionRecord.fromJson);
  }

  Future<ScriptPermissionRecord> update(
    String scriptName, {
    String? scriptId,
    String? content,
    String? newScriptName,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final normalizedName = _normalizeName(scriptName);

    final enrichedBody = Map<String, dynamic>.of(body);
    if (scriptId != null) {
      enrichedBody["script_id"] = scriptId.trim();
    }
    if (newScriptName != null) {
      enrichedBody["script_name"] = _normalizeName(newScriptName);
    }
    if (content != null) {
      enrichedBody["content"] = content.trim();
    }

    return client
        .send<Map<String, dynamic>>(
          "$_basePath/${Uri.encodeComponent(normalizedName)}",
          method: "PATCH",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(ScriptPermissionRecord.fromJson);
  }

  Future<void> delete(
    String scriptName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final normalizedName = _normalizeName(scriptName);

    return client.send(
      "$_basePath/${Uri.encodeComponent(normalizedName)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  String _normalizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("scriptName is required");
    }
    return trimmed;
  }
}
