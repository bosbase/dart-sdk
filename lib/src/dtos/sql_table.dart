import "collection_model.dart";

class SqlTableDefinition {
  final String name;
  final String? sql;

  const SqlTableDefinition({
    required this.name,
    this.sql,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{"name": name};
    if (sql != null) {
      data["sql"] = sql;
    }
    return data;
  }
}

class SqlTableImportResult {
  final List<CollectionModel> created;
  final List<String> skipped;

  SqlTableImportResult({
    required this.created,
    required this.skipped,
  });

  factory SqlTableImportResult.fromJson(Map<String, dynamic> json) {
    final createdRaw = json["created"] as List<dynamic>? ?? const [];
    final skippedRaw = json["skipped"] as List<dynamic>? ?? const [];

    final created = createdRaw
        .map((item) => CollectionModel.fromJson(
            item as Map<String, dynamic>? ?? const {}))
        .toList(growable: false);
    final skipped = skippedRaw
        .map((item) => item?.toString() ?? "")
        .toList(growable: false);

    return SqlTableImportResult(created: created, skipped: skipped);
  }
}
