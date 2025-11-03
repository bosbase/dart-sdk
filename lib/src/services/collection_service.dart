import "../client.dart";
import "../dtos/collection_field.dart";
import "../dtos/collection_model.dart";
import "base_crud_service.dart";

/// The service that handles the **Collection APIs**.
///
/// Usually shouldn't be initialized manually and instead
/// [Bosbase.collections] should be used.
class CollectionService extends BaseCrudService<CollectionModel> {
  CollectionService(super.client);

  @override
  String get baseCrudPath => "/api/collections";

  @override
  CollectionModel itemFactoryFunc(Map<String, dynamic> json) =>
      CollectionModel.fromJson(json);

  /// Deletes a collection (table) by its id or name.
  ///
  /// This is a convenience method that wraps the inherited [delete] method
  /// to make collection deletion explicit.
  ///
  /// **Warning**: This operation is destructive and will delete the collection
  /// along with all its records and associated data.
  ///
  /// [collectionIdOrName] - Collection id or name to delete
  /// Returns true if deletion succeeds
  Future<void> deleteCollection(
    String collectionIdOrName, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return delete(
      collectionIdOrName,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Imports the provided collections.
  ///
  /// If [deleteMissing] is `true`, all local collections and schema fields,
  /// that are not present in the imported configuration, WILL BE DELETED
  /// (including their related records data)!
  Future<void> import(
    List<CollectionModel> collections, {
    bool deleteMissing = false,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["collections"] = collections;
    enrichedBody["deleteMissing"] = deleteMissing;

    return client.send(
      "$baseCrudPath/import",
      method: "PUT",
      body: enrichedBody,
      query: query,
      headers: headers,
    );
  }

  /// Returns type indexed map with scaffolded collection models
  /// populated with their default field values.
  Future<Map<String, CollectionModel>> getScaffolds({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
      "$baseCrudPath/meta/scaffolds",
      body: body,
      query: query,
      headers: headers,
    )
        .then((data) {
      final result = <String, CollectionModel>{};

      data.forEach((key, value) {
        result[key] =
            CollectionModel.fromJson(value as Map<String, dynamic>? ?? {});
      });

      return result;
    });
  }

  /// Creates a new collection from a scaffold template.
  ///
  /// This is a convenience method that fetches the scaffold for the specified type
  /// and creates a new collection with the given name, using the scaffold as a base.
  ///
  /// [type] - Collection type: "base", "auth", or "view"
  /// [name] - Collection name
  /// [overrides] - Optional properties to override in the scaffold
  /// Returns created collection model
  Future<CollectionModel> createFromScaffold(
    String type,
    String name, {
    Map<String, dynamic>? overrides,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final scaffolds = await getScaffolds(query: query, headers: headers);
    final scaffold = scaffolds[type];

    if (scaffold == null) {
      throw ArgumentError('Scaffold for type "$type" not found');
    }

    // Create collection based on scaffold with overrides
    final scaffoldJson = scaffold.toJson();
    final collectionData = Map<String, dynamic>.from(scaffoldJson);
    collectionData["name"] = name;
    if (overrides != null) {
      collectionData.addAll(overrides);
    }

    final collection = CollectionModel.fromJson(collectionData);

    return create(
      collection,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Creates a new base collection.
  ///
  /// Convenience method for creating a base collection type.
  ///
  /// [name] - Collection name
  /// [overrides] - Optional properties to override
  /// Returns created collection model
  Future<CollectionModel> createBase(
    String name, {
    Map<String, dynamic>? overrides,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return createFromScaffold(
      "base",
      name,
      overrides: overrides,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Creates a new auth collection.
  ///
  /// Convenience method for creating an auth collection type.
  ///
  /// [name] - Collection name
  /// [overrides] - Optional properties to override
  /// Returns created collection model
  Future<CollectionModel> createAuth(
    String name, {
    Map<String, dynamic>? overrides,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return createFromScaffold(
      "auth",
      name,
      overrides: overrides,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Creates a new view collection.
  ///
  /// Convenience method for creating a view collection type.
  ///
  /// [name] - Collection name
  /// [viewQuery] - SQL query for the view (required for view collections)
  /// [overrides] - Optional properties to override
  /// Returns created collection model
  Future<CollectionModel> createView(
    String name, {
    String? viewQuery,
    Map<String, dynamic>? overrides,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final scaffoldOverrides = Map<String, dynamic>.from(overrides ?? {});
    if (viewQuery != null) {
      scaffoldOverrides["viewQuery"] = viewQuery;
    }

    return createFromScaffold(
      "view",
      name,
      overrides: scaffoldOverrides.isEmpty ? null : scaffoldOverrides,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Deletes all records associated with the specified collection.
  Future<void> truncate(
    String collectionIdOrName, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send(
      "$baseCrudPath/${Uri.encodeComponent(collectionIdOrName)}/truncate",
      method: "DELETE",
      body: body,
      query: query,
      headers: headers,
    );
  }

  // -------------------------------------------------------------------
  // Export/Import Helpers
  // -------------------------------------------------------------------

  /// Exports collections in a format suitable for import.
  ///
  /// This method fetches all collections and prepares them for export by:
  /// - Removing timestamps (created, updated)
  /// - Removing OAuth2 providers (for cleaner export)
  ///
  /// The returned collections can be saved as JSON and later imported.
  ///
  /// [filterCollections] - Optional function to filter which collections to export (by default exports all)
  /// Returns array of collection models ready for export
  Future<List<CollectionModel>> exportCollections({
    bool Function(CollectionModel)? filterCollections,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collections = await getFullList(
      query: query,
      headers: headers,
    );

    // Filter if a filter function is provided
    var filtered = filterCollections != null
        ? collections.where(filterCollections).toList()
        : collections;

    // Clean collections for export (matching UI behavior)
    return filtered.map((collection) {
      final json = collection.toJson();
      
      // Remove timestamps
      json.remove("created");
      json.remove("updated");
      
      // Remove OAuth2 providers
      if (json.containsKey("oauth2") && json["oauth2"] is Map) {
        final oauth2Data = json["oauth2"] as Map<String, dynamic>;
        if (oauth2Data.containsKey("providers")) {
          oauth2Data.remove("providers");
        }
      }
      
      return CollectionModel.fromJson(json);
    }).toList();
  }

  /// Normalizes collections data for import.
  ///
  /// This helper method prepares collections data by:
  /// - Removing timestamps (created, updated)
  /// - Removing duplicate collections by id
  /// - Removing duplicate fields within each collection
  ///
  /// Use this before calling import() to ensure clean data.
  ///
  /// [collections] - List of collection models to normalize
  /// Returns normalized list of collections ready for import
  List<CollectionModel> normalizeForImport(List<CollectionModel> collections) {
    // Remove duplicates by id
    final seenIds = <String>{};
    final uniqueCollections = collections.where((collection) {
      if (collection.id.isNotEmpty && seenIds.contains(collection.id)) {
        return false;
      }
      if (collection.id.isNotEmpty) {
        seenIds.add(collection.id);
      }
      return true;
    }).toList();

    // Normalize each collection
    return uniqueCollections.map((collection) {
      final normalized = CollectionModel.fromJson(collection.toJson());
      
      // Remove timestamps
      normalized.created = "";
      normalized.updated = "";
      
      // Remove duplicate fields by id
      if (normalized.fields.isNotEmpty) {
        final seenFieldIds = <String>{};
        normalized.fields = normalized.fields.where((field) {
          if (field.id.isNotEmpty && seenFieldIds.contains(field.id)) {
            return false;
          }
          if (field.id.isNotEmpty) {
            seenFieldIds.add(field.id);
          }
          return true;
        }).toList();
      }
      
      return normalized;
    }).toList();
  }

  /// Imports the provided collections.
  ///
  /// If [deleteMissing] is `true`, all local collections and schema fields,
  /// that are not present in the imported configuration, WILL BE DELETED
  /// (including their related records data)!
  ///
  /// **Warning**: This operation is destructive when [deleteMissing] is true.
  /// It's recommended to call [normalizeForImport] on the collections
  /// before importing to ensure clean data.
  Future<void> import(
    List<CollectionModel> collections, {
    bool deleteMissing = false,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["collections"] = collections;
    enrichedBody["deleteMissing"] = deleteMissing;

    return client.send(
      "$baseCrudPath/import",
      method: "PUT",
      body: enrichedBody,
      query: query,
      headers: headers,
    );
  }

  // -------------------------------------------------------------------
  // Field Management Helpers
  // -------------------------------------------------------------------

  /// Adds a new field to the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [field] - Field definition (at minimum: name and type)
  /// Returns the updated collection model
  Future<CollectionModel> addField(
    String collectionIdOrName,
    Map<String, dynamic> field, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (field["name"] == null || field["type"] == null) {
      throw ArgumentError("Field name and type are required");
    }

    final fieldName = field["name"] as String;

    // Check if field with this name already exists
    if (collection.fields.any((f) => f.name == fieldName)) {
      throw ArgumentError('Field with name "$fieldName" already exists');
    }

    // Initialize field with defaults
    final newFieldData = <String, dynamic>{
      "id": "",
      "name": fieldName,
      "type": field["type"],
      "system": false,
      "hidden": false,
      "presentable": false,
      "required": false,
      ...field,
    };

    final newField = CollectionField(newFieldData);
    collection.fields.add(newField);

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Updates an existing field in the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [fieldName] - Name of the field to update
  /// [updates] - Field updates to apply
  /// Returns the updated collection model
  Future<CollectionModel> updateField(
    String collectionIdOrName,
    String fieldName,
    Map<String, dynamic> updates, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    final fieldIndex = collection.fields.indexWhere((f) => f.name == fieldName);
    if (fieldIndex == -1) {
      throw ArgumentError('Field with name "$fieldName" not found');
    }

    final field = collection.fields[fieldIndex];

    // Don't allow changing system fields
    if (field.system && (updates.containsKey("type") || updates.containsKey("name"))) {
      throw ArgumentError("Cannot modify system fields");
    }

    // If renaming, check for name conflicts
    if (updates.containsKey("name") && updates["name"] != fieldName) {
      final newName = updates["name"] as String;
      if (collection.fields.any((f) => f.name == newName && f.name != fieldName)) {
        throw ArgumentError('Field with name "$newName" already exists');
      }
    }

    // Apply updates
    final updatedFieldData = Map<String, dynamic>.from(field.data);
    updatedFieldData.addAll(updates);
    collection.fields[fieldIndex] = CollectionField(updatedFieldData);

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Removes a field from the collection (deletes a table field).
  ///
  /// This method removes a field from the collection schema and automatically
  /// removes any indexes that reference the deleted field.
  ///
  /// **Note**: System fields cannot be removed.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [fieldName] - Name of the field to remove
  /// Returns the updated collection model
  /// Throws [ArgumentError] if field not found or if attempting to remove a system field
  Future<CollectionModel> removeField(
    String collectionIdOrName,
    String fieldName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    final fieldIndex = collection.fields.indexWhere((f) => f.name == fieldName);
    if (fieldIndex == -1) {
      throw ArgumentError('Field with name "$fieldName" not found');
    }

    final field = collection.fields[fieldIndex];

    // Don't allow removing system fields
    if (field.system) {
      throw ArgumentError("Cannot remove system fields");
    }

    // Remove the field
    collection.fields.removeAt(fieldIndex);

    // Remove indexes that reference this field
    collection.indexes = collection.indexes.where((idx) {
      // Parse index string to check if it contains this field
      // Index format is typically like: "CREATE INDEX idx_name ON table_name (column1, column2)"
      return !idx.contains("($fieldName)") &&
          !idx.contains("($fieldName,") &&
          !idx.contains(", $fieldName)") &&
          !idx.contains("\`$fieldName\`");
    }).toList();

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Gets a field by name from the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [fieldName] - Name of the field to retrieve
  /// Returns the field object or null if not found
  Future<CollectionField?> getField(
    String collectionIdOrName,
    String fieldName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    try {
      return collection.fields.firstWhere((f) => f.name == fieldName);
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------------
  // Index Management Helpers
  // -------------------------------------------------------------------

  /// Adds an index to the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [columns] - List of column names to index
  /// [unique] - Whether the index should be unique (default: false)
  /// [indexName] - Optional custom index name
  /// Returns the updated collection model
  Future<CollectionModel> addIndex(
    String collectionIdOrName,
    List<String> columns, {
    bool unique = false,
    String? indexName,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (columns.isEmpty) {
      throw ArgumentError("At least one column must be specified");
    }

    // Validate that all columns exist
    final fieldNames = collection.fields.map((f) => f.name).toList();
    for (final column in columns) {
      if (column != "id" && !fieldNames.contains(column)) {
        throw ArgumentError('Field "$column" does not exist in the collection');
      }
    }

    // Generate index name if not provided
    final idxName = indexName ?? "idx_${collection.name}_${columns.join("_")}";
    final columnsStr = columns.map((col) => "`$col`").join(", ");
    final index = unique
        ? "CREATE UNIQUE INDEX `$idxName` ON `${collection.name}` ($columnsStr)"
        : "CREATE INDEX `$idxName` ON `${collection.name}` ($columnsStr)";

    // Check if index already exists
    if (collection.indexes.contains(index)) {
      throw ArgumentError("Index already exists");
    }

    collection.indexes.add(index);

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Removes an index from the collection (deletes a table index).
  ///
  /// This method removes an index that contains all the specified columns.
  /// The index is identified by matching all provided column names.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [columns] - List of column names that identify the index to remove
  /// Returns the updated collection model
  /// Throws [ArgumentError] if index not found
  Future<CollectionModel> removeIndex(
    String collectionIdOrName,
    List<String> columns, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (columns.isEmpty) {
      throw ArgumentError("At least one column must be specified");
    }

    // Find and remove indexes that match the columns
    final initialLength = collection.indexes.length;
    collection.indexes = collection.indexes.where((idx) {
      // Check if index contains all the specified columns
      // Handle both backticked and non-backticked formats
      final hasAllColumns = columns.every((col) {
        return idx.contains("`$col`") ||
            idx.contains("($col)") ||
            idx.contains("($col,") ||
            idx.contains(", $col)");
      });
      return !hasAllColumns;
    }).toList();

    if (collection.indexes.length == initialLength) {
      throw ArgumentError("Index not found");
    }

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Gets all indexes for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// Returns a list of index strings
  Future<List<String>> getIndexes(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    return collection.indexes;
  }

  // -------------------------------------------------------------------
  // Access Rights Management Helpers
  // -------------------------------------------------------------------

  /// Sets the list rule (read/list access rule) for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null or empty string to remove)
  /// Returns the updated collection model
  Future<CollectionModel> setListRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    collection.listRule = rule?.isEmpty ?? true ? null : rule;
    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Sets the view rule (read/view access rule) for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null or empty string to remove)
  /// Returns the updated collection model
  Future<CollectionModel> setViewRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    collection.viewRule = rule?.isEmpty ?? true ? null : rule;
    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Sets the create rule for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null or empty string to remove)
  /// Returns the updated collection model
  Future<CollectionModel> setCreateRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    collection.createRule = rule?.isEmpty ?? true ? null : rule;
    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Sets the update rule for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null or empty string to remove)
  /// Returns the updated collection model
  Future<CollectionModel> setUpdateRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    collection.updateRule = rule?.isEmpty ?? true ? null : rule;
    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Sets the delete rule for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null or empty string to remove)
  /// Returns the updated collection model
  Future<CollectionModel> setDeleteRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    collection.deleteRule = rule?.isEmpty ?? true ? null : rule;
    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }
}
