// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vector_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VectorDocument _$VectorDocumentFromJson(Map<String, dynamic> json) =>
    VectorDocument(
      id: json['id'] as String?,
      vector: (json['vector'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$VectorDocumentToJson(VectorDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vector': instance.vector,
      'metadata': instance.metadata,
      'content': instance.content,
    };

VectorSearchResult _$VectorSearchResultFromJson(Map<String, dynamic> json) =>
    VectorSearchResult(
      document:
          VectorDocument.fromJson(json['document'] as Map<String, dynamic>),
      score: (json['score'] as num).toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$VectorSearchResultToJson(VectorSearchResult instance) =>
    <String, dynamic>{
      'document': instance.document,
      'score': instance.score,
      'distance': instance.distance,
    };

VectorSearchOptions _$VectorSearchOptionsFromJson(Map<String, dynamic> json) =>
    VectorSearchOptions(
      queryVector: (json['queryVector'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      limit: (json['limit'] as num?)?.toInt(),
      filter: json['filter'] as Map<String, dynamic>?,
      minScore: (json['minScore'] as num?)?.toDouble(),
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
      includeDistance: json['includeDistance'] as bool?,
      includeContent: json['includeContent'] as bool?,
    );

Map<String, dynamic> _$VectorSearchOptionsToJson(
        VectorSearchOptions instance) =>
    <String, dynamic>{
      'queryVector': instance.queryVector,
      'limit': instance.limit,
      'filter': instance.filter,
      'minScore': instance.minScore,
      'maxDistance': instance.maxDistance,
      'includeDistance': instance.includeDistance,
      'includeContent': instance.includeContent,
    };

VectorSearchResponse _$VectorSearchResponseFromJson(
        Map<String, dynamic> json) =>
    VectorSearchResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => VectorSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMatches: (json['totalMatches'] as num?)?.toInt(),
      queryTime: (json['queryTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VectorSearchResponseToJson(
        VectorSearchResponse instance) =>
    <String, dynamic>{
      'results': instance.results,
      'totalMatches': instance.totalMatches,
      'queryTime': instance.queryTime,
    };

VectorBatchInsertOptions _$VectorBatchInsertOptionsFromJson(
        Map<String, dynamic> json) =>
    VectorBatchInsertOptions(
      documents: (json['documents'] as List<dynamic>)
          .map((e) => VectorDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      skipDuplicates: json['skipDuplicates'] as bool?,
    );

Map<String, dynamic> _$VectorBatchInsertOptionsToJson(
        VectorBatchInsertOptions instance) =>
    <String, dynamic>{
      'documents': instance.documents,
      'skipDuplicates': instance.skipDuplicates,
    };

VectorInsertResponse _$VectorInsertResponseFromJson(
        Map<String, dynamic> json) =>
    VectorInsertResponse(
      id: json['id'] as String,
      success: json['success'] as bool,
    );

Map<String, dynamic> _$VectorInsertResponseToJson(
        VectorInsertResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'success': instance.success,
    };

VectorBatchInsertResponse _$VectorBatchInsertResponseFromJson(
        Map<String, dynamic> json) =>
    VectorBatchInsertResponse(
      insertedCount: (json['insertedCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num).toInt(),
      ids: (json['ids'] as List<dynamic>).map((e) => e as String).toList(),
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$VectorBatchInsertResponseToJson(
        VectorBatchInsertResponse instance) =>
    <String, dynamic>{
      'insertedCount': instance.insertedCount,
      'failedCount': instance.failedCount,
      'ids': instance.ids,
      'errors': instance.errors,
    };

VectorCollectionConfig _$VectorCollectionConfigFromJson(
        Map<String, dynamic> json) =>
    VectorCollectionConfig(
      dimension: (json['dimension'] as num?)?.toInt(),
      distance: json['distance'] as String?,
    );

Map<String, dynamic> _$VectorCollectionConfigToJson(
        VectorCollectionConfig instance) =>
    <String, dynamic>{
      'dimension': instance.dimension,
      'distance': instance.distance,
    };

VectorCollectionInfo _$VectorCollectionInfoFromJson(
        Map<String, dynamic> json) =>
    VectorCollectionInfo(
      name: json['name'] as String,
      count: (json['count'] as num?)?.toInt(),
      dimension: (json['dimension'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VectorCollectionInfoToJson(
        VectorCollectionInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
      'dimension': instance.dimension,
    };
