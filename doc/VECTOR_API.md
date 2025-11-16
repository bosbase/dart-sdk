# Vector Database API

Vector database operations for semantic search, RAG (Retrieval-Augmented Generation), and AI applications in Dart.

> **Note**: Vector operations are currently implemented using sqlite-vec but are designed with abstraction in mind to support future vector database providers.

## Overview

The Vector API provides a unified interface for working with vector embeddings, enabling you to:
- Store and search vector embeddings
- Perform similarity search
- Build RAG applications
- Create recommendation systems
- Enable semantic search capabilities

## Getting Started

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase('http://localhost:8090');

// Authenticate as superuser (vectors require superuser auth)
await pb.admins.authWithPassword('admin@example.com', 'password');
```

## Types

### VectorEmbedding
List of doubles representing a vector embedding.

```dart
typedef VectorEmbedding = List<double>;
```

### VectorDocument
A vector document with embedding, metadata, and optional content.

```dart
class VectorDocument {
  String? id;                    // Unique identifier (auto-generated if not provided)
  List<double> vector;           // The vector embedding
  Map<String, dynamic>? metadata; // Optional metadata (key-value pairs)
  String? content;               // Optional text content
}
```

### VectorSearchOptions
Options for vector similarity search.

```dart
class VectorSearchOptions {
  List<double> queryVector;        // Query vector to search for
  int? limit;                      // Max results (default: 10, max: 100)
  Map<String, dynamic>? filter;    // Optional metadata filter
  double? minScore;                // Minimum similarity score threshold
  double? maxDistance;             // Maximum distance threshold
  bool? includeDistance;           // Include distance in results
  bool? includeContent;            // Include full document content
}
```

### VectorSearchResult
Result from a similarity search.

```dart
class VectorSearchResult {
  VectorDocument document;    // The matching document
  double score;               // Similarity score (0-1, higher is better)
  double? distance;           // Distance metric (optional)
}
```

## Collection Management

### Create Collection

Create a new vector collection with specified dimension and distance metric.

```dart
await pb.vectors.createCollection(
  'documents',
  VectorCollectionConfig(
    dimension: 384,      // Vector dimension (default: 384)
    distance: 'cosine',  // Distance metric: 'cosine' (default), 'l2', 'dot'
  ),
);

// Minimal example (uses defaults)
await pb.vectors.createCollection(
  'documents',
  VectorCollectionConfig(),
);
```

**Parameters:**
- `name` (String): Collection name
- `config` (VectorCollectionConfig):
  - `dimension` (int?, optional): Vector dimension. Default: 384
  - `distance` (String?, optional): Distance metric. Default: 'cosine'
  - Options: 'cosine', 'l2', 'dot'

### List Collections

Get all available vector collections.

```dart
final collections = await pb.vectors.listCollections();

for (final collection in collections) {
  print('${collection.name}: ${collection.count ?? 0} vectors');
}
```

### Update Collection

Update a vector collection configuration (distance metric and options).
Note: Collection name and dimension cannot be changed after creation.

```dart
await pb.vectors.updateCollection(
  'documents',
  VectorCollectionConfig(
    distance: 'l2',  // Change from cosine to L2
  ),
);

// Update with options
await pb.vectors.updateCollection(
  'documents',
  VectorCollectionConfig(
    distance: 'inner_product',
    options: {'customOption': 'value'},
  ),
);
```

**Parameters:**
- `name` (String): Collection name
- `config` (VectorCollectionConfig):
  - `distance` (String?, optional): Distance metric to update. Options: 'cosine', 'l2', 'inner_product'
  - `options` (Map<String, dynamic>?, optional): Custom collection options

### Delete Collection

Delete a vector collection and all its data.

```dart
await pb.vectors.deleteCollection('documents');
```

**⚠️ Warning**: This permanently deletes the collection and all vectors in it!

## Document Operations

### Insert Document

Insert a single vector document.

```dart
// With custom ID
final result = await pb.vectors.insert(
  VectorDocument(
    id: 'doc_001',
    vector: [0.1, 0.2, 0.3, 0.4],
    metadata: {'category': 'tech', 'tags': ['AI', 'ML']},
    content: 'Document about machine learning',
  ),
  collection: 'documents',
);

print('Inserted: ${result.id}');

// Without ID (auto-generated)
final result2 = await pb.vectors.insert(
  VectorDocument(
    vector: [0.5, 0.6, 0.7, 0.8],
    content: 'Another document',
  ),
  collection: 'documents',
);
```

### Batch Insert

Insert multiple vector documents efficiently.

```dart
final result = await pb.vectors.batchInsert(
  VectorBatchInsertOptions(
    documents: [
      VectorDocument(
        vector: [0.1, 0.2, 0.3],
        metadata: {'cat': 'A'},
        content: 'Doc A',
      ),
      VectorDocument(
        vector: [0.4, 0.5, 0.6],
        metadata: {'cat': 'B'},
        content: 'Doc B',
      ),
      VectorDocument(
        vector: [0.7, 0.8, 0.9],
        metadata: {'cat': 'A'},
        content: 'Doc C',
      ),
    ],
    skipDuplicates: true,
  ),
  collection: 'documents',
);

print('Inserted: ${result.insertedCount}');
print('Failed: ${result.failedCount}');
print('IDs: ${result.ids}');
```

### Get Document

Retrieve a vector document by ID.

```dart
final doc = await pb.vectors.get('doc_001', collection: 'documents');
print('Vector: ${doc.vector}');
print('Content: ${doc.content}');
print('Metadata: ${doc.metadata}');
```

### Update Document

Update an existing vector document.

```dart
// Update all fields
await pb.vectors.update(
  'doc_001',
  VectorDocument(
    vector: [0.9, 0.8, 0.7, 0.6],
    metadata: {'updated': true},
    content: 'Updated content',
  ),
  collection: 'documents',
);

// Partial update (only metadata and content)
await pb.vectors.update(
  'doc_001',
  VectorDocument(
    vector: [0.9, 0.8, 0.7, 0.6], // Still need vector for partial update
    metadata: {'category': 'updated'},
    content: 'New content',
  ),
  collection: 'documents',
);
```

### Delete Document

Delete a vector document.

```dart
await pb.vectors.delete('doc_001', collection: 'documents');
```

### List Documents

List all documents in a collection with pagination.

```dart
// Get first page
final result = await pb.vectors.list(
  page: 1,
  perPage: 100,
  collection: 'documents',
);

print('Page ${result['page']} of ${result['totalPages']}');
for (final item in result['items'] as List) {
  print(item['id'] + ': ' + (item['content'] as String? ?? ''));
}
```

## Vector Search

### Basic Search

Perform similarity search on vectors.

```dart
final results = await pb.vectors.search(
  VectorSearchOptions(
    queryVector: [0.1, 0.2, 0.3, 0.4],
    limit: 10,
  ),
  collection: 'documents',
);

for (final result in results.results) {
  print('Score: ${result.score} - ${result.document.content}');
}
```

### Advanced Search

```dart
final results = await pb.vectors.search(
  VectorSearchOptions(
    queryVector: [0.1, 0.2, 0.3, 0.4],
    limit: 20,
    minScore: 0.7,              // Minimum similarity threshold
    maxDistance: 0.3,           // Maximum distance threshold
    includeDistance: true,      // Include distance metric
    includeContent: true,       // Include full content
    filter: {'category': 'tech'}, // Filter by metadata
  ),
  collection: 'documents',
);

print('Found ${results.totalMatches} matches in ${results.queryTime}ms');
for (final r in results.results) {
  print('Score: ${r.score}, Distance: ${r.distance}');
  print('Content: ${r.document.content}');
}
```

## Common Use Cases

### Semantic Search

```dart
// 1. Generate embeddings for your documents
final documents = [
  {'text': 'Introduction to machine learning', 'id': 'doc1'},
  {'text': 'Deep learning fundamentals', 'id': 'doc2'},
  {'text': 'Natural language processing', 'id': 'doc3'},
];

for (final doc in documents) {
  // Generate embedding using your model
  final embedding = await generateEmbedding(doc['text'] as String);
  
  await pb.vectors.insert(
    VectorDocument(
      id: doc['id'] as String,
      vector: embedding,
      content: doc['text'] as String,
      metadata: {'type': 'tutorial'},
    ),
    collection: 'articles',
  );
}

// 2. Search
final queryEmbedding = await generateEmbedding('What is AI?');
final results = await pb.vectors.search(
  VectorSearchOptions(
    queryVector: queryEmbedding,
    limit: 5,
    minScore: 0.75,
  ),
  collection: 'articles',
);

for (final r in results.results) {
  print('${r.score.toStringAsFixed(2)}: ${r.document.content}');
}
```

### RAG (Retrieval-Augmented Generation)

```dart
Future<List<String>> retrieveContext(String query, {int limit = 5}) async {
  final queryEmbedding = await generateEmbedding(query);
  
  final results = await pb.vectors.search(
    VectorSearchOptions(
      queryVector: queryEmbedding,
      limit: limit,
      minScore: 0.75,
      includeContent: true,
    ),
    collection: 'knowledge_base',
  );
  
  return results.results
      .map((r) => r.document.content ?? '')
      .where((content) => content.isNotEmpty)
      .toList();
}

// Use with your LLM
final context = await retrieveContext('What are best practices for security?');
final answer = await llm.generate(context, userQuery);
```

### Recommendation System

```dart
// Store user profile embeddings
await pb.vectors.insert(
  VectorDocument(
    id: userId,
    vector: userProfileEmbedding,
    metadata: {
      'preferences': ['tech', 'science'],
      'demographics': {'age': 30, 'location': 'US'},
    },
  ),
  collection: 'users',
);

// Find similar users
final similarUsers = await pb.vectors.search(
  VectorSearchOptions(
    queryVector: currentUserEmbedding,
    limit: 20,
    includeDistance: true,
  ),
  collection: 'users',
);

// Generate recommendations based on similar users
final recommendations = await generateRecommendations(similarUsers.results);
```

## Best Practices

### Vector Dimensions

Choose the right dimension for your use case:

- **OpenAI embeddings**: 1536 (`text-embedding-3-large`)
- **Sentence Transformers**: 384-768
  - `all-MiniLM-L6-v2`: 384
  - `all-mpnet-base-v2`: 768
- **Custom models**: Match your model's output

### Distance Metrics

| Metric | Best For | Notes |
|--------|----------|-------|
| `cosine` | Text embeddings | Works well with normalized vectors |
| `l2` | General similarity | Euclidean distance |
| `dot` | Performance | Requires normalized vectors |

### Performance Tips

1. **Use batch insert** for multiple vectors
2. **Set appropriate limits** to avoid excessive results
3. **Use metadata filtering** to narrow search space
4. **Enable indexes** (automatic with sqlite-vec)

### Security

- All vector endpoints require superuser authentication
- Never expose credentials in client-side code
- Use environment variables for sensitive data

## Error Handling

```dart
try {
  await pb.vectors.search(
    VectorSearchOptions(
      queryVector: [0.1, 0.2, 0.3],
    ),
    collection: 'documents',
  );
} on ClientException catch (error) {
  if (error.statusCode == 404) {
    print('Collection not found');
  } else if (error.statusCode == 400) {
    print('Invalid request: ${error.response}');
  } else {
    print('Error: ${error.message}');
  }
}
```

## Examples

### Complete RAG Application

```dart
import 'package:bosbase/bosbase.dart';
import 'package:openai_dart/openai_dart.dart';

final pb = Bosbase('http://localhost:8090');
final openai = OpenAIClient(apiKey: Platform.environment['OPENAI_API_KEY']!);

// Initialize
await pb.admins.authWithPassword('admin@example.com', 'password');

// 1. Create knowledge base collection
await pb.vectors.createCollection(
  'knowledge_base',
  VectorCollectionConfig(
    dimension: 1536,  // OpenAI dimensions
    distance: 'cosine',
  ),
);

// 2. Index documents
Future<void> indexDocuments(List<Map<String, dynamic>> documents) async {
  for (final doc in documents) {
    // Generate OpenAI embedding
    final embedding = await openai.embeddings.create(
      request: EmbeddingRequest(
        model: 'text-embedding-3-large',
        input: [doc['content'] as String],
      ),
    );
    
    await pb.vectors.insert(
      VectorDocument(
        id: doc['id'] as String,
        vector: embedding.data.first.embedding,
        content: doc['content'] as String,
        metadata: {
          'source': doc['source'],
          'topic': doc['topic'],
        },
      ),
      collection: 'knowledge_base',
    );
  }
}

// 3. RAG Query
Future<String> ask(String question) async {
  // Generate query embedding
  final embedding = await openai.embeddings.create(
    request: EmbeddingRequest(
      model: 'text-embedding-3-large',
      input: [question],
    ),
  );
  
  // Search for relevant context
  final results = await pb.vectors.search(
    VectorSearchOptions(
      queryVector: embedding.data.first.embedding,
      limit: 5,
      minScore: 0.8,
      includeContent: true,
      filter: {'topic': 'relevant_topic'},
    ),
    collection: 'knowledge_base',
  );
  
  // Build context
  final context = results.results
      .map((r) => r.document.content ?? '')
      .where((c) => c.isNotEmpty)
      .join('\n\n');
  
  // Generate answer with LLM
  final completion = await openai.chat.completions.create(
    request: ChatCompletionRequest(
      model: 'gpt-4',
      messages: [
        ChatMessage(
          role: ChatMessageRole.system,
          content: 'You are a helpful assistant.',
        ),
        ChatMessage(
          role: ChatMessageRole.user,
          content: 'Context: $context\n\nQuestion: $question',
        ),
      ],
    ),
  );
  
  return completion.choices.first.message.content ?? 'No answer';
}

// Use it
final answer = await ask('What is machine learning?');
print(answer);
```

## References

- [sqlite-vec Documentation](https://alexgarcia.xyz/sqlite-vec)
- [sqlite-vec with rqlite](https://alexgarcia.xyz/sqlite-vec/rqlite.html)
- [Vector Implementation Guide](../VECTOR_IMPLEMENTATION.md)
- [Vector Setup Guide](../VECTOR_SETUP_GUIDE.md)

