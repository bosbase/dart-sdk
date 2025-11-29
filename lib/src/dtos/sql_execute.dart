class SQLExecuteResponse {
  final List<String> columns;
  final List<List<String>> rows;
  final int? rowsAffected;

  SQLExecuteResponse({
    this.columns = const [],
    this.rows = const [],
    this.rowsAffected,
  });

  factory SQLExecuteResponse.fromJson(Map<String, dynamic> json) {
    final parsedColumns = <String>[];
    if (json["columns"] is List) {
      for (final dynamic column in json["columns"] as List) {
        parsedColumns.add(column?.toString() ?? "");
      }
    }

    final parsedRows = <List<String>>[];
    if (json["rows"] is List) {
      for (final dynamic row in json["rows"] as List) {
        if (row is! List) {
          continue;
        }

        final rowValues = <String>[];
        for (final dynamic value in row) {
          rowValues.add(value?.toString() ?? "");
        }
        parsedRows.add(List<String>.unmodifiable(rowValues));
      }
    }

    final dynamic rowsAffectedValue = json["rowsAffected"];
    final rowsAffected = rowsAffectedValue is int
        ? rowsAffectedValue
        : (rowsAffectedValue != null
            ? int.tryParse("$rowsAffectedValue")
            : null);

    return SQLExecuteResponse(
      columns: List<String>.unmodifiable(parsedColumns),
      rows: List<List<String>>.unmodifiable(parsedRows),
      rowsAffected: rowsAffected,
    );
  }
}
