import "package:json_annotation/json_annotation.dart";

part "vector_document.g.dart";

/// Represents a vector embedding as a list of numbers.
typedef VectorEmbedding = List<double>;

/// Represents a vector document/record that can be stored and queried.
@JsonSerializable()
class VectorDocument {
  /// Unique identifier for the vector document.
  String? id;

  /// The vector embedding.
  @JsonKey(name: "vector")
  List<double> vector;

  /// Optional metadata to attach to the vector.
  @JsonKey(name: "metadata")
  Map<String, dynamic>? metadata;

  /// Optional content/text that this vector represents.
  @JsonKey(name: "content")
  String? content;

  VectorDocument({
    this.id,
    required this.vector,
    this.metadata,
    this.content,
  });

  factory VectorDocument.fromJson(Map<String, dynamic> json) =>
      _$VectorDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$VectorDocumentToJson(this);
}

/// A result from a vector similarity search.
@JsonSerializable()
class VectorSearchResult {
  /// The vector document that matched.
  @JsonKey(name: "document")
  VectorDocument document;

  /// The similarity score (higher is better, typically 0-1 range).
  @JsonKey(name: "score")
  double score;

  /// Optional distance metric value (lower is better).
  @JsonKey(name: "distance")
  double? distance;

  VectorSearchResult({
    required this.document,
    required this.score,
    this.distance,
  });

  factory VectorSearchResult.fromJson(Map<String, dynamic> json) =>
      _$VectorSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$VectorSearchResultToJson(this);
}

/// Options for vector search operations.
@JsonSerializable()
class VectorSearchOptions {
  /// The query vector to search for.
  @JsonKey(name: "queryVector")
  List<double> queryVector;

  /// Maximum number of results to return.
  @JsonKey(name: "limit")
  int? limit;

  /// Optional filter metadata criteria.
  @JsonKey(name: "filter")
  Map<String, dynamic>? filter;

  /// Minimum score threshold (results below this will be filtered out).
  @JsonKey(name: "minScore")
  double? minScore;

  /// Minimum distance threshold (results above this will be filtered out).
  @JsonKey(name: "maxDistance")
  double? maxDistance;

  /// Whether to return distances in addition to scores.
  @JsonKey(name: "includeDistance")
  bool? includeDistance;

  /// Whether to include the full document content.
  @JsonKey(name: "includeContent")
  bool? includeContent;

  VectorSearchOptions({
    required this.queryVector,
    this.limit,
    this.filter,
    this.minScore,
    this.maxDistance,
    this.includeDistance,
    this.includeContent,
  });

  factory VectorSearchOptions.fromJson(Map<String, dynamic> json) =>
      _$VectorSearchOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$VectorSearchOptionsToJson(this);
}

/// Response from a vector search operation.
@JsonSerializable()
class VectorSearchResponse {
  /// The search results.
  @JsonKey(name: "results")
  List<VectorSearchResult> results;

  /// Total number of vectors that matched before limit.
  @JsonKey(name: "totalMatches")
  int? totalMatches;

  /// Query execution time in milliseconds.
  @JsonKey(name: "queryTime")
  int? queryTime;

  VectorSearchResponse({
    required this.results,
    this.totalMatches,
    this.queryTime,
  });

  factory VectorSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$VectorSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VectorSearchResponseToJson(this);
}

/// Options for batch vector insert operations.
@JsonSerializable()
class VectorBatchInsertOptions {
  /// The vectors to insert.
  @JsonKey(name: "documents")
  List<VectorDocument> documents;

  /// Whether to skip duplicate IDs.
  @JsonKey(name: "skipDuplicates")
  bool? skipDuplicates;

  VectorBatchInsertOptions({
    required this.documents,
    this.skipDuplicates,
  });

  factory VectorBatchInsertOptions.fromJson(Map<String, dynamic> json) =>
      _$VectorBatchInsertOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$VectorBatchInsertOptionsToJson(this);
}

/// Response from a vector insert operation.
@JsonSerializable()
class VectorInsertResponse {
  /// The inserted document ID (if generated).
  @JsonKey(name: "id")
  String id;

  /// Whether the insert succeeded.
  @JsonKey(name: "success")
  bool success;

  VectorInsertResponse({
    required this.id,
    required this.success,
  });

  factory VectorInsertResponse.fromJson(Map<String, dynamic> json) =>
      _$VectorInsertResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VectorInsertResponseToJson(this);
}

/// Response from a batch vector insert operation.
@JsonSerializable()
class VectorBatchInsertResponse {
  /// Number of successfully inserted vectors.
  @JsonKey(name: "insertedCount")
  int insertedCount;

  /// Number of failed insertions.
  @JsonKey(name: "failedCount")
  int failedCount;

  /// List of inserted document IDs.
  @JsonKey(name: "ids")
  List<String> ids;

  /// List of errors (if any).
  @JsonKey(name: "errors")
  List<String>? errors;

  VectorBatchInsertResponse({
    required this.insertedCount,
    required this.failedCount,
    required this.ids,
    this.errors,
  });

  factory VectorBatchInsertResponse.fromJson(Map<String, dynamic> json) =>
      _$VectorBatchInsertResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VectorBatchInsertResponseToJson(this);
}

/// Configuration for creating a vector collection.
@JsonSerializable()
class VectorCollectionConfig {
  /// Vector dimension
  @JsonKey(name: "dimension")
  int? dimension;

  /// Distance metric
  @JsonKey(name: "distance")
  String? distance;

  VectorCollectionConfig({
    this.dimension,
    this.distance,
  });

  factory VectorCollectionConfig.fromJson(Map<String, dynamic> json) =>
      _$VectorCollectionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VectorCollectionConfigToJson(this);
}

/// Response from listing vector collections.
@JsonSerializable()
class VectorCollectionInfo {
  /// Collection name
  @JsonKey(name: "name")
  String name;

  /// Vector count
  @JsonKey(name: "count")
  int? count;

  /// Vector dimension
  @JsonKey(name: "dimension")
  int? dimension;

  VectorCollectionInfo({
    required this.name,
    this.count,
    this.dimension,
  });

  factory VectorCollectionInfo.fromJson(Map<String, dynamic> json) =>
      _$VectorCollectionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VectorCollectionInfoToJson(this);
}

