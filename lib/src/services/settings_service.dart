import "../client.dart";
import "../dtos/apple_client_secret.dart";
import "base_service.dart";

/// The service that handles the **Settings APIs**.
///
/// Usually shouldn't be initialized manually and instead
/// [Bosbase.settings] should be used.
class SettingsService extends BaseService {
  SettingsService(super.client);

  /// Fetch all available app settings.
  Future<Map<String, dynamic>> getAll({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      "/api/settings",
      query: query,
      headers: headers,
    );
  }

  /// Bulk updates app settings.
  Future<Map<String, dynamic>> update({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return client.send<Map<String, dynamic>>(
      "/api/settings",
      method: "PATCH",
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Performs a S3 storage connection test.
  Future<void> testS3({
    String filesystem = "storage", // "storage" or "backups"
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["filesystem"] ??= filesystem;

    return client.send(
      "/api/settings/test/s3",
      method: "POST",
      body: enrichedBody,
      query: query,
      headers: headers,
    );
  }

  /// Sends a test email.
  ///
  /// The possible `template` values are:
  /// - verification
  /// - password-reset
  /// - email-change
  Future<void> testEmail(
    String toEmail,
    String template, {
    String? collection, // fallback to _superusers
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["email"] ??= toEmail;
    enrichedBody["template"] ??= template;
    enrichedBody["collection"] ??= collection;

    return client.send(
      "/api/settings/test/email",
      method: "POST",
      body: enrichedBody,
      query: query,
      headers: headers,
    );
  }

  /// Generates a new Apple OAuth2 client secret.
  Future<AppleClientSecret> generateAppleClientSecret(
    String clientId,
    String teamId,
    String keyId,
    String privateKey,
    int duration, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["clientId"] ??= clientId;
    enrichedBody["teamId"] ??= teamId;
    enrichedBody["keyId"] ??= keyId;
    enrichedBody["privateKey"] ??= privateKey;
    enrichedBody["duration"] ??= duration;

    return client
        .send<Map<String, dynamic>>(
          "/api/settings/apple/generate-client-secret",
          method: "POST",
          body: enrichedBody,
          query: query,
          headers: headers,
        )
        .then(AppleClientSecret.fromJson);
  }

  // -------------------------------------------------------------------
  // Settings Category Helpers
  // -------------------------------------------------------------------

  /// Gets a specific settings category.
  ///
  /// [category] - The settings category name (meta, smtp, s3, backups, batch, rateLimits, trustedProxy, logs)
  /// Returns the settings category object or null if not found
  Future<Map<String, dynamic>?> getCategory(
    String category, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final allSettings = await getAll(query: query, headers: headers);
    return allSettings[category] as Map<String, dynamic>?;
  }

  /// Updates the Meta configuration (app name, URL, sender info, etc.).
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateMeta({
    String? appName,
    String? appURL,
    String? senderName,
    String? senderAddress,
    bool? hideControls,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["meta"] = {
      if (appName != null) "appName": appName,
      if (appURL != null) "appURL": appURL,
      if (senderName != null) "senderName": senderName,
      if (senderAddress != null) "senderAddress": senderAddress,
      if (hideControls != null) "hideControls": hideControls,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  /// Updates the SMTP email configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateSMTP({
    bool? enabled,
    String? host,
    int? port,
    String? username,
    String? password,
    String? authMethod,
    bool? tls,
    String? localName,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["smtp"] = {
      if (enabled != null) "enabled": enabled,
      if (host != null) "host": host,
      if (port != null) "port": port,
      if (username != null) "username": username,
      if (password != null) "password": password,
      if (authMethod != null) "authMethod": authMethod,
      if (tls != null) "tls": tls,
      if (localName != null) "localName": localName,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  /// Updates the S3 storage configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateS3({
    bool? enabled,
    String? bucket,
    String? region,
    String? endpoint,
    String? accessKey,
    String? secret,
    bool? forcePathStyle,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["s3"] = {
      if (enabled != null) "enabled": enabled,
      if (bucket != null) "bucket": bucket,
      if (region != null) "region": region,
      if (endpoint != null) "endpoint": endpoint,
      if (accessKey != null) "accessKey": accessKey,
      if (secret != null) "secret": secret,
      if (forcePathStyle != null) "forcePathStyle": forcePathStyle,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  // -------------------------------------------------------------------
  // Storage-Specific Helpers (S3 File Storage)
  // -------------------------------------------------------------------

  /// Gets the current S3 storage configuration.
  ///
  /// This is a convenience method specifically for file storage S3 configuration,
  /// equivalent to calling getCategory("s3").
  ///
  /// Returns the S3 storage configuration object or null if not found
  Future<Map<String, dynamic>?> getStorageS3({
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return getCategory("s3", query: query, headers: headers);
  }

  /// Updates the S3 storage configuration for file storage.
  ///
  /// This is a convenience method specifically for file storage S3 configuration,
  /// equivalent to calling updateS3().
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateStorageS3({
    bool? enabled,
    String? bucket,
    String? region,
    String? endpoint,
    String? accessKey,
    String? secret,
    bool? forcePathStyle,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return updateS3(
      enabled: enabled,
      bucket: bucket,
      region: region,
      endpoint: endpoint,
      accessKey: accessKey,
      secret: secret,
      forcePathStyle: forcePathStyle,
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Tests the S3 storage connection for file storage.
  ///
  /// This is a convenience method that tests the "storage" filesystem,
  /// equivalent to calling testS3(filesystem: "storage").
  Future<void> testStorageS3({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    return testS3(
      filesystem: "storage",
      body: body,
      query: query,
      headers: headers,
    );
  }

  /// Updates the Backups configuration (scheduling and S3 storage).
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateBackups({
    String? cron,
    int? cronMaxKeep,
    Map<String, dynamic>? s3,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["backups"] = {
      if (cron != null) "cron": cron,
      if (cronMaxKeep != null) "cronMaxKeep": cronMaxKeep,
      if (s3 != null) "s3": s3,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  /// Updates the Batch request configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateBatch({
    bool? enabled,
    int? maxRequests,
    int? timeout,
    int? maxBodySize,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["batch"] = {
      if (enabled != null) "enabled": enabled,
      if (maxRequests != null) "maxRequests": maxRequests,
      if (timeout != null) "timeout": timeout,
      if (maxBodySize != null) "maxBodySize": maxBodySize,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  /// Updates the Rate Limits configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateRateLimits({
    bool? enabled,
    List<Map<String, dynamic>>? rules,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["rateLimits"] = {
      if (enabled != null) "enabled": enabled,
      if (rules != null) "rules": rules,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }

  /// Updates the Trusted Proxy configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateTrustedProxy({
    List<String>? headers,
    bool? useLeftmostIP,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> requestHeaders = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["trustedProxy"] = {
      if (headers != null) "headers": headers,
      if (useLeftmostIP != null) "useLeftmostIP": useLeftmostIP,
    };

    return update(body: enrichedBody, query: query, headers: requestHeaders);
  }

  /// Updates the Logs configuration.
  ///
  /// Returns updated settings
  Future<Map<String, dynamic>> updateLogs({
    int? maxDays,
    int? minLevel,
    bool? logIP,
    bool? logAuthId,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) {
    final enrichedBody = Map<String, dynamic>.of(body);
    enrichedBody["logs"] = {
      if (maxDays != null) "maxDays": maxDays,
      if (minLevel != null) "minLevel": minLevel,
      if (logIP != null) "logIP": logIP,
      if (logAuthId != null) "logAuthId": logAuthId,
    };

    return update(body: enrichedBody, query: query, headers: headers);
  }
}
