import "dart:convert";

import "package:bosbase/bosbase.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:test/test.dart";

void main() {
  group("SQLService", () {
    test("execute() posts trimmed SQL to /api/sql/execute", () async {
      final mock = MockClient((request) async {
        expect(request.method, "POST");
        expect(request.url.toString(), "/base/api/sql/execute");
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body["query"], "SELECT 1");

        return http.Response(
          jsonEncode({
            "columns": ["one"],
            "rows": [
              [1],
            ],
            "rowsAffected": 0,
          }),
          200,
        );
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);
      final result = await client.sql.execute("  SELECT 1  ");

      expect(result.columns, ["one"]);
      expect(result.rows, [
        ["1"]
      ]);
      expect(result.rowsAffected, 0);
    });

    test("execute() throws when query is empty", () async {
      final client = Bosbase("/base", httpClientFactory: http.Client.new);

      expect(
        () => client.sql.execute("   "),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
