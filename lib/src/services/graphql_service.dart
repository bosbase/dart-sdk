import "../dtos/graphql_response.dart";
import "base_service.dart";

/// Service for executing GraphQL queries and mutations against `/api/graphql`.
class GraphQLService extends BaseService {
  GraphQLService(super.client);

  /// Executes a GraphQL document with optional variables and operation name.
  ///
  /// Authentication is required and the endpoint is **superuser-only**.
  Future<GraphQLResponse> query(
    String document, {
    Map<String, dynamic> variables = const {},
    String? operationName,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final payload = <String, dynamic>{
      "query": document,
      "variables": variables,
      if (operationName != null) "operationName": operationName,
    };

    final response = await client.send<Map<String, dynamic>>(
      "/api/graphql",
      method: "POST",
      headers: headers,
      query: query,
      body: payload,
    );

    return GraphQLResponse.fromJson(response);
  }
}
