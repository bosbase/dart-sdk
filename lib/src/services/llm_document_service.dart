import "../dtos/llm_document.dart";
import "base_service.dart";

class LLMDocumentService extends BaseService {
  LLMDocumentService(super.client);

  String get basePath => "/api/llm-documents";

  String _collectionsPath() => "$basePath/collections";

  String _collectionPath(String collection) =>
      "$basePath/${Uri.encodeComponent(collection)}";

  Future<List<Map<String, dynamic>>> listCollections({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<List<dynamic>>(
      _collectionsPath(),
      query: query,
      headers: headers,
    ).then((items) => items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList());
  }

  Future<void> createCollection(
    String name, {
    Map<String, String>? metadata,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "${_collectionsPath()}/${Uri.encodeComponent(name)}",
      method: "POST",
      body: {"metadata": metadata},
      query: query,
      headers: headers,
    );
  }

  Future<void> deleteCollection(
    String name, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "${_collectionsPath()}/${Uri.encodeComponent(name)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> insert(
    LLMDocument document, {
    required String collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      _collectionPath(collection),
      method: "POST",
      body: document.toJson(),
      query: query,
      headers: headers,
    );
  }

  Future<LLMDocument> get(
    String id, {
    required String collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      "${_collectionPath(collection)}/${Uri.encodeComponent(id)}",
      query: query,
      headers: headers,
    ).then((json) => LLMDocument.fromJson(json));
  }

  Future<Map<String, dynamic>> update(
    String id,
    LLMDocumentUpdate document, {
    required String collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      "${_collectionPath(collection)}/${Uri.encodeComponent(id)}",
      method: "PATCH",
      body: document.toJson(),
      query: query,
      headers: headers,
    );
  }

  Future<void> delete(
    String id, {
    required String collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "${_collectionPath(collection)}/${Uri.encodeComponent(id)}",
      method: "DELETE",
      query: query,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> list({
    required String collection,
    int? page,
    int? perPage,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final merged = Map<String, dynamic>.from(query);
    if (page != null) merged["page"] = page;
    if (perPage != null) merged["perPage"] = perPage;

    return client.send<Map<String, dynamic>>(
      _collectionPath(collection),
      query: merged,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> query(
    LLMQueryOptions options, {
    required String collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      "${_collectionPath(collection)}/documents/query",
      method: "POST",
      body: options.toJson(),
      query: query,
      headers: headers,
    );
  }
}
