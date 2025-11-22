# GraphQL queries with the Dart SDK

Use `pb.graphql.query()` to call `/api/graphql` with your current auth token. It returns a `GraphQLResponse` with `data`, `errors`, and `extensions`.

> Authentication: the GraphQL endpoint is **superuser-only**. Authenticate as a superuser before calling GraphQL, e.g. `await pb.collection("_superusers").authWithPassword("email", "password");`.

## Single-table query

```dart
const query = r'''
  query ActiveUsers($limit: Int!) {
    records(collection: "users", perPage: $limit, filter: "status = true") {
      items { id data }
    }
  }
''';

final result = await pb.graphql.query(query, variables: {"limit": 5});
print(result.data);
```

## Multi-table join via expands

```dart
const query = r'''
  query PostsWithAuthors {
    records(
      collection: "posts",
      expand: ["author", "author.profile"],
      sort: "-created"
    ) {
      items {
        id
        data  // expanded relations live under data.expand
      }
    }
  }
''';

final response = await pb.graphql.query(query);
```

## Conditional query with variables

```dart
const query = r'''
  query FilteredOrders($minTotal: Float!, $state: String!) {
    records(
      collection: "orders",
      filter: "total >= $minTotal && status = $state",
      sort: "created"
    ) {
      items { id data }
    }
  }
''';

final result = await pb.graphql.query(
  query,
  variables: {"minTotal": 100, "state": "paid"},
);
```

Use the `filter`, `sort`, `page`, `perPage`, and `expand` arguments to mirror REST list behavior while keeping query logic in GraphQL.

## Create a record

```dart
const mutation = r'''
  mutation CreatePost($data: JSON!) {
    createRecord(collection: "posts", data: $data, expand: ["author"]) {
      id
      data
    }
  }
''';

final payload = {"title": "Hello", "author": "USER_ID"};
final created = await pb.graphql.query(mutation, variables: {"data": payload});
```

## Update a record

```dart
const mutation = r'''
  mutation UpdatePost($id: ID!, $data: JSON!) {
    updateRecord(collection: "posts", id: $id, data: $data) {
      id
      data
    }
  }
''';

await pb.graphql.query(
  mutation,
  variables: {
    "id": "POST_ID",
    "data": {"title": "Updated title"},
  },
);
```

## Delete a record

```dart
const mutation = r'''
  mutation DeletePost($id: ID!) {
    deleteRecord(collection: "posts", id: $id)
  }
''';

await pb.graphql.query(mutation, variables: {"id": "POST_ID"});
```
