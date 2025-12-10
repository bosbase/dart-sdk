class ScriptRecord {
  final String id;
  final String name;
  final String content;
  final String? description;
  final int version;
  final String? created;
  final String? updated;

  ScriptRecord({
    required this.id,
    required this.name,
    required this.content,
    required this.version,
    this.description,
    this.created,
    this.updated,
  });

  factory ScriptRecord.fromJson(Map<String, dynamic> json) {
    return ScriptRecord(
      id: (json["id"] as String?) ?? "",
      name: (json["name"] as String?) ?? "",
      content: (json["content"] as String?) ?? "",
      description: json["description"] as String?,
      version: json["version"] is int
          ? json["version"] as int
          : int.tryParse("${json["version"]}") ?? 0,
      created: json["created"] as String?,
      updated: json["updated"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "content": content,
      "description": description,
      "version": version,
      "created": created,
      "updated": updated,
    };
  }
}

class ScriptExecutionResult {
  final String output;

  ScriptExecutionResult(this.output);

  factory ScriptExecutionResult.fromJson(Map<String, dynamic> json) {
    return ScriptExecutionResult((json["output"] as String?) ?? "");
  }

  Map<String, dynamic> toJson() => {"output": output};
}

class ScriptPermissionRecord {
  final String id;
  final String scriptName;
  final String content;
  final int version;
  final String? scriptId;
  final String? created;
  final String? updated;

  ScriptPermissionRecord({
    required this.id,
    required this.scriptName,
    required this.content,
    required this.version,
    this.scriptId,
    this.created,
    this.updated,
  });

  factory ScriptPermissionRecord.fromJson(Map<String, dynamic> json) {
    return ScriptPermissionRecord(
      id: (json["id"] as String?) ?? "",
      scriptName: (json["script_name"] as String?) ??
          (json["scriptName"] as String?) ??
          "",
      content: (json["content"] as String?) ?? "",
      version: json["version"] is int
          ? json["version"] as int
          : int.tryParse("${json["version"]}") ?? 0,
      scriptId: (json["script_id"] as String?) ?? (json["scriptId"] as String?),
      created: json["created"] as String?,
      updated: json["updated"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "script_name": scriptName,
      "script_id": scriptId,
      "content": content,
      "version": version,
      "created": created,
      "updated": updated,
    };
  }
}
