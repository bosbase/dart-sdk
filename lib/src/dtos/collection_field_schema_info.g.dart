// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_field_schema_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionFieldSchemaInfo _$CollectionFieldSchemaInfoFromJson(
        Map<String, dynamic> json) =>
    CollectionFieldSchemaInfo(
      name: json['name'] as String? ?? "",
      type: json['type'] as String? ?? "",
      required: json['required'] as bool?,
      system: json['system'] as bool?,
      hidden: json['hidden'] as bool?,
    );

Map<String, dynamic> _$CollectionFieldSchemaInfoToJson(
        CollectionFieldSchemaInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'required': instance.required,
      'system': instance.system,
      'hidden': instance.hidden,
    };
