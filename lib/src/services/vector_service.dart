import "../client.dart";
import "../dtos/vector_document.dart";
import "base_service.dart";

/// The service that handles the **Vector APIs**.
///
/// Usually shouldn't be initialized manually and instead
/// [Bosbase.vectors] should be used.
class VectorService extends BaseService {
  VectorService(super.client);

  /// Base path for vector operations.
  String get baseVectorPath => "/api/vectors";

  /// Collection-specific path.
  String _getPath(String? collection) {
    if (collection != null) {
      return "$baseVectorPath/${Uri.encodeComponent(collection)}";
    }
    return baseVectorPath;
  }

  /// Insert a single vector document.
  ///
  /// Example:
  /// ```dart
  /// final result = await pb.vectors.insert(
  ///   VectorDocument(
  ///     vector: [0.1, 0.2, 0.3],
  ///     metadata: {'category': 'example'},
  ///     content: 'Example text'
  ///   ),
  ///   collection: 'documents',
  /// );
  /// ```
  Future<VectorInsertResponse> insert(
    VectorDocument document, {
    String? collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = _getPath(collection);
    return client.send<Map<String, dynamic>>(
      path,
      method: "POST",
      body: document.toJson(),
      query: query,
      headers: headers,
    ).then((data) => VectorInsertResponse.fromJson(data));
  }

  /// Insert multiple vector documents in a batch.
  ///
  /// Example:
  /// ```dart
  /// final result = await pb.vectors.batchInsert(
  ///   VectorBatchInsertOptions(
  ///     documents: [
  ///       VectorDocument(vector: [0.1, 0.2, 0.3], content: 'Example 1'),
  ///       VectorDocument(vector: [0.4, 0.5, 0.6], content: 'Example 2'),
  ///     ],
  ///     skipDuplicates: true,
  ///   ),
  ///   collection: 'documents',
  /// );
  /// ```
  Future<VectorBatchInsertResponse> batchInsert(
    VectorBatchInsertOptions options, {
    String? collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = "${_getPath(collection)}/documents/batch";
    return client.send<Map<String, dynamic>>(
      path,
      method: "POST",
      body: options.toJson(),
      query: query,
      headers: headers,
    ).then((data) => VectorBatchInsertResponse.fromJson(data));
  }

  /// Update an existing vector document.
  ///
  /// Example:
  /// ```dart
  /// final result = await pb.vectors.update(
  ///   'doc_id',
  ///   VectorDocument(
  ///     vector: [0.1, 0.2, 0.3],
  ///     metadata: {'updated': true},
  ///   ),
  ///   collection: 'documents',
  /// );
  /// ```
  Future<VectorInsertResponse> update(
    String id,
    VectorDocument document, {
    String? collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = "${_getPath(collection)}/${Uri.encodeComponent(id)}";
    return client.send<Map<String, dynamic>>(
      path,
      method: "PATCH",
      body: document.toJson(),
      query: query,
      headers: headers,
    ).then((data) => VectorInsertResponse.fromJson(data));
  }

  /// Delete a vector document by ID.
  ///
  /// Example:
  /// ```dart
  /// await pb.vectors.delete('doc_id', collection: 'documents');
  /// ```
  Future<void> delete(
    String id, {
    String? collection,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final path = "${_getPath(collection)}/${Uri.encodeComponent(id)}";
    return client.send(
      path,
      method: "DELETE",
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Search for similar vectors.
  ///
  /// Example:
  /// ```dart
  /// final results = await pb.vectors.search(
  ///   VectorSearchOptions(
  ///     queryVector: [0.1, 0.2, 0.3],
  ///     limit: 10,
  ///     minScore: 0.7,
  ///   ),
  ///   collection: 'documents',
  /// );
  /// ```
  Future<VectorSearchResponse> search(
    VectorSearchOptions options, {
    String? collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = "${_getPath(collection)}/documents/search";
    return client.send<Map<String, dynamic>>(
      path,
      method: "POST",
      body: options.toJson(),
      query: query,
      headers: headers,
    ).then((data) => VectorSearchResponse.fromJson(data));
  }

  /// Get a vector document by ID.
  ///
  /// Example:
  /// ```dart
  /// final doc = await pb.vectors.get('doc_id', collection: 'documents');
  /// ```
  Future<VectorDocument> get(
    String id, {
    String? collection,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = "${_getPath(collection)}/${Uri.encodeComponent(id)}";
    return client.send<Map<String, dynamic>>(
      path,
      query: query,
      headers: headers,
    ).then((data) => VectorDocument.fromJson(data));
  }

  /// List all vector documents in a collection (with optional pagination).
  ///
  /// Example:
  /// ```dart
  /// final result = await pb.vectors.list(
  ///   page: 1,
  ///   perPage: 100,
  ///   collection: 'documents',
  /// );
  /// ```
  Future<Map<String, dynamic>> list({
    String? collection,
    int? page,
    int? perPage,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final enrichedQuery = Map<String, dynamic>.of(query);
    if (page != null) enrichedQuery["page"] = page;
    if (perPage != null) enrichedQuery["perPage"] = perPage;

    final path = _getPath(collection);
    return client.send<Map<String, dynamic>>(
      path,
      query: enrichedQuery,
      headers: headers,
    );
  }

  /// Create or ensure a vector collection/table exists.
  ///
  /// Example:
  /// ```dart
  /// await pb.vectors.createCollection(
  ///   'documents',
  ///   VectorCollectionConfig(dimension: 384, distance: 'cosine'),
  /// );
  /// ```
  Future<void> createCollection(
    String name,
    VectorCollectionConfig config, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final path = "$baseVectorPath/collections/${Uri.encodeComponent(name)}";
    return client.send(
      path,
      method: "POST",
      body: config.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Update a vector collection configuration (distance metric and options).
  /// Note: Collection name and dimension cannot be changed after creation.
  ///
  /// Example:
  /// ```dart
  /// await pb.vectors.updateCollection(
  ///   'documents',
  ///   VectorCollectionConfig(distance: 'l2'),  // Change from cosine to L2
  /// );
  /// ```
  Future<void> updateCollection(
    String name,
    VectorCollectionConfig config, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final path = "$baseVectorPath/collections/${Uri.encodeComponent(name)}";
    return client.send(
      path,
      method: "PATCH",
      body: config.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Delete a vector collection/table.
  ///
  /// Example:
  /// ```dart
  /// await pb.vectors.deleteCollection('documents');
  /// ```
  Future<void> deleteCollection(
    String name, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final path = "$baseVectorPath/collections/${Uri.encodeComponent(name)}";
    return client.send(
      path,
      method: "DELETE",
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// List all available vector collections.
  ///
  /// Example:
  /// ```dart
  /// final collections = await pb.vectors.listCollections();
  /// ```
  Future<List<VectorCollectionInfo>> listCollections({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final path = "$baseVectorPath/collections";
    return client.send<List<dynamic>>(
      path,
      query: query,
      headers: headers,
    ).then((data) => data
        .map((json) => VectorCollectionInfo.fromJson(
            json as Map<String, dynamic>))
        .toList());
  }
}

