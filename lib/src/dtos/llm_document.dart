class LLMDocument {
  String? id;
  String content;
  Map<String, String>? metadata;
  List<double>? embedding;

  LLMDocument({
    this.id,
    required this.content,
    this.metadata,
    this.embedding,
  });

  factory LLMDocument.fromJson(Map<String, dynamic> json) {
    return LLMDocument(
      id: json["id"] as String?,
      content: json["content"] as String? ?? "",
      metadata: (json["metadata"] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value.toString())),
      embedding: (json["embedding"] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "content": content,
        "metadata": metadata,
        "embedding": embedding,
      };
}

class LLMDocumentUpdate {
  String? content;
  Map<String, String>? metadata;
  List<double>? embedding;

  LLMDocumentUpdate({this.content, this.metadata, this.embedding});

  Map<String, dynamic> toJson() => {
        if (content != null) "content": content,
        if (metadata != null) "metadata": metadata,
        if (embedding != null) "embedding": embedding,
      };
}

class LLMQueryOptions {
  String? queryText;
  List<double>? queryEmbedding;
  int? limit;
  Map<String, String>? where;
  Map<String, dynamic>? negative;

  LLMQueryOptions({
    this.queryText,
    this.queryEmbedding,
    this.limit,
    this.where,
    this.negative,
  });

  Map<String, dynamic> toJson() => {
        if (queryText != null) "queryText": queryText,
        if (queryEmbedding != null) "queryEmbedding": queryEmbedding,
        if (limit != null) "limit": limit,
        if (where != null) "where": where,
        if (negative != null) "negative": negative,
      };
}

class LLMQueryResult {
  String id;
  String content;
  Map<String, String> metadata;
  double similarity;

  LLMQueryResult({
    required this.id,
    required this.content,
    required this.metadata,
    required this.similarity,
  });

  factory LLMQueryResult.fromJson(Map<String, dynamic> json) {
    return LLMQueryResult(
      id: json["id"] as String,
      content: json["content"] as String? ?? "",
      metadata: (json["metadata"] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value.toString())),
      similarity: (json["similarity"] as num).toDouble(),
    );
  }
}
