import "../client.dart";
import "../dtos/collection_field.dart";
import "../dtos/collection_model.dart";
import "../dtos/collection_schema_info.dart";
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
      body: collection.toJson()..addAll(body),
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
  /// API Rules are collection access controls and data filters. Each rule can be:
  /// - `null` (locked) - Only superusers can perform the action (default)
  /// - `""` (empty string) - Anyone can perform the action
  /// - Non-empty string - Only users satisfying the filter expression can perform the action
  ///
  /// Rules support filter syntax with operators (=, !=, >, <, ~, etc.), macros (@now, @request.auth.id, etc.),
  /// and modifiers (:isset, :length, :each, :lower).
  ///
  /// Examples:
  /// - Allow only registered users: `"@request.auth.id != \"\""`
  /// - Filter by status: `"status = \"active\""`
  /// - Combine conditions: `"@request.auth.id != \"\" && (status = \"active\" || status = \"pending\")"`
  /// - Filter by relation: `"@request.auth.id != \"\" && author.id ?= @request.auth.id"`
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null, empty string, or "" to allow anyone; use non-empty string for filter)
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
  /// See [setListRule] for details on rule syntax and examples.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null, empty string, or "" to allow anyone; use non-empty string for filter)
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
  /// See [setListRule] for details on rule syntax and examples.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null, empty string, or "" to allow anyone; use non-empty string for filter)
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
  /// See [setListRule] for details on rule syntax and examples.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null, empty string, or "" to allow anyone; use non-empty string for filter)
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
  /// See [setListRule] for details on rule syntax and examples.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rule] - Rule expression (use null, empty string, or "" to allow anyone; use non-empty string for filter)
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

  /// Sets all API rules at once for the collection.
  ///
  /// This is a convenience method to update multiple rules in a single operation.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// [rules] - Map containing rule expressions (listRule, viewRule, createRule, updateRule, deleteRule)
  /// Returns the updated collection model
  Future<CollectionModel> setRules(
    String collectionIdOrName, {
    String? listRule,
    String? viewRule,
    String? createRule,
    String? updateRule,
    String? deleteRule,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (listRule != null) {
      collection.listRule = listRule.isEmpty ? null : listRule;
    }
    if (viewRule != null) {
      collection.viewRule = viewRule.isEmpty ? null : viewRule;
    }
    if (createRule != null) {
      collection.createRule = createRule.isEmpty ? null : createRule;
    }
    if (updateRule != null) {
      collection.updateRule = updateRule.isEmpty ? null : updateRule;
    }
    if (deleteRule != null) {
      collection.deleteRule = deleteRule.isEmpty ? null : deleteRule;
    }

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Gets all API rules for the collection.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// Returns map containing all rules (listRule, viewRule, createRule, updateRule, deleteRule)
  Future<Map<String, String?>> getRules(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);
    return {
      "listRule": collection.listRule,
      "viewRule": collection.viewRule,
      "createRule": collection.createRule,
      "updateRule": collection.updateRule,
      "deleteRule": collection.deleteRule,
    };
  }

  /// Sets the manage rule for an auth collection.
  ///
  /// ManageRule gives admin-like permissions to allow fully managing auth record(s),
  /// e.g. changing password without requiring the old one, directly updating verified state and email, etc.
  /// This rule is executed in addition to the Create and Update API rules.
  ///
  /// Only available for auth collections (type == "auth").
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [rule] - Rule expression (use null to remove; empty string is not allowed for manageRule)
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<CollectionModel> setManageRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("ManageRule is only available for auth collections");
    }

    collection.manageRule = rule?.isEmpty ?? true ? null : rule;

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  /// Sets the auth rule for an auth collection.
  ///
  /// AuthRule specifies additional record constraints applied after record authentication
  /// and right before returning the auth token response to the client.
  /// For example, to allow only verified users: `"verified = true"`
  ///
  /// Set to empty string to allow any Auth collection record to authenticate.
  /// Set to null to disallow authentication altogether for the collection.
  ///
  /// Only available for auth collections (type == "auth").
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [rule] - Rule expression (use null to disallow auth; empty string to allow all; non-empty for filter)
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<CollectionModel> setAuthRule(
    String collectionIdOrName,
    String? rule, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("AuthRule is only available for auth collections");
    }

    collection.authRule = rule?.isEmpty ?? true ? null : rule;

    return update(
      collectionIdOrName,
      body: collection.toJson(),
      query: query,
      headers: headers,
    );
  }

  // -------------------------------------------------------------------
  // Schema Query Methods
  // -------------------------------------------------------------------

  /// Gets the schema (fields and types) for a single collection.
  ///
  /// This method returns simplified schema information containing only
  /// field names, types, and basic metadata (required, system, hidden flags).
  /// This is useful for AI systems to understand the structure of collections
  /// without fetching the full collection definition.
  ///
  /// [collectionIdOrName] - Collection id or name
  /// Returns collection schema information
  Future<CollectionSchemaInfo> getSchema(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
      "$baseCrudPath/${Uri.encodeComponent(collectionIdOrName)}/schema",
      body: const {},
      query: query,
      headers: headers,
    )
        .then((data) {
      return CollectionSchemaInfo.fromJson(data);
    });
  }

  /// Gets the schema (fields and types) for all collections in the system.
  ///
  /// This method returns simplified schema information for all collections,
  /// containing only field names, types, and basic metadata (required, system, hidden flags).
  /// This is useful for AI systems to understand the overall structure of the system
  /// and all available collections without fetching full collection definitions.
  ///
  /// Returns object containing list of collection schemas
  Future<List<CollectionSchemaInfo>> getAllSchemas({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client
        .send<Map<String, dynamic>>(
      "$baseCrudPath/schemas",
      body: const {},
      query: query,
      headers: headers,
    )
        .then((data) {
      final collectionsData = data["collections"] as List<dynamic>? ?? [];
      return collectionsData
          .map((item) => CollectionSchemaInfo.fromJson(
              item as Map<String, dynamic>))
          .toList();
    });
  }

  // -------------------------------------------------------------------
  // OAuth2 Configuration Methods
  // -------------------------------------------------------------------

  /// Enables OAuth2 authentication for an auth collection.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<CollectionModel> enableOAuth2(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] == null) {
      json["oauth2"] = {
        "enabled": true,
        "mappedFields": <String, String>{},
        "providers": <dynamic>[],
      };
    } else {
      (json["oauth2"] as Map<String, dynamic>)["enabled"] = true;
    }

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }

  /// Disables OAuth2 authentication for an auth collection.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<CollectionModel> disableOAuth2(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] != null) {
      (json["oauth2"] as Map<String, dynamic>)["enabled"] = false;
    }

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }

  /// Gets the OAuth2 configuration for an auth collection.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// Returns OAuth2 configuration object
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<Map<String, dynamic>> getOAuth2Config(
    String collectionIdOrName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    final oauth2 = json["oauth2"] as Map<String, dynamic>?;

    return {
      "enabled": oauth2?["enabled"] ?? false,
      "mappedFields": oauth2?["mappedFields"] ?? <String, String>{},
      "providers": oauth2?["providers"] ?? <dynamic>[],
    };
  }

  /// Sets the OAuth2 mapped fields for an auth collection.
  ///
  /// Mapped fields define how OAuth2 provider user data maps to collection fields.
  /// For example: { "name": "name", "email": "email", "avatarUrl": "avatar" }
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [mappedFields] - Map mapping OAuth2 fields to collection fields
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection
  Future<CollectionModel> setOAuth2MappedFields(
    String collectionIdOrName,
    Map<String, String> mappedFields, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] == null) {
      json["oauth2"] = {
        "enabled": false,
        "mappedFields": <String, String>{},
        "providers": <dynamic>[],
      };
    }
    (json["oauth2"] as Map<String, dynamic>)["mappedFields"] = mappedFields;

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }

  /// Adds a new OAuth2 provider to an auth collection.
  ///
  /// Before using this method, you need to:
  /// 1. Create an OAuth2 app in the provider's dashboard
  /// 2. Get the Client ID and Client Secret
  /// 3. Register a redirect URL (typically: https://yourdomain.com/api/oauth2-redirect)
  ///
  /// Supported provider names include: "google", "github", "gitlab", "discord",
  /// "facebook", "microsoft", "apple", "twitter", "spotify", "kakao", "twitch",
  /// "strava", "vk", "yandex", "patreon", "linkedin", "instagram", "vimeo",
  /// "digitalocean", "bitbucket", "dropbox", "planningcenter", "notion", "linear",
  /// "oidc", "oidc2", "oidc3", and more.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [provider] - OAuth2 provider configuration map
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection or provider is invalid
  Future<CollectionModel> addOAuth2Provider(
    String collectionIdOrName,
    Map<String, dynamic> provider, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] == null) {
      json["oauth2"] = {
        "enabled": false,
        "mappedFields": <String, String>{},
        "providers": <dynamic>[],
      };
    }

    final providers = (json["oauth2"] as Map<String, dynamic>)["providers"] as List<dynamic>;

    // Check if provider with this name already exists
    final providerName = provider["name"] as String?;
    if (providerName == null) {
      throw ArgumentError("Provider name is required");
    }

    final existingProviderIndex = providers.indexWhere(
      (p) => (p as Map<String, dynamic>)["name"] == providerName,
    );
    if (existingProviderIndex != -1) {
      throw ArgumentError('OAuth2 provider with name "$providerName" already exists');
    }

    // Add the new provider
    providers.add({
      "name": provider["name"],
      "clientId": provider["clientId"],
      "clientSecret": provider["clientSecret"],
      "authURL": provider["authURL"],
      "tokenURL": provider["tokenURL"],
      "userInfoURL": provider["userInfoURL"],
      "displayName": provider["displayName"] ?? provider["name"],
      if (provider.containsKey("pkce")) "pkce": provider["pkce"],
      if (provider.containsKey("extra")) "extra": provider["extra"],
    });

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }

  /// Updates an existing OAuth2 provider in an auth collection.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [providerName] - Name of the provider to update
  /// [updates] - Partial provider configuration map to update
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection or provider not found
  Future<CollectionModel> updateOAuth2Provider(
    String collectionIdOrName,
    String providerName,
    Map<String, dynamic> updates, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] == null) {
      throw ArgumentError("OAuth2 is not configured for this collection");
    }

    final providers = (json["oauth2"] as Map<String, dynamic>)["providers"] as List<dynamic>;

    final providerIndex = providers.indexWhere(
      (p) => (p as Map<String, dynamic>)["name"] == providerName,
    );
    if (providerIndex == -1) {
      throw ArgumentError('OAuth2 provider with name "$providerName" not found');
    }

    // Update the provider
    final provider = providers[providerIndex] as Map<String, dynamic>;
    provider.addAll(updates);
    providers[providerIndex] = provider;

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }

  /// Removes an OAuth2 provider from an auth collection.
  ///
  /// [collectionIdOrName] - Auth collection id or name
  /// [providerName] - Name of the provider to remove
  /// Returns the updated collection model
  /// Throws [ArgumentError] if collection is not an auth collection or provider not found
  Future<CollectionModel> removeOAuth2Provider(
    String collectionIdOrName,
    String providerName, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final collection = await getOne(collectionIdOrName, query: query, headers: headers);

    if (collection.type != "auth") {
      throw ArgumentError("OAuth2 is only available for auth collections");
    }

    final json = collection.toJson();
    if (json["oauth2"] == null) {
      throw ArgumentError("OAuth2 is not configured for this collection");
    }

    final providers = (json["oauth2"] as Map<String, dynamic>)["providers"] as List<dynamic>;

    final providerIndex = providers.indexWhere(
      (p) => (p as Map<String, dynamic>)["name"] == providerName,
    );
    if (providerIndex == -1) {
      throw ArgumentError('OAuth2 provider with name "$providerName" not found');
    }

    // Remove the provider
    providers.removeAt(providerIndex);

    return update(
      collectionIdOrName,
      body: json,
      query: query,
      headers: headers,
    );
  }
}
