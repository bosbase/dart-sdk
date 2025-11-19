import "../dtos/langchaingo.dart";
import "base_service.dart";

class LangChaingoService extends BaseService {
  LangChaingoService(super.client);

  String get basePath => "/api/langchaingo";

  Future<LangChaingoCompletionResponse> completions(
    LangChaingoCompletionRequest payload, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "$basePath/completions",
          method: "POST",
          body: payload.toJson(),
          query: query,
          headers: headers,
        )
        .then(LangChaingoCompletionResponse.fromJson);
  }

  Future<LangChaingoRAGResponse> rag(
    LangChaingoRAGRequest payload, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "$basePath/rag",
          method: "POST",
          body: payload.toJson(),
          query: query,
          headers: headers,
        )
        .then(LangChaingoRAGResponse.fromJson);
  }

  Future<LangChaingoDocumentQueryResponse> queryDocuments(
    LangChaingoDocumentQueryRequest payload, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "$basePath/documents/query",
          method: "POST",
          body: payload.toJson(),
          query: query,
          headers: headers,
        )
        .then(LangChaingoDocumentQueryResponse.fromJson);
  }

  Future<LangChaingoSQLResponse> sql(
    LangChaingoSQLRequest payload, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
          "$basePath/sql",
          method: "POST",
          body: payload.toJson(),
          query: query,
          headers: headers,
        )
        .then(LangChaingoSQLResponse.fromJson);
  }
}
