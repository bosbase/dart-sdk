import "../client.dart";

abstract class BaseService {
  final Bosbase _client;

  Bosbase get client => _client;

  BaseService(this._client);
}
