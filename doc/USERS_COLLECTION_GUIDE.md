# Built-in Users Collection Guide - Dart SDK

This guide explains how to use the built-in `users` collection for authentication, registration, and API rules. **The `users` collection is automatically created when BosBase is initialized and does not need to be created manually.**

## Table of Contents

1. [Overview](#overview)
2. [Users Collection Structure](#users-collection-structure)
3. [User Registration](#user-registration)
4. [User Login/Authentication](#user-loginauthentication)
5. [API Rules and Filters with Users](#api-rules-and-filters-with-users)
6. [Using Users with Other Collections](#using-users-with-other-collections)
7. [Complete Examples](#complete-examples)

---

## Overview

The `users` collection is a **built-in auth collection** that is automatically created when BosBase starts. It has:

- **Collection ID**: `_pb_users_auth_`
- **Collection Name**: `users`
- **Type**: `auth` (authentication collection)
- **Purpose**: User accounts, authentication, and authorization

**Important**: 
- ✅ **DO NOT** create a new `users` collection manually
- ✅ **DO** use the existing built-in `users` collection
- ✅ The collection already has proper API rules configured
- ✅ It supports password, OAuth2, and OTP authentication

### Getting Users Collection Information

```dart
// Get the users collection details
final usersCollection = await pb.collections.getOne('users');
// or by ID
final usersCollection = await pb.collections.getOne('_pb_users_auth_');

print('Collection ID: ${usersCollection.id}');
print('Collection Name: ${usersCollection.name}');
print('Collection Type: ${usersCollection.type}');
print('Fields: ${usersCollection.fields}');
print('API Rules:');
print('  listRule: ${usersCollection.listRule}');
print('  viewRule: ${usersCollection.viewRule}');
print('  createRule: ${usersCollection.createRule}');
print('  updateRule: ${usersCollection.updateRule}');
print('  deleteRule: ${usersCollection.deleteRule}');
```

---

## Users Collection Structure

### System Fields (Automatically Created)

These fields are automatically added to all auth collections (including `users`):

| Field Name | Type | Description | Required | Hidden |
|------------|------|-------------|----------|--------|
| `id` | text | Unique record identifier | Yes | No |
| `email` | email | User email address | Yes* | No |
| `username` | text | Username (optional, if enabled) | No* | No |
| `password` | password | Hashed password | Yes* | Yes |
| `tokenKey` | text | Token key for auth tokens | Yes | Yes |
| `emailVisibility` | bool | Whether email is visible to others | No | No |
| `verified` | bool | Whether email is verified | No | No |
| `created` | date | Record creation timestamp | Yes | No |
| `updated` | date | Last update timestamp | Yes | No |

*Required based on authentication method configuration (password auth, username auth, etc.)

### Custom Fields (Pre-configured)

The built-in `users` collection includes these custom fields:

| Field Name | Type | Description | Required |
|------------|------|-------------|----------|
| `name` | text | User's display name | No (max: 255 characters) |
| `avatar` | file | User avatar image | No (max: 1 file, images only) |

### Default API Rules

The `users` collection comes with these default API rules:

```dart
{
  'listRule': 'id = @request.auth.id',    // Users can only list themselves
  'viewRule': 'id = @request.auth.id',   // Users can only view themselves
  'createRule': '',                       // Anyone can register (public)
  'updateRule': 'id = @request.auth.id', // Users can only update themselves
  'deleteRule': 'id = @request.auth.id'  // Users can only delete themselves
}
```

**Understanding the Rules:**

1. **`listRule: "id = @request.auth.id"`**
   - Users can only see their own record when listing
   - If not authenticated, returns empty list (not an error)
   - Superusers can see all users

2. **`viewRule: "id = @request.auth.id"`**
   - Users can only view their own record
   - If trying to view another user, returns 404
   - Superusers can view any user

3. **`createRule: ""`** (empty string)
   - **Public registration** - Anyone can create a user account
   - No authentication required
   - This enables self-registration

4. **`updateRule: "id = @request.auth.id"`**
   - Users can only update their own record
   - Prevents users from modifying other users' data
   - Superusers can update any user

5. **`deleteRule: "id = @request.auth.id"`**
   - Users can only delete their own account
   - Prevents users from deleting other users
   - Superusers can delete any user

**Note**: These rules ensure user privacy and security. Users can only access and modify their own data unless they are superusers.

---

## User Registration

### Basic Registration

Users can register by creating a record in the `users` collection. The `createRule` is set to `""` (empty string), meaning **anyone can register**.

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

// Register a new user
final newUser = await pb.collection('users').create(body: {
  'email': 'user@example.com',
  'password': 'securepassword123',
  'passwordConfirm': 'securepassword123',
  'name': 'John Doe',
});

print('User registered: ${newUser.id}');
print('Email: ${newUser.data['email']}');
```

### Registration with Email Verification

```dart
// Register user (verification email sent automatically if configured)
final newUser = await pb.collection('users').create(body: {
  'email': 'user@example.com',
  'password': 'securepassword123',
  'passwordConfirm': 'securepassword123',
  'name': 'John Doe',
});

// User will receive verification email
// After clicking link, verified field becomes true
print('Verified: ${newUser.data['verified']}'); // false initially
```

### Registration with Username

If username authentication is enabled in the collection settings:

```dart
final newUser = await pb.collection('users').create(body: {
  'email': 'user@example.com',
  'username': 'johndoe',
  'password': 'securepassword123',
  'passwordConfirm': 'securepassword123',
  'name': 'John Doe',
});
```

### Registration with Avatar Upload

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

final file = File('/path/to/avatar.jpg');
final fileBytes = await file.readAsBytes();
final multipartFile = http.MultipartFile.fromBytes(
  'avatar',
  fileBytes,
  filename: 'avatar.jpg',
);

final request = http.MultipartRequest(
  'POST',
  Uri.parse('${pb.baseURL}/api/collections/users/records'),
);
request.fields['email'] = 'user@example.com';
request.fields['password'] = 'securepassword123';
request.fields['passwordConfirm'] = 'securepassword123';
request.fields['name'] = 'John Doe';
request.files.add(multipartFile);
request.headers['Authorization'] = 'Bearer ${pb.authStore.token}';

final response = await request.send();
final responseBody = await response.stream.bytesToString();
final newUser = RecordModel.fromJson(jsonDecode(responseBody));
```

### Check if Email Exists

```dart
try {
  final existing = await pb.collection('users').getFirstListItem(
    'email = "user@example.com"',
  );
  print('Email already exists');
} on ClientException catch (e) {
  if (e.statusCode == 404) {
    print('Email is available');
  }
}
```

---

## User Login/Authentication

### Password Authentication

```dart
// Login with email and password
final authData = await pb.collection('users').authWithPassword(
  'user@example.com',
  'password123',
);

// Auth data is automatically stored
print(pb.authStore.isValid);  // true
print(pb.authStore.token);    // JWT token
print(pb.authStore.record);   // User record
```

### Login with Username

If username authentication is enabled:

```dart
final authData = await pb.collection('users').authWithPassword(
  'johndoe',  // username instead of email
  'password123',
);
```

### OAuth2 Authentication

```dart
import 'package:url_launcher/url_launcher.dart';

// Login with OAuth2 (e.g., Google)
final authData = await pb.collection('users').authWithOAuth2(
  'google',
  (url) async {
    // Open OAuth2 URL
    await launchUrl(url);
  },
);

// If user doesn't exist, account is created automatically
print('User: ${pb.authStore.record?.data}');
```

### OTP Authentication

```dart
// Step 1: Request OTP
final otpResult = await pb.collection('users').requestOTP('user@example.com');

// Step 2: Authenticate with OTP code from email
final authData = await pb.collection('users').authWithOTP(
  otpResult.otpId,
  '123456', // OTP code from email
);
```

### Check Current Authentication

```dart
if (pb.authStore.isValid) {
  final user = pb.authStore.record;
  print('Logged in as: ${user?.data['email']}');
  print('User ID: ${user?.id}');
  print('Name: ${user?.data['name']}');
} else {
  print('Not authenticated');
}
```

### Refresh Auth Token

```dart
// Refresh the authentication token
await pb.collection('users').authRefresh();
```

### Logout

```dart
pb.authStore.clear();
```

### Get Current User

```dart
final currentUser = pb.authStore.record;
if (currentUser != null) {
  print('Current user: ${currentUser.data['email']}');
  print('User ID: ${currentUser.id}');
  print('Name: ${currentUser.data['name']}');
  print('Verified: ${currentUser.data['verified']}');
}
```

### Accessing User Fields

```dart
// After authentication, access user fields
final user = pb.authStore.record;

if (user != null) {
  // System fields
  print(user.id);                    // User ID
  print(user.data['email']);         // Email
  print(user.data['username']);     // Username (if enabled)
  print(user.data['verified']);     // Email verification status
  print(user.data['emailVisibility']); // Email visibility setting
  print(user.data['created']);      // Creation date
  print(user.data['updated']);      // Last update date
  
  // Custom fields (from users collection)
  print(user.data['name']);          // Display name
  print(user.data['avatar']);        // Avatar filename
}
```

---

## API Rules and Filters with Users

### Understanding @request.auth

The `@request.auth` identifier provides access to the currently authenticated user's data in API rules and filters.

**Available Properties:**
- `@request.auth.id` - User's record ID
- `@request.auth.email` - User's email
- `@request.auth.username` - User's username (if enabled)
- `@request.auth.*` - Any field from the user record

### Common API Rule Patterns

#### 1. Require Authentication

```dart
// Only authenticated users can access
'listRule': '@request.auth.id != ""'
'viewRule': '@request.auth.id != ""'
'createRule': '@request.auth.id != ""'
```

#### 2. Owner-Based Access

```dart
// Users can only access their own records
'viewRule': 'author = @request.auth.id'
'updateRule': 'author = @request.auth.id'
'deleteRule': 'author = @request.auth.id'
```

#### 3. Public with User-Specific Data

```dart
// Public can see published, users can see their own
'listRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"'
'viewRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"'
```

#### 4. Role-Based Access (if you add a role field)

```dart
// Assuming you add a 'role' select field to users collection
'listRule': '@request.auth.id != "" && @request.auth.role = "admin"'
'updateRule': '@request.auth.role = "admin" || author = @request.auth.id'
```

#### 5. Verified Users Only

```dart
// Only verified users can create
'createRule': '@request.auth.id != "" && @request.auth.verified = true'
```

### Setting API Rules for Other Collections

When creating collections that relate to users:

```dart
// Create posts collection with user-based rules
final postsCollection = await pb.collections.create(body: {
  'name': 'posts',
  'type': 'base',
  'fields': [
    {
      'name': 'title',
      'type': 'text',
      'required': true,
    },
    {
      'name': 'content',
      'type': 'editor',
    },
    {
      'name': 'author',
      'type': 'relation',
      'collectionId': '_pb_users_auth_', // Reference to users collection
      'maxSelect': 1,
      'required': true,
    },
    {
      'name': 'status',
      'type': 'select',
      'options': {
        'values': ['draft', 'published'],
      },
    },
  ],
  // Public can see published posts, users can see their own
  'listRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"',
  'viewRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"',
  // Only authenticated users can create
  'createRule': '@request.auth.id != ""',
  // Only authors can update their posts
  'updateRule': 'author = @request.auth.id',
  // Only authors can delete their posts
  'deleteRule': 'author = @request.auth.id',
});
```

### Using Filters with Users

```dart
// Get posts by current user
final myPosts = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  filter: 'author = @request.auth.id',
);

// Get posts by verified users only
final verifiedPosts = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  filter: 'author.verified = true',
  expand: 'author',
);

// Get posts where author name contains "John"
final posts = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  filter: 'author.name ~ "John"',
  expand: 'author',
);
```

---

## Using Users with Other Collections

### Creating Relations to Users

When creating collections that need to reference users:

```dart
// Create a posts collection with author relation
final postsCollection = await pb.collections.create(body: {
  'name': 'posts',
  'type': 'base',
  'fields': [
    {
      'name': 'title',
      'type': 'text',
      'required': true,
    },
    {
      'name': 'author',
      'type': 'relation',
      'collectionId': '_pb_users_auth_', // Users collection ID
      // OR use collection name
      // 'collectionName': 'users',
      'maxSelect': 1,
      'required': true,
    },
  ],
});
```

### Creating Records with User Relations

```dart
// Authenticate first
await pb.collection('users').authWithPassword('user@example.com', 'password');

// Create a post with current user as author
final post = await pb.collection('posts').create(body: {
  'title': 'My First Post',
  'author': pb.authStore.record?.id, // Current user's ID
});
```

### Querying with User Relations

```dart
// Get posts with author information
final posts = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  expand: 'author', // Expand the author relation
);

for (final post in posts.items) {
  print('Post: ${post.data['title']}');
  final author = post.expand?['author'] as RecordModel?;
  print('Author: ${author?.data['name']}');
  print('Author Email: ${author?.data['email']}');
}

// Filter posts by author
final userPosts = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  filter: 'author = "USER_ID"',
  expand: 'author',
);
```

### Updating User Profile

```dart
// Users can update their own profile
await pb.collection('users').update(
  pb.authStore.record!.id,
  body: {
    'name': 'Updated Name',
  },
);

// Update with avatar
final file = File('/path/to/new_avatar.jpg');
final fileBytes = await file.readAsBytes();
final multipartFile = http.MultipartFile.fromBytes(
  'avatar',
  fileBytes,
  filename: 'avatar.jpg',
);

final request = http.MultipartRequest(
  'PATCH',
  Uri.parse('${pb.baseURL}/api/collections/users/records/${pb.authStore.record!.id}'),
);
request.fields['name'] = 'New Name';
request.files.add(multipartFile);
request.headers['Authorization'] = 'Bearer ${pb.authStore.token}';

final response = await request.send();
```

---

## Complete Examples

### Example 1: User Registration and Login Flow

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

Future<void> registerAndLogin() async {
  try {
    // 1. Register new user
    final newUser = await pb.collection('users').create(body: {
      'email': 'newuser@example.com',
      'password': 'securepassword123',
      'passwordConfirm': 'securepassword123',
      'name': 'New User',
    });
    
    print('Registration successful: ${newUser.id}');
    
    // 2. Login with credentials
    final authData = await pb.collection('users').authWithPassword(
      'newuser@example.com',
      'securepassword123',
    );
    
    print('Login successful');
    print('Token: ${authData.token}');
    print('User: ${authData.record.data}');
  } on ClientException catch (e) {
    print('Error: ${e.message}');
    if (e.response != null) {
      print('Validation errors: ${e.response}');
    }
  }
}

void main() {
  registerAndLogin();
}
```

### Example 2: Creating User-Related Collections

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

// Authenticate as superuser to create collections
await pb.admins.authWithPassword('admin@example.com', 'adminpassword');

Future<void> setupUserRelatedCollections() async {
  // Create posts collection linked to users
  final postsCollection = await pb.collections.create(body: {
    'name': 'posts',
    'type': 'base',
    'fields': [
      {
        'name': 'title',
        'type': 'text',
        'required': true,
      },
      {
        'name': 'content',
        'type': 'editor',
      },
      {
        'name': 'author',
        'type': 'relation',
        'collectionId': '_pb_users_auth_', // Link to users
        'maxSelect': 1,
        'required': true,
      },
      {
        'name': 'status',
        'type': 'select',
        'options': {
          'values': ['draft', 'published'],
        },
      },
    ],
    // API rules using users collection
    'listRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"',
    'viewRule': '@request.auth.id != "" && author = @request.auth.id || status = "published"',
    'createRule': '@request.auth.id != ""',
    'updateRule': 'author = @request.auth.id',
    'deleteRule': 'author = @request.auth.id',
  });
  
  // Create comments collection
  final commentsCollection = await pb.collections.create(body: {
    'name': 'comments',
    'type': 'base',
    'fields': [
      {
        'name': 'content',
        'type': 'text',
        'required': true,
      },
      {
        'name': 'post',
        'type': 'relation',
        'collectionId': postsCollection.id,
        'maxSelect': 1,
        'required': true,
      },
      {
        'name': 'author',
        'type': 'relation',
        'collectionId': '_pb_users_auth_', // Link to users
        'maxSelect': 1,
        'required': true,
      },
    ],
    'listRule': '@request.auth.id != ""',
    'viewRule': '@request.auth.id != ""',
    'createRule': '@request.auth.id != ""',
    'updateRule': 'author = @request.auth.id',
    'deleteRule': 'author = @request.auth.id',
  });
  
  print('Collections created successfully');
}

void main() {
  setupUserRelatedCollections();
}
```

### Example 3: User Creates and Manages Their Posts

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

Future<void> userPostManagement() async {
  // 1. User logs in
  await pb.collection('users').authWithPassword('user@example.com', 'password');
  final userId = pb.authStore.record!.id;
  
  // 2. User creates a post
  final post = await pb.collection('posts').create(body: {
    'title': 'My First Post',
    'content': 'This is my content',
    'author': userId,
    'status': 'draft',
  });
  
  print('Post created: ${post.id}');
  
  // 3. User lists their own posts
  final myPosts = await pb.collection('posts').getList(
    page: 1,
    perPage: 20,
    filter: 'author = "$userId"',
    sort: '-created',
  );
  
  print('My posts: ${myPosts.items.length}');
  
  // 4. User updates their post
  await pb.collection('posts').update(post.id, body: {
    'title': 'Updated Title',
    'status': 'published',
  });
  
  // 5. User views their post with author info
  final updatedPost = await pb.collection('posts').getOne(
    post.id,
    expand: 'author',
  );
  
  final author = updatedPost.expand?['author'] as RecordModel?;
  print('Post author: ${author?.data['name']}');
  
  // 6. User deletes their post
  await pb.collection('posts').delete(post.id);
  
  print('Post deleted');
}

void main() {
  userPostManagement();
}
```

### Example 4: Public Posts with User Information

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

Future<void> viewPublicPosts() async {
  // No authentication required for public posts
  
  // Get published posts with author information
  final posts = await pb.collection('posts').getList(
    page: 1,
    perPage: 20,
    filter: 'status = "published"',
    expand: 'author',
    sort: '-created',
  );
  
  for (final post in posts.items) {
    print('Title: ${post.data['title']}');
    final author = post.expand?['author'] as RecordModel?;
    print('Author: ${author?.data['name']}');
    // Email visibility depends on author's emailVisibility setting
    if (author?.data['emailVisibility'] == true) {
      print('Author Email: ${author?.data['email']}');
    }
  }
}

void main() {
  viewPublicPosts();
}
```

### Example 5: Email Verification Flow

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

Future<void> emailVerificationFlow() async {
  // 1. User registers
  final newUser = await pb.collection('users').create(body: {
    'email': 'user@example.com',
    'password': 'password123',
    'passwordConfirm': 'password123',
    'name': 'User Name',
  });
  
  print('User registered, verification email sent');
  print('Verified status: ${newUser.data['verified']}'); // false
  
  // 2. User clicks verification link in email
  // (This is handled by the backend automatically)
  
  // 3. Check verification status
  final user = await pb.collection('users').getOne(newUser.id);
  print('Verified: ${user.data['verified']}');
  
  // 4. Request new verification email if needed
  await pb.collection('users').requestVerification('user@example.com');
}

void main() {
  emailVerificationFlow();
}
```

### Example 6: Password Reset Flow

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

Future<void> passwordResetFlow() async {
  // 1. User requests password reset
  await pb.collection('users').requestPasswordReset('user@example.com');
  print('Password reset email sent');
  
  // 2. User clicks link in email and gets reset token
  // (Token is in the URL query parameter)
  
  // 3. User confirms password reset with token
  await pb.collection('users').confirmPasswordReset(
    'RESET_TOKEN_FROM_EMAIL',
    'newpassword123',
    'newpassword123', // passwordConfirm
  );
  
  print('Password reset successful');
  
  // 4. User can now login with new password
  await pb.collection('users').authWithPassword(
    'user@example.com',
    'newpassword123',
  );
}

void main() {
  passwordResetFlow();
}
```

### Example 7: Using Users in API Rules for Other Collections

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

// Authenticate as superuser
await pb.admins.authWithPassword('admin@example.com', 'adminpassword');

// Create a blog system with user-based access control
Future<void> createBlogSystem() async {
  // Create posts collection
  final posts = await pb.collections.create(body: {
    'name': 'posts',
    'type': 'base',
    'fields': [
      {'name': 'title', 'type': 'text', 'required': true},
      {'name': 'content', 'type': 'editor'},
      {'name': 'author', 'type': 'relation', 'collectionId': '_pb_users_auth_', 'maxSelect': 1, 'required': true},
      {'name': 'status', 'type': 'select', 'options': {'values': ['draft', 'published']}},
    ],
    // Public can see published, authors can see their own
    'listRule': 'status = "published" || author = @request.auth.id',
    'viewRule': 'status = "published" || author = @request.auth.id',
    'createRule': '@request.auth.id != ""',
    'updateRule': 'author = @request.auth.id',
    'deleteRule': 'author = @request.auth.id',
  });
  
  // Create comments collection
  final comments = await pb.collections.create(body: {
    'name': 'comments',
    'type': 'base',
    'fields': [
      {'name': 'content', 'type': 'text', 'required': true},
      {'name': 'post', 'type': 'relation', 'collectionId': posts.id, 'maxSelect': 1, 'required': true},
      {'name': 'author', 'type': 'relation', 'collectionId': '_pb_users_auth_', 'maxSelect': 1, 'required': true},
    ],
    // Anyone can see comments on published posts, authors can see their own
    'listRule': 'post.status = "published" || author = @request.auth.id',
    'viewRule': 'post.status = "published" || author = @request.auth.id',
    'createRule': '@request.auth.id != "" && post.status = "published"',
    'updateRule': 'author = @request.auth.id',
    'deleteRule': 'author = @request.auth.id',
  });
  
  print('Blog system created with user-based access control');
}

void main() {
  createBlogSystem();
}
```

---

## Best Practices

1. **Always use the built-in `users` collection** - Don't create a new one
2. **Use `_pb_users_auth_` as collectionId** when creating relations
3. **Check authentication** before user-specific operations
4. **Use `@request.auth.id`** in API rules for user-based access control
5. **Expand user relations** when you need user information
6. **Respect emailVisibility** - Don't expose emails unless user allows it
7. **Handle verification** - Check `verified` field for email verification status
8. **Use proper error handling** for registration/login failures
9. **Use async/await** for better readability
10. **Type safety** - Use proper type annotations and null checks

---

## Common Patterns

### Pattern 1: Owner-Only Access

```dart
// Users can only access their own records
'updateRule': 'author = @request.auth.id'
'deleteRule': 'author = @request.auth.id'
```

### Pattern 2: Public Read, Authenticated Write

```dart
'listRule': 'status = "published" || author = @request.auth.id'
'viewRule': 'status = "published" || author = @request.auth.id'
'createRule': '@request.auth.id != ""'
```

### Pattern 3: Verified Users Only

```dart
'createRule': '@request.auth.id != "" && @request.auth.verified = true'
```

### Pattern 4: Filter by Current User

```dart
final myRecords = await pb.collection('posts').getList(
  page: 1,
  perPage: 20,
  filter: 'author = "${pb.authStore.record?.id}"',
);
```

---

This guide covers all essential operations with the built-in `users` collection. Remember: **always use the existing `users` collection, never create a new one manually.**

