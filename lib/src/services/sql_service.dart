import "../dtos/sql_execute.dart";
import "base_service.dart";

/// Service for executing raw SQL statements via `/api/sql/execute`.
///
/// Only superusers can call these endpoints.
class SQLService extends BaseService {
  SQLService(super.client);

  Future<SQLExecuteResponse> execute(
    String statement, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final trimmed = statement.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError("query is required");
    }

    return client
        .send<Map<String, dynamic>>(
          "/api/sql/execute",
          method: "POST",
          body: {"query": trimmed},
          query: query,
          headers: headers,
        )
        .then(SQLExecuteResponse.fromJson);
  }
}
