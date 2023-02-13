import 'package:diox/diox.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

const String path = '/test';

void main() {
  group('RequestOptions matchers', () {
    test('general truthy test', () {
      // These RequestOptions and Request properties are required defaults.
      final options = RequestOptions(
        path: path,
        method: 'GET',
        contentType: Headers.jsonContentType,
        queryParameters: {},
      );

      const request = Request(
        route: path,
        method: RequestMethods.get,
        queryParameters: <String, dynamic>{},
      );

      expect(options.matchesRequest(request), true);
    });

    group('matches', () {
      late RequestOptions options;

      setUp(() {
        options = RequestOptions(
          path: path,
          method: 'GET',
          contentType: Headers.jsonContentType,
          queryParameters: {},
        );
      });

      test('data is MockDataCallback', () {
        const actual = {'a': 'a', 'b': 'b'};
        expect(options.matches(actual, (option) => {}), true);
      });

      group('map', () {
        test('exactly', () {
          const actual = {
            'a': 'a',
            'b': 'b',
          };

          const expected = {
            'a': 'a',
            'b': 'b',
          };

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers to validate', () {
          const actual = {
            'a': 'a',
            'b': 'b',
            'c': '123',
            'd': 123,
          };

          const expected = {
            'a': Matchers.any,
            'b': 'b',
            'c': Matchers.number,
            'd': Matchers.integer,
          };

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers but does not validate', () {
          const actual = {
            'a': 'a',
            'b': 'b',
            'c': '123A',
            'd': 123.0,
          };

          const expected = {
            'a': Matchers.any,
            'b': 'b',
            'c': Matchers.number,
            'd': Matchers.decimal,
          };

          expect(options.matches(actual, expected), false);
        });
      });

      group('list', () {
        test('exactly', () {
          const actual = ['a', 'b'];
          const expected = ['a', 'b'];

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers to validate', () {
          const actual = ['a', false, '123', 123];
          const expected = [
            Matchers.any,
            Matchers.boolean,
            Matchers.number,
            Matchers.number,
          ];

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers but does not validate', () {
          const actual = ['a', 'b', '123A', 123];
          const expected = [
            Matchers.any,
            Matchers.string,
            Matchers.number,
            Matchers.number,
          ];

          expect(options.matches(actual, expected), false);
        });
      });

      group('set', () {
        test('exactly', () {
          const actual = {'a', 'b'};
          const expected = {'a', 'b'};

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers to validate', () {
          const actual = {'a', false, '123', 'string'};
          const expected = {
            Matchers.any,
            Matchers.boolean,
            Matchers.number,
            Matchers.string
          };

          expect(options.matches(actual, expected), true);
        });

        test('uses matchers but does not validate', () {
          const actual = {'a', 'b', '123A'};
          const expected = {
            Matchers.any,
            Matchers.string,
            Matchers.number,
          };

          expect(options.matches(actual, expected), false);
        });
      });

      group('Dio request with matchers', () {
        late Dio dio;

        const data = {'message': 'Test!'};

        const statusCode = 200;
        late DioAdapter dioAdapter;

        setUpAll(() {
          dio = Dio();
          dioAdapter = DioAdapter(dio: dio);
        });

        test('fails on unsatisfied header expectation', () async {
          dioAdapter.onGet(
            path,
            (server) => server.reply(statusCode, data),
            headers: {
              Headers.contentLengthHeader: Matchers.integer,
            },
          );

          expect(
              () => dio.get(path),
              throwsA(predicate((e) =>
                  e is DioError &&
                  e.type == DioErrorType.unknown &&
                  e.error is AssertionError)));
        });
      });
    });
  });
}
