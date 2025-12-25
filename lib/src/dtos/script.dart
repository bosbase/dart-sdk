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
  final String? stdout;
  final String? stderr;
  final String? duration;

  ScriptExecutionResult({
    required this.output,
    this.stdout,
    this.stderr,
    this.duration,
  });

  factory ScriptExecutionResult.fromJson(Map<String, dynamic> json) {
    return ScriptExecutionResult(
      output: (json["output"] as String?) ?? "",
      stdout: json["stdout"] as String?,
      stderr: json["stderr"] as String?,
      duration: json["duration"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        "output": output,
        "stdout": stdout,
        "stderr": stderr,
        "duration": duration,
      };
}

class ScriptCommandAsyncResponse {
  final String id;
  final String status;

  ScriptCommandAsyncResponse({
    required this.id,
    required this.status,
  });

  factory ScriptCommandAsyncResponse.fromJson(Map<String, dynamic> json) {
    return ScriptCommandAsyncResponse(
      id: (json["id"] as String?) ?? "",
      status: (json["status"] as String?) ?? "",
    );
  }
}

class ScriptCommandJob {
  final String id;
  final String command;
  final String status;
  final String output;
  final String error;
  final String startedAt;
  final String? finishedAt;

  ScriptCommandJob({
    required this.id,
    required this.command,
    required this.status,
    required this.output,
    required this.error,
    required this.startedAt,
    this.finishedAt,
  });

  factory ScriptCommandJob.fromJson(Map<String, dynamic> json) {
    return ScriptCommandJob(
      id: (json["id"] as String?) ?? "",
      command: (json["command"] as String?) ?? "",
      status: (json["status"] as String?) ?? "",
      output: (json["output"] as String?) ?? "",
      error: (json["error"] as String?) ?? "",
      startedAt: (json["startedAt"] as String?) ?? "",
      finishedAt: json["finishedAt"] as String?,
    );
  }
}

class ScriptExecuteAsyncResponse {
  final String id;
  final String status;

  ScriptExecuteAsyncResponse({
    required this.id,
    required this.status,
  });

  factory ScriptExecuteAsyncResponse.fromJson(Map<String, dynamic> json) {
    return ScriptExecuteAsyncResponse(
      id: (json["id"] as String?) ?? "",
      status: (json["status"] as String?) ?? "",
    );
  }
}

class ScriptExecuteJob {
  final String id;
  final String scriptName;
  final String status;
  final String output;
  final String error;
  final String startedAt;
  final String? finishedAt;

  ScriptExecuteJob({
    required this.id,
    required this.scriptName,
    required this.status,
    required this.output,
    required this.error,
    required this.startedAt,
    this.finishedAt,
  });

  factory ScriptExecuteJob.fromJson(Map<String, dynamic> json) {
    return ScriptExecuteJob(
      id: (json["id"] as String?) ?? "",
      scriptName: (json["scriptName"] as String?) ??
          (json["script_name"] as String?) ??
          "",
      status: (json["status"] as String?) ?? "",
      output: (json["output"] as String?) ?? "",
      error: (json["error"] as String?) ?? "",
      startedAt: (json["startedAt"] as String?) ?? "",
      finishedAt: json["finishedAt"] as String?,
    );
  }
}

class ScriptWasmAsyncResponse {
  final String id;
  final String status;

  ScriptWasmAsyncResponse({
    required this.id,
    required this.status,
  });

  factory ScriptWasmAsyncResponse.fromJson(Map<String, dynamic> json) {
    return ScriptWasmAsyncResponse(
      id: (json["id"] as String?) ?? "",
      status: (json["status"] as String?) ?? "",
    );
  }
}

class ScriptWasmJob {
  final String id;
  final String wasmName;
  final String status;
  final String output;
  final String stdout;
  final String stderr;
  final String error;
  final String duration;
  final String startedAt;
  final String? finishedAt;

  ScriptWasmJob({
    required this.id,
    required this.wasmName,
    required this.status,
    required this.output,
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.duration,
    required this.startedAt,
    this.finishedAt,
  });

  factory ScriptWasmJob.fromJson(Map<String, dynamic> json) {
    return ScriptWasmJob(
      id: (json["id"] as String?) ?? "",
      wasmName: (json["wasmName"] as String?) ??
          (json["wasm_name"] as String?) ??
          "",
      status: (json["status"] as String?) ?? "",
      output: (json["output"] as String?) ?? "",
      stdout: (json["stdout"] as String?) ?? "",
      stderr: (json["stderr"] as String?) ?? "",
      error: (json["error"] as String?) ?? "",
      duration: (json["duration"] as String?) ?? "",
      startedAt: (json["startedAt"] as String?) ?? "",
      finishedAt: json["finishedAt"] as String?,
    );
  }
}

class ScriptUploadResult {
  final String output;
  final String? path;

  ScriptUploadResult({
    required this.output,
    this.path,
  });

  factory ScriptUploadResult.fromJson(Map<String, dynamic> json) {
    return ScriptUploadResult(
      output: (json["output"] as String?) ?? "",
      path: json["path"] as String?,
    );
  }
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
