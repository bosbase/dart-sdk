# OAuth2 Configuration Guide

This guide explains how to configure OAuth2 authentication providers for auth collections using the BosBase Dart SDK.

## Overview

OAuth2 allows users to authenticate with your application using third-party providers like Google, GitHub, Facebook, etc. Before you can use OAuth2 authentication, you need to:

1. **Create an OAuth2 app** in the provider's dashboard
2. **Obtain Client ID and Client Secret** from the provider
3. **Register a redirect URL** (typically: `https://yourdomain.com/api/oauth2-redirect`)
4. **Configure the provider** in your BosBase auth collection using the SDK

## Prerequisites

- An auth collection in your BosBase instance
- OAuth2 app credentials (Client ID and Client Secret) from your chosen provider
- Admin/superuser authentication to configure collections

## Supported Providers

The following OAuth2 providers are supported:

- **google** - Google OAuth2
- **github** - GitHub OAuth2
- **gitlab** - GitLab OAuth2
- **discord** - Discord OAuth2
- **facebook** - Facebook OAuth2
- **microsoft** - Microsoft OAuth2
- **apple** - Apple Sign In
- **twitter** - Twitter OAuth2
- **spotify** - Spotify OAuth2
- **kakao** - Kakao OAuth2
- **twitch** - Twitch OAuth2
- **strava** - Strava OAuth2
- **vk** - VK OAuth2
- **yandex** - Yandex OAuth2
- **patreon** - Patreon OAuth2
- **linkedin** - LinkedIn OAuth2
- **instagram** - Instagram OAuth2
- **vimeo** - Vimeo OAuth2
- **digitalocean** - DigitalOcean OAuth2
- **bitbucket** - Bitbucket OAuth2
- **dropbox** - Dropbox OAuth2
- **planningcenter** - Planning Center OAuth2
- **notion** - Notion OAuth2
- **linear** - Linear OAuth2
- **oidc**, **oidc2**, **oidc3** - OpenID Connect (OIDC) providers

## Basic Usage

### 1. Enable OAuth2 for a Collection

First, enable OAuth2 authentication for your auth collection:

```dart
import 'package:bosbase/bosbase.dart';

final client = Bosbase('https://your-instance.com');

// Authenticate as admin
await client.admins.authWithPassword('admin@example.com', 'password');

// Enable OAuth2 for the "users" collection
await client.collections.enableOAuth2('users');
```

### 2. Add an OAuth2 Provider

Add a provider configuration to your collection. You'll need the URLs and credentials from your OAuth2 app:

```dart
// Add Google OAuth2 provider
await client.collections.addOAuth2Provider('users', {
  'name': 'google',
  'clientId': 'your-google-client-id',
  'clientSecret': 'your-google-client-secret',
  'authURL': 'https://accounts.google.com/o/oauth2/v2/auth',
  'tokenURL': 'https://oauth2.googleapis.com/token',
  'userInfoURL': 'https://www.googleapis.com/oauth2/v2/userinfo',
  'displayName': 'Google',
  'pkce': true, // Optional: enable PKCE if supported
});
```

### 3. Configure Field Mapping

Map OAuth2 provider fields to your collection fields:

```dart
await client.collections.setOAuth2MappedFields('users', {
  'name': 'name',        // OAuth2 "name" → collection "name"
  'email': 'email',      // OAuth2 "email" → collection "email"
  'avatarUrl': 'avatar', // OAuth2 "avatarUrl" → collection "avatar"
});
```

### 4. Get OAuth2 Configuration

Retrieve the current OAuth2 configuration:

```dart
final config = await client.collections.getOAuth2Config('users');
print(config['enabled']);        // true/false
print(config['providers']);      // List of providers
print(config['mappedFields']);   // Field mappings
```

### 5. Update a Provider

Update an existing provider's configuration:

```dart
await client.collections.updateOAuth2Provider('users', 'google', {
  'clientId': 'new-client-id',
  'clientSecret': 'new-client-secret',
});
```

### 6. Remove a Provider

Remove an OAuth2 provider:

```dart
await client.collections.removeOAuth2Provider('users', 'google');
```

### 7. Disable OAuth2

Disable OAuth2 authentication for a collection:

```dart
await client.collections.disableOAuth2('users');
```

## Complete Example

Here's a complete example of setting up Google OAuth2:

```dart
import 'package:bosbase/bosbase.dart';

final client = Bosbase('https://your-instance.com');

// Authenticate as admin
await client.admins.authWithPassword('admin@example.com', 'password');

try {
  // 1. Enable OAuth2
  await client.collections.enableOAuth2('users');
  
  // 2. Add Google provider
  await client.collections.addOAuth2Provider('users', {
    'name': 'google',
    'clientId': 'your-google-client-id.apps.googleusercontent.com',
    'clientSecret': 'your-google-client-secret',
    'authURL': 'https://accounts.google.com/o/oauth2/v2/auth',
    'tokenURL': 'https://oauth2.googleapis.com/token',
    'userInfoURL': 'https://www.googleapis.com/oauth2/v2/userinfo',
    'displayName': 'Google',
    'pkce': true,
  });
  
  // 3. Configure field mappings
  await client.collections.setOAuth2MappedFields('users', {
    'name': 'name',
    'email': 'email',
    'avatarUrl': 'avatar',
  });
  
  print('OAuth2 configuration completed successfully!');
} catch (e) {
  print('Error configuring OAuth2: $e');
}
```

## Provider-Specific Examples

### GitHub

```dart
await client.collections.addOAuth2Provider('users', {
  'name': 'github',
  'clientId': 'your-github-client-id',
  'clientSecret': 'your-github-client-secret',
  'authURL': 'https://github.com/login/oauth/authorize',
  'tokenURL': 'https://github.com/login/oauth/access_token',
  'userInfoURL': 'https://api.github.com/user',
  'displayName': 'GitHub',
  'pkce': false,
});
```

### Discord

```dart
await client.collections.addOAuth2Provider('users', {
  'name': 'discord',
  'clientId': 'your-discord-client-id',
  'clientSecret': 'your-discord-client-secret',
  'authURL': 'https://discord.com/api/oauth2/authorize',
  'tokenURL': 'https://discord.com/api/oauth2/token',
  'userInfoURL': 'https://discord.com/api/users/@me',
  'displayName': 'Discord',
  'pkce': true,
});
```

### Microsoft

```dart
await client.collections.addOAuth2Provider('users', {
  'name': 'microsoft',
  'clientId': 'your-microsoft-client-id',
  'clientSecret': 'your-microsoft-client-secret',
  'authURL': 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
  'tokenURL': 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
  'userInfoURL': 'https://graph.microsoft.com/v1.0/me',
  'displayName': 'Microsoft',
  'pkce': true,
});
```

## Important Notes

1. **Redirect URL**: When creating your OAuth2 app in the provider's dashboard, you must register the redirect URL as: `https://yourdomain.com/api/oauth2-redirect`

2. **Provider Names**: The `name` field must match one of the supported provider names exactly (case-sensitive).

3. **PKCE Support**: Some providers support PKCE (Proof Key for Code Exchange) for enhanced security. Check your provider's documentation to determine if PKCE should be enabled.

4. **Client Secret Security**: Never expose your client secret in client-side code. These configuration methods should only be called from server-side code or with proper authentication.

5. **Field Mapping**: The mapped fields determine how OAuth2 user data is mapped to your collection fields. Common OAuth2 fields include:
   - `name` - User's full name
   - `email` - User's email address
   - `avatarUrl` - User's avatar/profile picture URL
   - `username` - User's username

6. **Multiple Providers**: You can add multiple OAuth2 providers to the same collection. Users can choose which provider to use during authentication.

## Error Handling

All methods throw `ClientException` if something goes wrong:

```dart
try {
  await client.collections.addOAuth2Provider('users', providerConfig);
} on ClientException catch (e) {
  if (e.statusCode == 400) {
    print('Invalid provider configuration: ${e.response}');
  } else if (e.statusCode == 403) {
    print('Permission denied. Make sure you are authenticated as admin.');
  } else {
    print('Unexpected error: $e');
  }
}
```

## API Reference

### `enableOAuth2(collectionIdOrName, {query, headers})`

Enables OAuth2 authentication for an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection

---

### `disableOAuth2(collectionIdOrName, {query, headers})`

Disables OAuth2 authentication for an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection

---

### `getOAuth2Config(collectionIdOrName, {query, headers})`

Gets the OAuth2 configuration for an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<Map<String, dynamic>>` with keys:
  - `enabled` (bool) - Whether OAuth2 is enabled
  - `mappedFields` (Map<String, String>) - Field mappings
  - `providers` (List<dynamic>) - List of provider configurations

**Throws:** `ArgumentError` if collection is not an auth collection

---

### `setOAuth2MappedFields(collectionIdOrName, mappedFields, {query, headers})`

Sets the OAuth2 mapped fields for an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `mappedFields` (Map<String, String>) - Map mapping OAuth2 fields to collection fields
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection

---

### `addOAuth2Provider(collectionIdOrName, provider, {query, headers})`

Adds a new OAuth2 provider to an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `provider` (Map<String, dynamic>) - OAuth2 provider configuration:
  - `name` (String, required) - Provider name
  - `clientId` (String, required) - OAuth2 client ID
  - `clientSecret` (String, required) - OAuth2 client secret
  - `authURL` (String, required) - Authorization URL
  - `tokenURL` (String, required) - Token exchange URL
  - `userInfoURL` (String, required) - User info API URL
  - `displayName` (String, optional) - Display name for the provider
  - `pkce` (bool, optional) - Enable PKCE
  - `extra` (Map<String, dynamic>, optional) - Additional provider-specific configuration
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection or provider is invalid

---

### `updateOAuth2Provider(collectionIdOrName, providerName, updates, {query, headers})`

Updates an existing OAuth2 provider in an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `providerName` (String) - Name of the provider to update
- `updates` (Map<String, dynamic>) - Partial provider configuration to update
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection or provider not found

---

### `removeOAuth2Provider(collectionIdOrName, providerName, {query, headers})`

Removes an OAuth2 provider from an auth collection.

**Parameters:**
- `collectionIdOrName` (String) - Collection id or name
- `providerName` (String) - Name of the provider to remove
- `query` (Map<String, dynamic>, optional) - Query parameters
- `headers` (Map<String, String>, optional) - Request headers

**Returns:** `Future<CollectionModel>`

**Throws:** `ArgumentError` if collection is not an auth collection or provider not found

---

## Next Steps

After configuring OAuth2 providers, users can authenticate using the `authWithOAuth2()` method. See the [Authentication Guide](./AUTHENTICATION.md) for details on using OAuth2 authentication in your application.

